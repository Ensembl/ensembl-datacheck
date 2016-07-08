=head1 NAME

  HealthCheckSuite - Runs healthchecks depending according to changes to the database
  
=head1 SYNOPSIS

  $ perl HealthCheckSuite.pl
  
=head1 DESCRIPTION

  Using various ChangeDetection modules, this program provides the framework to detect changes in the 
  database and runs the necessary healthchecks in response. Information from the information_schema.tables
  meta tables kept by the MySQL server is used to find out what tables have changed. Healthcheck objects are
  created, after which the necessary healthchecks are determined using the table and database type information
  each healthcheck contains. The necessary healthchecks are then run.
  
  For adding new healthchecks to the suite: see the Input::HealthChecks module.
=cut

#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::SqlHelper;

use ChangeDetection::ChangeDetector;
use ChangeDetection::HealthCheckObject;
use ChangeDetection::TableFilter;

use DBUtils::Connect;

use Input::HealthChecks;

my $dba = DBUtils::Connect::get_db_adaptor('config');

my $type = DBUtils::Connect::get_db_type($dba);

my $changed_tables = ChangeDetection::ChangeDetector::get_changed_tables($dba);

use Data::Dumper;
print Dumper($changed_tables);

#create a filtered table file for the CoreForeignKeys healthcheck.    (not sure if this is the best place for this)
ChangeDetection::TableFilter::filter_foreignkey_file($changed_tables);

my @healthcheck_objects; 
 
for my $healthcheck (keys %Input::HealthChecks::healthchecks ) {
    
    my $healthcheck_def = $Input::HealthChecks::healthchecks{$healthcheck};
    my $object = ChangeDetection::HealthCheckObject->new(
        name => $healthcheck,
        %{$healthcheck_def}
   );
   push @healthcheck_objects, $object;
}

#filter out healthchecks that don't apply to the type;
@healthcheck_objects = grep { ($_->db_type) eq $type || ($_->db_type) eq 'generic' } @healthcheck_objects;


#filter out the healthchecks that don't apply to the changed table(s):
foreach my $changed_table (@$changed_tables){
    
    foreach my $healthcheck_object (@healthcheck_objects){
        my @healthcheck_tables = @{ $healthcheck_object->tables };
        
       
        if(grep{$changed_table eq $_} @healthcheck_tables){
            $healthcheck_object->applicable(1);
        }
    }
}    

#now run the  healthchecks that apply to the changed tables
foreach my $healthcheck_object (@healthcheck_objects){
    my $applicable = $healthcheck_object->applicable;
    if($applicable){
        my $command = "--config_file 'config'";
        if(($healthcheck_object->name) eq 'CoreForeignKeys'){
            $command .= " --filter_tables";
        }
        $healthcheck_object->run_healthcheck(
            command => $command,
            path => '.',
        );
    }
}    

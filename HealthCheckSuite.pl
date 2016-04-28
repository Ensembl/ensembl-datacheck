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
    my $object = ChangeDetection::HealthCheckObject->new(
        name => $healthcheck,
        hc_type => $Input::HealthChecks::healthchecks{$healthcheck}{'hc_type'},
        tables => $Input::HealthChecks::healthchecks{$healthcheck}{'tables'},
        db_type => $Input::HealthChecks::healthchecks{$healthcheck}{'db_type'},
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
        $healthcheck_object->run_healthcheck();
    }
}    

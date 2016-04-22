#!/usr/bin/env perl

use strict;
use warnings;

use HealthChecks;

use ChangeDetection::HealthCheckObject;
use ChangeDetection::ChangeDetector;

use DBUtils::Connect;

use Bio::EnsEMBL::Utils::SqlHelper;
use Bio::EnsEMBL::DBSQL::DBAdaptor;

my $dba = DBUtils::Connect::get_db_adaptor();

my $type = DBUtils::Connect::get_db_type($dba);

my $changed_tables = ChangeDetection::ChangeDetector::get_changed_tables($dba);

use Data::Dumper;
print Dumper($changed_tables);

my @healthcheck_objects; 
 
for my $healthcheck (keys %HealthChecks::healthchecks ) {
    my $object = ChangeDetection::HealthCheckObject->new(
        name => $healthcheck,
        hc_type => $HealthChecks::healthchecks{$healthcheck}{'hc_type'},
        tables => $HealthChecks::healthchecks{$healthcheck}{'tables'},
        db_type => $HealthChecks::healthchecks{$healthcheck}{'db_type'},
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

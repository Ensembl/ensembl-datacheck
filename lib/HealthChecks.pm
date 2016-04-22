package HealthChecks;

use strict;
use warnings;


#Add healthchecks to this file to add them to the automatic change detection system.

our %healthchecks = (
    DataFiles => {
        hc_type => 4,
        tables => ['data_file'],
        db_type => 'rnaseq',
    },
    LRG => {
        hc_type => 2,
        tables => ['coord_system', 'gene', 'seq_region', 'transcript'],
        db_type => 'core',
    },
    ProjectedXrefs => {
        hc_type => 2,
        tables => ['external_db', 'gene', 'xref'],
        db_type => 'core',
    },
 );
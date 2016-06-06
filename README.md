# Ensembl_thesis

<h2>A New Healthcheck System for Ensembl</h2>

This repository contains the work of Emma den Brok's Bachelor Thesis project carried out at the EBI from Febuary to July 2016. The goal of the project was to design a new healthcheck system for Ensembl in Perl.

Twelve healthchecks, grouped in 5 different categories, were adapted into Perl: <b>CoreForeignKeys</b> (1), <b>AssemblyMapping</b> (2), <b>LRG</b> (2), <b>ProjectedXrefs</b> (2), <b>SeqRegionCoordSystem</b> (2), <b>SequenceLevel</b> (2), <b>XrefTypes</b> (2), <b>AutoIncrement</b> (3), <b>Meta</b> (3), <b>AssemblyNameLength</b> (4), <b>DataFiles</b> (4), <b>CoordSystemAcrossSpecies</b> (5). The scripts for each can be found in folder corresponding to the category.
The old healthchecks, in Java, can be found at:
https://github.com/Ensembl/ensj-healthcheck/tree/release/83/src/org/ensembl/healthcheck/testcase/generic

These scripts can be run individually on the command line. See documentation included with each healthcheck to see how. The new healthcheck system uses the Ensembl Perl API, so this needs to be installed. Other modules used are: Data::Dumper File::Spec, Getopt::Long, and <b>Moose</b>.
These come with most standard distributions of Perl, except Moose which you will also need to install to run healthchecks. The system is compatible with Perl 5.14.2 or higher.

The <b>config</b> file in the main directory contains the information that is used by the scripts to connect to a database. You should specify ports, hosts, etc in this file. If you use the registry, you can also use the command line to specify species and database type. Moreover, you can also specify the filepath to a different configuration file if you wish to use your own.

Apart from the healthchecks, an infrastructure was also developed. The overarching component of this is <b>HealthCheckSuite.pl</b>. This script uses modules in the <b>ChangeDetection</b> namespace to determine which tables have changed in the database since it was last run. Based on this information it will then proceed to only run healthchecks that involve these changed tables. Moreover, it also filters out foreign key pairs for the CoreForeignKeys script, so that again, only the changed tables are tested.

Modules used as helper functions by the healthchecks can be found in the <b>DBUtils</b> namespace. Additionally, large amounts of hardcoded values have been removed from the healthchecks themselves and are stored as modules in the <b>Input</b> namespace. This is also where you should make additions or deletions to these values (such as foreign key pairs).

Part of the thesis research focussed on the simplification of integrity constraints. The scripts used for this can be found on the integrity-simplification branch, in the integrity-simplification folder. 


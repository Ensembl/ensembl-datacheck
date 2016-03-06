#!/usr/bin/env perl

use strict;
use warnings;
use diagnostics;

#following the example in Beginning Perl chapter 11

use lib '/home/ensembl/Shared_Folders/lib'; 

use My::Primes;

my @numbers = qw(
	3 2 39 7919 997 631 200
	7919 459 7919 623 997 867 15
	);

my @primes = grep { My::Primes::is_prime($_) }
	@numbers;
print join ', ' => sort { $a <=> $b } @primes;
print "\n";

#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all'; 

use FindBin;
use lib "$FindBin::Bin/lib";

# Some of the tests only work with BioPerl 1.6.1
use lib '/software/pubseq/PerlModules/BioPerl/1_6_1';


use MyTest::HTGT::Utils::Restriction::EnzymeCollection;
use Log::Log4perl ':levels';

Log::Log4perl->easy_init( $ERROR );

Test::Class->runtests;



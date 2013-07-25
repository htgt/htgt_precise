#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    $ENV{HTGT_DB} = 'eucomm_vector_esmt';
}

use FindBin '$Bin';
use lib "$Bin/lib";

use Log::Log4perl ':levels';
use MyTest::HTGT::Utils::ResetPlateParentageAndQC;

Log::Log4perl->easy_init( { level => $FATAL } );

Test::Class->runtests;
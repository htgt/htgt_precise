#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    $ENV{HTGT_DB} = 'eucomm_vector_esmt';
}

use Test::Most;
use HTGT::DBFactory;
#use Data::Dump 'pp';

use_ok 'HTGT::Utils::QCTestResults', 'fetch_test_results_for_run';

my $schema = HTGT::DBFactory->connect( 'eucomm_vector' );

ok my $results = fetch_test_results_for_run( $schema, '09DD5A76-1776-11E1-A00E-EAA4A96C86F0' );

isa_ok $results, 'ARRAY';

isa_ok $results->[0], 'HASH';

#pp $results;

done_testing;

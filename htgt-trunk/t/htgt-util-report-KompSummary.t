#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use HTGT::DBFactory;
use Test::Most;

use_ok( "HTGT::Utils::Report::KompSummary" );

ok get_komp_summary_columns(), 'Get column Names';

my $schema = HTGT::DBFactory->connect('eucomm_vector');

ok my $data = get_komp_summary_data($schema), 'Get Komp Data';

done_testing();

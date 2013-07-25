#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use TargetedTrap::IVSA::Constants;
use Data::Dumper;
use Const::Fast;

const my %TEST_DATA => (
    'HEPD00525_1_1_B_1a04.p1kR2R' => [ 'HEPD00525_1', 'B',   '1', 'a04', undef, 'R2R' ],
    'PC00071_A_4h12.p1kaLRR'      => [ 'PC00071',     'A',   '4', 'h12', 'a',   'LRR' ],
    'MOHPGS0002_A_3b_1a05.p1kNF'  => [ 'MOHPGS0002',  'A',   '1', 'a05', undef, 'NF'  ],
    'EPD00230_1_A_1_2f11.p1kLR'   => [ 'EPD00230_1',  'A',   '2', 'f11', undef, 'LR'  ],
    'HTGR01001_A4h12.p1kePNF'     => [ 'HTGR01001',   'A',   '4', 'h12', 'e',   'PNF' ],
    'GW00007_a_1b02.p1kjR3'       => [ 'GW00007',     'a',   '1', 'b02', 'j',   'R3'  ],
    'EPD0014_1_A_1b02.p1kjR3'     => [ 'EPD0014_1',   'A',   '1', 'b02', 'j',   'R3'  ],
    'RHEPD0017_B1h03.p1kaR2R'     => [ 'RHEPD0017',   'B',   '1', 'h03', 'a',   'R2R' ],
    'PC00007_1b03.p1kbLRR'        => [ 'PC00007',     undef, '1', 'b03', 'b',   'LRR' ],
    'EPD00229_5_B_1-1h12.p1k'     => [ 'EPD00229_5',  'B',   '1', 'h12', undef, ''    ],
    'PG00102_Y_4h10.p1keLR'       => [ 'PG00102',     'Y',   '4', 'h10', 'e',   'LR'  ],
    'GR0007_A_1b02.p1kR3'         => [ 'GR0007',      'A',   '1', 'b02', undef, 'R3'  ],
    'PGTest_A_1d07.p1kaPNF'       => [ 'PGTest',      'A',   '1', 'd07', 'a',   'PNF' ],
);

const my $RX => $TargetedTrap::IVSA::Constants::PLATE_REGEXP;

for my $t ( keys %TEST_DATA ) {
    is_deeply [ $t =~ $RX ], $TEST_DATA{$t}, "parse $t";    
}

done_testing();

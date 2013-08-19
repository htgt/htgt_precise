#!/usr/bin/env perl

use Test::More;

use_ok 'HTGT::Utils::MutagenesisPrediction::FloxedExons', 'get_floxed_exons';

is_deeply get_floxed_exons( 'ENSMUSG00000018666', 96800600, 96801000 ),
    [ 'ENSMUSE00001122566' ],
    'floxed exons for Cbx1 (conditional)';

is_deeply get_floxed_exons( 'ENSMUSG00000018666', 96800600 ),
    [ 'ENSMUSE00001122566', 'ENSMUSE00001167818', 'ENSMUSE00000110987', 'ENSMUSE00000585970', 'ENSMUSE00000585969' ],
    'floxed exons for Cbx1 (non-conditional)';

is_deeply get_floxed_exons( 'ENSMUSG00000030217', 136855200, 136854200 ),
    [ 'ENSMUSE00000196466' ],
    'Floxed exons for Art4 (conditional)';

is_deeply get_floxed_exons( 'ENSMUSG00000030217', 136855200  ),
    [ 'ENSMUSE00000196466', 'ENSMUSE00000313469' ],
    'Floxed exons for Art4 (non-conditional)';

is_deeply get_floxed_exons( 'ENSMUSG00000031555', 25000000, 24997500 ),
    [ 'ENSMUSE00000609044' ],
    'floxed exons for Adam9 (conditional) - transcripts have non-canonical splicing';

done_testing;

#!/software/perl-5.8.8/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::Most;

use_ok( "HTGT::Utils::ESCellStrain" );

my %strain_for = (
    'AB2.2'                  => '129S7/SvEvBrd-Hprt<b-m2>',
    'C2 (Nagy) (p13)'        => 'C57BL/6N',
    'JM8'                    => 'C57BL/6N',
    'JM8 parental'           => 'C57BL/6N',
    'JM8.F6'                 => 'C57BL/6N',
    'JM8.N19'                => 'C57BL/6N',
    'JM8.N4'                 => 'C57BL/6N',
    'JM8.N4 (p12)'           => 'C57BL/6N',
    'JM8.N4 CRE/FLP P14'     => undef,
    'JM8.N4 Rosa26:Flp/Cre'  => undef,
    'JM8.N4.BirA'            => undef,
    'JM8A1 (Agouti)'         => 'C57BL/6N-A',
    'JM8A1.N3'               => 'C57BL/6N-A',
    'JM8A3'                  => 'C57BL/6N-A',
    'JM8A3 (Agouti)'         => 'C57BL/6N-A',
    'JM8A3 (Agouti)'         => 'C57BL/6N-A',
    'JM8A3.N1'               => 'C57BL/6N-A',
    'JM8A3.N1    P11'        => 'C57BL/6N-A',
    'JM8A3.N1   P11'         => 'C57BL/6N-A',
    'JM8A3.N1 (p11)'         => 'C57BL/6N-A',
    'JM8A3.N1 (p11)'         => 'C57BL/6N-A',
    'JM8A3.N1 (p12)'         => 'C57BL/6N-A',
    'JM8A3.N1 p10'           => 'C57BL/6N-A',
    'JM8A3.N1 p11'           => 'C57BL/6N-A',
    'JM8A3.N1 p18'           => 'C57BL/6N-A',
    'SI2.3'                  => '129S7/SvEvBrd-Hprt<b-m2>',
    'SI6.C21'                => 'C57BL/6JCrl'
);

throws_ok { es_cell_strain() } qr/^ES cell line not specified/, '...ES cell line not specified' ;
throws_ok { es_cell_strain( "no such strain") } qr/^Unrecognized ES cell line: no such strain/, '...Unrecognized ES cell line' ;

foreach my $es_cell_line ( sort keys %strain_for ) {
    if ( ( $es_cell_line =~ /JM8.N4 CRE\/FLP/ ) or ( $es_cell_line =~ /JM8.N4 Rosa26:Flp\/Cre/ ) or ( $es_cell_line =~ /JM8.N4.BirA/ ) ){
	throws_ok { es_cell_strain( $es_cell_line ) } qr/Unrecognized ES cell line/, '... unrecognized ES cell line $es_cell_line';
    }else{
	is( es_cell_strain( $es_cell_line ), $strain_for{ $es_cell_line }, $es_cell_line );
    }
}

done_testing();
#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use Test::Most;
use Readonly;

BEGIN {
    $ENV{HTGT_DB} = 'eucomm_vector_esmt';
    $ENV{VECTOR_QC_DB} = 'vector_qc_esmt';
}

Readonly my @QC_WELL_DATA => qw( pass_level distribute qctest_result_id );

Readonly my %PLATE_384_TEST_DATA => (
    plate_name    => 'PG00191_Z_1',
    qctest_run_id => 12814,
    genomic_hits  => [ qw( A02 A06 A11 C12 D07 F05 F12 G02 G12 H09 ) ],
    user          => 'test',
    load_qc       => 'load_384well_qc',
);

Readonly my %PLATE_96_TEST_DATA => (
    plate_name       =>  'GRD91029_A',
    qctest_run_id    => 13276,
    genomic_hits     => [ qw( A05 A06 A07 A08 D07 G08 ) ],
    stage            => 'postgw',
    user             => 'test',
    ignore_well_slop => 1,
    load_qc          => 'load_qc',
);

die_on_fail;

ok my $htgt      = HTGT::DBFactory->connect( 'eucomm_vector' ), 'HTGT connect';
ok my $vector_qc = HTGT::DBFactory->connect( 'vector_qc' ), 'VectorQC connect';

$htgt->txn_do(
    sub {

        run_tests( %PLATE_384_TEST_DATA );
        
        run_tests( %PLATE_96_TEST_DATA );

        $htgt->txn_rollback;
    }
);

done_testing;

sub run_tests {
    my %options = @_;

    my $plate_name   = delete $options{ plate_name };
    my $genomic_hits = delete $options{ genomic_hits };
    my $load_qc      = delete $options{ load_qc };

    my @log_lines;
    $options{log} = sub { push @log_lines, @_ };
    $options{qc_schema} = $vector_qc;
    
    ok my $plate = $htgt->resultset( 'Plate' )->find( { name => $plate_name } ), 'find plate';
    ok $plate->wells_rs->search_related_rs( 'well_data', { data_type => \@QC_WELL_DATA } )->delete, 'delete existing QC data';
    lives_ok { $plate->$load_qc( \%options ) } $load_qc;

    my %is_expected_genomic_hit = map { $_ => 1 } @{ $genomic_hits };

    for my $well ( $plate->wells ) {
        if ( $is_expected_genomic_hit{ $well->well_name } ) {
            for ( @QC_WELL_DATA ) {
                ok !defined $well->well_data_value( $_ ), "$well $_ not defined for genomic hit";                
            }            
        }
        else {
            for ( @QC_WELL_DATA ) {
                next if $_ eq 'distribute'; # distribute flag not set on QC load
                ok defined $well->well_data_value( $_ ), "$well $_ defined for non-genomic hit";                
            }
        }
    }

    is scalar( grep m/ignoring genomic hit/, @log_lines ), scalar( @{ $genomic_hits } ), 'logged expected number of genomic hits';
}

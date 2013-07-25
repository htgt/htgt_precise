#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use Log::Log4perl ':levels';

Log::Log4perl->easy_init( $FATAL );

die_on_fail;

use_ok( 'HTGT::Utils::MutagenesisPrediction::Exon' );
use_ok( 'HTGT::Utils::MutagenesisPrediction::ORF' );
use_ok( 'HTGT::Utils::EnsEMBL' );
use_ok( 'Bio::Seq' );

test_transcript( 'ENSMUST00000071564' );
test_transcript( 'ENSMUST00000093943' );

done_testing;

sub test_transcript {
    my $transcript_id = shift;

    ok my $transcript = HTGT::Utils::EnsEMBL->transcript_adaptor->fetch_by_stable_id( $transcript_id ),
        'fetch transcript ' . $transcript_id;

    ok my $orf = HTGT::Utils::MutagenesisPrediction::ORF->new(
        cdna_coding_start => $transcript->cdna_coding_start,
        cdna_coding_end   => $transcript->cdna_coding_end,
        translation       => Bio::Seq->new( -alphabet => 'dna', -seq => $transcript->translation->seq )
    ), 'create ORF';

    for my $ensembl_exon ( @{ $transcript->get_all_Exons } ) {
        ok my $exon = HTGT::Utils::MutagenesisPrediction::Exon->new(
            ensembl_exon => $ensembl_exon,
            cdna_start   => $ensembl_exon->cdna_start( $transcript ),
            cdna_end     => $ensembl_exon->cdna_end( $transcript )
        ), 'create exon ' . $ensembl_exon->stable_id;
        is $exon->phase( $orf ), $ensembl_exon->phase, 'phase';
        is $exon->end_phase( $orf ), $ensembl_exon->end_phase, 'end_phase';
        ok $exon->phase( $orf ) == -1 || $exon->is_in_phase( $orf ), 'is_in_phase';
        lives_and {
            my $got = $exon->translation( $orf );
            my $expected = $ensembl_exon->peptide( $transcript );
            if ( $got and $expected ) {                
                is $got->seq, $expected->seq, 'translation of coding exon';
            }
            else {
                ok !$got && $expected->length == 0, 'translation of non-coding exon';
            }
        };        
    }
}


#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use Const::Fast;
use HTGT::Utils::EnsEMBL;

const my $NEG_STRAND_GENE_ID => 'ENSMUSG00000043060';
const my $POS_STRAND_GENE_ID => 'ENSMUSG00000044400';
const my $MULTI_EXON_GENE_ID => 'ENSMUSG00000074435';


const my @RECOMBINEERING_PRIMERS => qw( U5 U3 D5 D3 );

die_on_fail;

use_ok 'HTGT::Utils::DesignFinder::SingleExonGene';

ok my $sa = HTGT::Utils::EnsEMBL->slice_adaptor, 'create slice adaptor';

throws_ok { HTGT::Utils::DesignFinder::SingleExonGene->new( ensembl_gene_id => $MULTI_EXON_GENE_ID ) }
    qr/Transcript .+ has \d+ exons/, 'Dies when passed multi-exon gene';

for my $ens_gene_id ( $POS_STRAND_GENE_ID, $NEG_STRAND_GENE_ID) {
    ok my $df = HTGT::Utils::DesignFinder::SingleExonGene->new( ensembl_gene_id => $ens_gene_id ), 'create DesignFinder object';
    isa_ok $df, 'HTGT::Utils::DesignFinder::SingleExonGene';
    ok my $candidate_designs = $df->find_candidate_insertion_locations, 'find_candidate_insertion_locations';
    isa_ok $candidate_designs, 'ARRAY';
    ok @{$candidate_designs} > 0, 'find_candidate_insertion_locations returned candidates';
    for ( @{$candidate_designs} ) {
        check_oligos( $_ );
    }
}

done_testing;

sub check_oligos {
    my $params = shift;

    for ( @RECOMBINEERING_PRIMERS ) {
        my $expected_seq = $params->{ $_ . '_seq' };
        my $slice = $sa->fetch_by_region( 'chromosome', @{$params}{ 'chromosome', $_ . '_start', $_ . '_end', 'strand' } );
        is $slice->seq, $expected_seq, "Sequence for $_";
    }
}

package MyTest::HTGT::Utils::DesignFinder::Gene;

use strict;
use warnings FATAL => 'all';

use base qw( Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( class => 'HTGT::Utils::DesignFinder::Gene' );
}

use Test::Most;
use HTGT::Utils::DesignFinder::Gene;
use Readonly;

Readonly my $ENSEMBL_GENE_ID     => 'ENSMUSG00000018666';
Readonly my @VALID_TRANSCRIPTS   => qw( ENSMUST00000093943 ENSMUST00000079702 ENSMUST00000018810 );
Readonly my $TEMPLATE_TRANSCRIPT => 'ENSMUST00000093943';
Readonly my @TEMPLATE_EXONS      => qw( ENSMUSE00000761328 ENSMUSE00001062012 ENSMUSE00001022518
                                        ENSMUSE00000110987 ENSMUSE00000585970 ENSMUSE00000585969 );
Readonly my $LAST_CE_START_IX    => 2;

sub constructor :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'new';
    ok my $o = $test->class->new( ensembl_gene_id => $ENSEMBL_GENE_ID ), '...constructor should succeed';
    isa_ok $o, $test->class, '...the object it returns';
}

sub ensembl_gene :Tests(4) {
    my $test = shift;

    my $o = $test->class->new( ensembl_gene_id => $ENSEMBL_GENE_ID );

    can_ok $o, 'ensembl_gene';
    ok my $e = $o->ensembl_gene, '...ensembl_gene should succeed';
    isa_ok $e, 'Bio::EnsEMBL::Gene', '...the object it returns';
    is $e->stable_id, $ENSEMBL_GENE_ID, '...it has the expected stable_id';
}

sub valid_coding_transcripts :Tests(3) {
    my $test = shift;

    my $o = $test->class->new( ensembl_gene_id => $ENSEMBL_GENE_ID );

    can_ok $o, 'valid_coding_transcripts';
    ok my @t = $o->valid_coding_transcripts, '...valid_coding_transcripts should succeed';
    is_deeply [ map $_->stable_id, @t ], \@VALID_TRANSCRIPTS,
        '...returns expected transcripts in correct order';
}

sub has_valid_coding_transcripts :Tests(2) {
    my $test = shift;

    my $o = $test->class->new( ensembl_gene_id => $ENSEMBL_GENE_ID );
    can_ok $o, 'has_valid_coding_transcripts';
    ok $o->has_valid_coding_transcripts, '...gene has valid coding transcripts';
}

sub template_transcript :Tests(4) {
    my $test = shift;

    my $o = $test->class->new( ensembl_gene_id => $ENSEMBL_GENE_ID );
    can_ok $o, 'template_transcript';
    ok my $t = $o->template_transcript, '...template_transcript should succeed';
    isa_ok $t, 'Bio::EnsEMBL::Transcript', '...the object it returns';
    is $t->stable_id, $TEMPLATE_TRANSCRIPT, '...it has the expected stable_id';
}

sub template_exons :Tests(3) {
    my $test = shift;

    my $o = $test->class->new( ensembl_gene_id => $ENSEMBL_GENE_ID );
    can_ok $o, 'template_exons';
    ok my @e = $o->template_exons, '...template_exons should succeed';
    is_deeply [ map $_->stable_id, @e ], \@TEMPLATE_EXONS;
}

sub num_template_exons :Tests(2) {
    my $test = shift;

    my $o = $test->class->new( ensembl_gene_id => $ENSEMBL_GENE_ID );
    can_ok $o, 'num_template_exons';
    is $o->num_template_exons, scalar @TEMPLATE_EXONS;
}

sub get_template_exon :Tests(3) {
    my $test = shift;

    my $o = $test->class->new( ensembl_gene_id => $ENSEMBL_GENE_ID );
    can_ok $o, 'get_template_exon';
    ok my $e = $o->get_template_exon(0), '...get_template_exon should succeed';
    is $e->stable_id, $TEMPLATE_EXONS[0], '...first exon has expected stable_id';
}

sub first_exon_codes_more_than_50pct_protein :Tests(3) {
    my $test = shift;

    {
        my $o = $test->class->new( ensembl_gene_id => $ENSEMBL_GENE_ID );
        can_ok $o, 'first_exon_codes_more_than_50pct_protein';
        ok !$o->first_exon_codes_more_than_50pct_protein, '...first_exon_codes_more_than_50pct_protein should return false';
    }

    {
        my $o = $test->class->new( ensembl_gene_id => 'ENSMUSG00000025239' );
        ok $o->first_exon_codes_more_than_50pct_protein, '...first_exon_codes_more_than_50pct_protein should return true';
    }
}

sub last_candidate_start_ce_index :Tests(2) {
    my $test = shift;

    my $o = $test->class->new( ensembl_gene_id => $ENSEMBL_GENE_ID );
    can_ok $o, 'last_candidate_start_ce_index';
    is $o->last_candidate_start_ce_index, $LAST_CE_START_IX;
}



1;

__END__

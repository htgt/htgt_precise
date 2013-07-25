package MyTest::HTGT::Utils::EnsEMBL;

use strict;
use warnings FATAL => 'all';

use base qw( Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( class => 'HTGT::Utils::EnsEMBL' );
}

use Test::Most;
use HTGT::Utils::EnsEMBL;

sub registry :Tests(6) {
    my $test = shift;

    can_ok $test->class, 'registry';
    ok my $r = $test->class->registry;
    ok my $a = $r->get_adaptor( 'Mouse', 'core', 'gene' );    
    isa_ok $a, 'Bio::EnsEMBL::DBSQL::GeneAdaptor';
    ok my $b = $test->class->registry->get_DBAdaptor( 'Mouse', 'Core' );
    isa_ok $b, 'Bio::EnsEMBL::DBSQL::DBAdaptor';
}

sub db_adaptor :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'db_adaptor';
    ok my $a = $test->class->db_adaptor;
    isa_ok $a, 'Bio::EnsEMBL::DBSQL::DBAdaptor';
}

sub gene_adaptor :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'gene_adaptor';
    ok my $a = $test->class->gene_adaptor;
    isa_ok $a, 'Bio::EnsEMBL::DBSQL::GeneAdaptor';
}

sub slice_adaptor :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'slice_adaptor';
    ok my $a = $test->class->slice_adaptor;
    isa_ok $a, 'Bio::EnsEMBL::DBSQL::SliceAdaptor';
}

sub exon_adaptor :Tests(3) {
    my $test = shift;
    
    can_ok $test->class, 'exon_adaptor';
    ok my $a = $test->class->exon_adaptor;
    isa_ok $a, 'Bio::EnsEMBL::DBSQL::ExonAdaptor';
}

sub transcript_adaptor :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'transcript_adaptor';
    ok my $a = $test->class->transcript_adaptor;
    isa_ok $a, 'Bio::EnsEMBL::DBSQL::TranscriptAdaptor';
}

sub repeat_feature_adaptor :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'repeat_feature_adaptor';
    ok my $a = $test->class->repeat_feature_adaptor;
    isa_ok $a, 'Bio::EnsEMBL::DBSQL::RepeatFeatureAdaptor';
}

sub constrained_element_adaptor :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'constrained_element_adaptor';
    ok my $a = $test->class->constrained_element_adaptor;
    isa_ok $a, 'Bio::EnsEMBL::Compara::DBSQL::ConstrainedElementAdaptor';
}

1;

__END__

package MyTest::HTGT::Utils::Design::Info;

use strict;
use warnings FATAL => 'all';

use base qw( Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( class => 'HTGT::Utils::Design::Info' );
    __PACKAGE__->mk_classdata( 'htgt' );
    __PACKAGE__->mk_classdata( 'data' );
}

use Bio::Seq;
use HTGT::DBFactory;
use HTGT::Utils::Design::Info;
use Test::Most;
use Readonly;

sub constructor :Tests(startup => 5) {
    my $test = shift;

    $test->htgt( HTGT::DBFactory->connect( 'eucomm_vector' ) );

    my @test_data = (
        {
            design_id         => 45286,
            ensembl_gene_id   => 'ENSMUSG00000030217',
            transcript_id     => 'ENSMUST00000032341',
            slice_id          => 'chromosome:GRCm38:6:136849277:136860426:-1',
            first_floxed_exon => 'ENSMUSE00000196466',
            last_floxed_exon  => 'ENSMUSE00000196466',
            num_floxed_exons  => 1,
            marker_symbol     => 'Art4',
            chr_name          => 6,
            chr_strand        => -1,
            oligos            => {
                G5 => Bio::Seq->new( -seq => 'AGAGAACTGACCGCTGAGATATGAATGTGTATATTTAGGTTTAATGGCAG' )->revcom,
                U5 => Bio::Seq->new( -seq => 'ATGGGGGGCTCTGTCTCAGCCTAACCAAACTAAAACTAAAGCAAGCTTAT' )->revcom,
                U3 => Bio::Seq->new( -seq => 'TGGGGGGGGGGGTGGCTTATGCTTATCGTCCTTAGAAGGCCGAAATACAA' )->revcom,
                D5 => Bio::Seq->new( -seq => 'CAGGTTTCCCTGTTTTCAACTCCCTACTCCTAGCCCACTCAGAAAAAGAA' )->revcom,
                D3 => Bio::Seq->new( -seq => 'GCCCAGTGGATAAGGACCTAATACAGTACCACTTCAGAGACTCTTTTTTT' )->revcom,
                G3 => Bio::Seq->new( -seq => 'CTTCTGGTCTACGATGTTCTGTAAGTTTATAAGTGGAAGCAAAGCTTTCA' )->revcom,
            },
            features          => {
                G5 => { start => 136860377, end => 136860426 },
                G3 => { start => 136849277, end => 136849326 },
                U5 => { start => 136855522, end => 136855571 },
                U3 => { start => 136855419, end => 136855468 },
                D5 => { start => 136854158, end => 136854207 },
                D3 => { start => 136854033, end => 136854082 },
            },
            chr_start           => 136849277,
            chr_end             => 136860426,
            target_region_start => 136854158,
            target_region_end   => 136855468,
            cassette_start      => 136855469,
            cassette_end        => 136855521,
            loxp_start          => 136854083,
            loxp_end            => 136854157,
            floxed_exon_start   => 136854352,
            floxed_exon_end     => 136855060,
            homology_arm_start  => 136849277,
            homology_arm_end    => 136860426,
        },
        {
            design_id         => 39792,
            ensembl_gene_id   => 'ENSMUSG00000018666',
            transcript_id     => 'ENSMUST00000093943',
            slice_id          => 'chromosome:GRCm38:11:96796597:96806551:1',
            first_floxed_exon => 'ENSMUSE00001167818',
            last_floxed_exon  => 'ENSMUSE00001167818',
            num_floxed_exons  => 1,
            marker_symbol     => 'Cbx1',
            chr_name          => 11,
            chr_strand        => 1,
            oligos            => {
                G5 => Bio::Seq->new( -seq => 'TGGTTTTCAGATAATTACCCCTTAGTTAAAGACAATGTATAATGAATTAG' ),
                U5 => Bio::Seq->new( -seq => 'CATTGACACAGGTAAATTCGGTCACTATGAAAAATCATATATGCTTACTA' ),
                U3 => Bio::Seq->new( -seq => 'AGGACCTACATGCAGAGTATTATATGACTGAGTTTTTTGTCTTGTTTTAA' ),
                D5 => Bio::Seq->new( -seq => 'TGGCCTATAATTTTGTATCCCAAGTTTGCCTTAGACTTGTAGCAATTCTC' ),
                D3 => Bio::Seq->new( -seq => 'TGTTGAGATTATGAGTACGAACTACCATACTGGACTTTCTTCCTTTGGAT' ),
                G3 => Bio::Seq->new( -seq => 'TCCTCTTTCCTAGTTTGTTTCTGGAATTTAGACTTTAAAAGCCCCATTCC' ),
            },
            features          => {
                G5 => { start => 96657911, end => 96657960 },
                G3 => { start => 96667816, end => 96667865 },
                U5 => { start => 96662270, end => 96662319 },
                U3 => { start => 96662372, end => 96662421 },
                D5 => { start => 96663069, end => 96663118 },
                D3 => { start => 96663158, end => 96663207 },
            },
            chr_start           => 96796597,
            chr_end             => 96806551,
            target_region_start => 96801058,
            target_region_end   => 96801804,
            cassette_start      => 96801006,
            cassette_end        => 96801057,
            loxp_start          => 96801805,
            loxp_end            => 96801843,
            floxed_exon_start   => 96801429,
            floxed_exon_end     => 96801606,
            homology_arm_start  => 96796597,
            homology_arm_end    => 96806551,
        },
    );

    for ( @test_data ) {
        $_->{design} = $test->htgt->resultset( 'Design' )->find( { design_id => $_->{design_id} } )
            or die "failed to retrieve design $_->{design_id}";
    }

    can_ok $test->class, 'new';

    for ( @test_data ) {
        ok my $i = $test->class->new( design => $_->{design} ), 'the constructor succeeds';
        isa_ok $i, $test->class, '...the object it returns';
        $_->{info} = $i;
    }

    $test->data( \@test_data );
}

sub slice_adaptor :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'slice_adaptor';
    for ( @{ $test->data } ) {
        isa_ok $_->{info}->slice_adaptor, 'Bio::EnsEMBL::DBSQL::SliceAdaptor';
    }
}

sub gene_adaptor :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'gene_adaptor';
    for ( @{ $test->data } ) {
        isa_ok $_->{info}->gene_adaptor, 'Bio::EnsEMBL::DBSQL::GeneAdaptor';
    }
}

sub species :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'species';

    for ( @{ $test->data } ) {
        is $_->{info}->species, 'Mus musculus', 'default species';
    }
}

sub features :Tests(1) {
    my $test = shift;

    can_ok $test->class, 'features';

    # TODO: check start/end for each feature
}

sub oligos :Tests(13) {
    my $test = shift;

    can_ok $test->class, 'oligos';

    for my $t ( @{ $test->data } ) {
        for my $o ( keys %{ $t->{oligos} } ) {
            is $t->{oligos}->{$o}->seq, $t->{info}->oligos->{$o}->seq, "$o oligo";
        }
    }
}

sub _test_accessor {
    my ( $test, $accessor ) = @_;

    can_ok $test->class, $accessor;

    for ( @{ $test->data } ) {
        is $_->{info}->$accessor, $_->{$accessor}, "$accessor is $_->{$accessor}";
    }
}

sub chr_name :Tests(3) {
    shift->_test_accessor( 'chr_name' );
}

sub chr_strand :Tests(3) {
    shift->_test_accessor( 'chr_strand' );
}

sub chr_start :Tests(3) {
    shift->_test_accessor( 'chr_start' );
}

sub chr_end :Tests(3) {
    shift->_test_accessor( 'chr_end' );
}

sub target_region_start :Tests(3) {
    shift->_test_accessor( 'target_region_start' );
}

sub target_region_end :Tests(3) {
    shift->_test_accessor( 'target_region_end' );
}

sub cassette_start :Tests(3) {
    shift->_test_accessor( 'cassette_start' );
}

sub cassette_end :Tests(3) {
    shift->_test_accessor( 'cassette_end' );
}

sub loxp_start :Tests(3) {
    shift->_test_accessor( 'loxp_start' );
}

sub loxp_end :Tests(3) {
    shift->_test_accessor( 'loxp_end' );
}

sub homology_arm_start :Tests(3) {
    shift->_test_accessor( 'homology_arm_start' );
}

sub homology_arm_end :Tests(3) {
    shift->_test_accessor( 'homology_arm_end' );
}

sub num_floxed_exons :Tests(3) {
    shift->_test_accessor( 'num_floxed_exons' );
}

sub first_floxed_exon :Tests(5) {
    my $test = shift;

    can_ok $test->class, 'first_floxed_exon';

    for ( @{ $test->data } ) {
        isa_ok $_->{info}->first_floxed_exon, 'Bio::EnsEMBL::Exon';
        is $_->{info}->first_floxed_exon->stable_id, $_->{first_floxed_exon}, "first floxed exon is $_->{first_floxed_exon}";
    }
}

sub last_floxed_exon :Tests(5) {
    my $test = shift;

    can_ok $test->class, 'last_floxed_exon';

    for ( @{ $test->data } ) {
        isa_ok $_->{info}->last_floxed_exon, 'Bio::EnsEMBL::Exon';
        is $_->{info}->last_floxed_exon->stable_id, $_->{last_floxed_exon}, "last floxed exon is $_->{last_floxed_exon}";
    }
}

sub floxed_exon_start :Tests(3) {
    shift->_test_accessor( 'floxed_exon_start' );
}

sub floxed_exon_end :Tests(3) {
    shift->_test_accessor( 'floxed_exon_end' );
}

sub mgi_gene :Tests(5) {
    my $test = shift;

    can_ok $test->class, 'mgi_gene';

    for ( @{ $test->data } ) {
        isa_ok $_->{info}->mgi_gene, 'HTGTDB::MGIGene';
        is $_->{info}->mgi_gene->marker_symbol, $_->{marker_symbol}, "marker symbol is $_->{marker_symbol}";
    }
}

sub build_gene :Tests(5) {
    my $test = shift;

    can_ok $test->class, 'build_gene';

    for ( @{ $test->data } ) {
        my $bg = $_->{info}->build_gene;
        isa_ok $bg, 'Bio::EnsEMBL::Gene';
        is $bg->stable_id, $_->{ensembl_gene_id}, "build_gene_id is $_->{ensembl_gene_id}";
    }
}

sub target_gene :Tests(5) {
    my $test = shift;

    can_ok $test->class, 'target_gene';

    for ( @{ $test->data } ) {
        isa_ok $_->{info}->target_gene, 'Bio::EnsEMBL::Gene';
        is $_->{info}->target_gene->stable_id, $_->{ensembl_gene_id}, "stable_id is $_->{ensembl_gene_id}";
    }
}

sub target_transcript :Tests(5) {
    my $test = shift;

    can_ok $test->class, 'target_transcript';

    for ( @{ $test->data } ) {
        isa_ok $_->{info}->target_transcript, 'Bio::EnsEMBL::Transcript';
        is $_->{info}->target_transcript->stable_id, $_->{transcript_id}, "transcript_id is $_->{transcript_id}";
    }
}

sub slice :Tests(5) {
    my $test = shift;

    can_ok $test->class, 'slice';

    for ( @{ $test->data } ) {
        isa_ok $_->{info}->slice, 'Bio::EnsEMBL::Slice';
        is $_->{info}->slice->display_id, $_->{slice_id}, "slice_id is $_->{slice_id}";
    }
}

sub constrained_elements :Tests(3) {
    my $test = shift;
$DB::single=1;
    can_ok $test->class, 'constrained_elements';

    for ( @{ $test->data } ) {
        isa_ok $_->{info}->constrained_elements, 'HASH';
    }

    #my $i = $test->class->new( $test->htgt->resultset( 'Design' )->find( { design_id => } ) );

}

sub repeat_regions :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'repeat_regions';

    for ( @{ $test->data } ) {
        isa_ok $_->{info}->repeat_regions, 'HASH';
    }
}

1;

__END__

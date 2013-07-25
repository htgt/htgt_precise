package MyTest::HTGT::Utils::DesignChecker::TargetRegion;

use strict;
use warnings FATAL => 'all';

use base qw( HTGT::Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::DesignChecker::TargetRegion' );
}

use Test::Most;
use HTGT::Utils::DesignChecker::TargetRegion;
use HTGT::Utils::DesignCheckRunner;
use Const::Fast;
use Bio::EnsEMBL::Registry;

const my $ASSEMBLY_ID => '101';
const my $BUILD_ID    => 'test_build';

#Setup Bio::EnsEMBL
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org',
    -user => 'anonymous',
);

my $gene_adaptor  = $registry->get_adaptor( 'Mouse', 'Core', 'gene' );

my @TEST_TARGET_REGION_STATUS_TESTS = (
    {   testname         => 'Design has one gene in target region, but it does not match project gene',
        design_id        => 55553,
        check_subroutine => 'target_gene_matches_project_gene',
        status           => 'target_gene_does_not_match_project_gene',
    },

    {   testname         => 'Design has multiple genes in target region, none of which match project gene',
        design_id        => 430363, 
        check_subroutine => 'target_gene_matches_project_gene',
        status           => 'multiple_non_matching_genes_in_target_region',
    },

    {   testname         => 'Design has one gene in target region no projects',
        design_id        => 39217,
        check_subroutine => 'target_gene_matches_project_gene',
        status           => 'unable_to_validate',
    },

    {   testname         => 'Design has projects linked to multiple mgi accession ids',
        design_id        => 33642,
        check_subroutine => 'target_gene_matches_project_gene',
        status           => 'design_projects_linked_to_multiple_mgi_genes',
    },

    {   testname         => 'Design has one gene in target region and projects with different genes',
        design_id        => 115588,
        check_subroutine => 'target_gene_matches_project_gene',
        status           => 'project_gene_matches_one_of_multiple_target_genes',
    },

    {   testname         => 'One of the coding transcripts for targeted gene is not hit',
        design_id        => 280668,
        ensembl_gene_id  => 'ENSMUSG00000031381',
        check_subroutine => 'all_coding_transcripts_targeted',
        status           => 'non_targeted_coding_transcripts',
        status_notes     => qr/Valid coding transcripts not targeted:/,
    },

    {   testname         => 'Coding transcript does not have phase shifted',
        design_id        => 176415,
        ensembl_gene_id  => 'ENSMUSG00000029282',
        check_subroutine => 'phase_shift_induced_in_transcripts',
        status           => 'no_phase_shift_for_transcript',
        status_notes     => qr/Coding transcripts do not have phase shifted by design:/,
    },

    {   testname         => 'Target gene has different design phases for its coding transcripts',
        design_id        => 221787,
        ensembl_gene_id  => 'ENSMUSG00000004872',
        check_subroutine => 'transcript_phase_match',
        status           => undef,
        status_notes     => qr/Transcript ENSMUST\d+ has a design phase of \d/,
    },

);

sub set_target_region_status_tests : Tests {
    my $test = shift;

    for my $t ( @TEST_TARGET_REGION_STATUS_TESTS ) {
        note( 'TEST: ' . $t->{testname} );

        my $target_region_status_checker = $test->_generate_target_region_status_checker( $t );

        my $check_subroutine = $t->{check_subroutine};
        lives_ok{ $target_region_status_checker->$check_subroutine } "can call $check_subroutine";

        is $target_region_status_checker->status
            , $t->{status}, $t->{testname} . ' Status is correct';

        if ( exists $t->{status_notes} ) {
            like $target_region_status_checker->status_notes->[0], $t->{status_notes}
                , $t->{testname} . ' Status notes are correct';
        }
    }
}

my @OVERALL_TARGET_REGION_STATUS_TESTS = (
    {   testname         => 'One of the coding transcripts for targeted gene is not hit, but its NMD',
        design_id        => 301348,
        status           => 'valid',
    },

    {   testname         => 'Coding transcript does not have phase shifted, but its NMD',
        design_id        => 259710,
        status           => 'valid',
    },

    {   testname         => 'Target gene different design phases coding transcripts, but one is NMD',
        design_id        => 117767,
        status           => 'valid',
    },

    {   testname         => 'Design passes target region checks',
        design_id        => 39792,
        status           => 'valid',
    },

    {   testname         => 'Design has multiple genes in target region, but one matches project gene',
        design_id        => 107633,
        status           => 'valid',
    },

);

sub overall_status : Tests {
    my $test = shift;

    for my $t ( @OVERALL_TARGET_REGION_STATUS_TESTS ) {
        note( 'TEST: ' . $t->{testname} );

        my $target_region_status_checker = $test->_generate_target_region_status_checker( $t );

        lives_ok{ $target_region_status_checker->check_status } "can call check_status";

        is $target_region_status_checker->status
            , $t->{status}, $t->{testname} . ' Status is correct';

        if ( exists $t->{status_notes} ) {
            like $target_region_status_checker->status_notes->[0], $t->{status_notes}
                , $t->{testname} . ' Status notes are correct';
        }
    }
}

sub _generate_target_region_status_checker{
    my ( $test, $t ) = @_;

    ok my $design = $test->eucomm_vector_schema->resultset('Design')->find(
        { design_id => $t->{design_id} }
    ), 'Found test design';

   my $gene;
   if ( $t->{ensembl_gene_id} ) {
       ok $gene = $gene_adaptor->fetch_by_stable_id( $t->{ensembl_gene_id} ), 'fetched gene';
       isa_ok $gene, 'Bio::EnsEMBL::Gene';
   }

    ok my $design_checker = HTGT::Utils::DesignCheckRunner->new(
        design      => $design,
        schema      => $test->eucomm_vector_schema,
        assembly_id => $ASSEMBLY_ID,
        build_id    => $BUILD_ID,
    ), 'Created design checker object';

    my %params = (
        design       => $design,
        strand       => $design_checker->strand,
        target_slice => $design_checker->target_slice,
    );
    $params{target_gene} = $gene if $gene;

    ok my $target_region_status_checker = HTGT::Utils::DesignChecker::TargetRegion->new(
        %params
    ), 'Create target region status checker object';

    isa_ok $target_region_status_checker, $test->class, $t->{testname};

    return $target_region_status_checker;
}
    
1;

__END__

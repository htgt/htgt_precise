package MyTest::HTGT::Utils::DesignChecker::DesignQuality;

use strict;
use warnings FATAL => 'all';

use base qw( HTGT::Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::DesignChecker::DesignQuality' );
}

use Test::Most;
use HTGT::Utils::DesignChecker::DesignQuality;
use Bio::EnsEMBL::Registry;
use Const::Fast;

const my $ASSEMBLY_ID => '101';
const my $BUILD_ID    => 'test_build';

my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org',
    -user => 'anonymous',
);
my $slice_adaptor  = $registry->get_adaptor( 'Mouse', 'Core', 'slice' );

my @TEST_DESIGN_QUALITY_STATUS_TESTS = (
    {   testname           => 'Design has no genes in target region',
        design_id          => 41064,  
        target_slice       => {
            chromosome => 7,
            start      => 1,
            end        => 3,
            strand     => 1,
        },
        check_subroutine => 'genes_in_target_region',
        status           => 'no_genes_in_target_region',
    },

    {   testname           => 'Design has no exons in target region',
        design_id          => 80068,  
        target_slice       => {
            chromosome => 7,
            start      => 1,
            end        => 3,
            strand     => 1,
        },
        check_subroutine => 'exons_in_target_region',
        status           => 'no_exons_in_target_region',
    },

    # The test of the status_notes may be flakey, if so just remove 
    {   testname           => 'Design has no exons in target region, but has intron',
        design_id          => 278619,  
        target_slice       => {
            chromosome => 11,
            start      => 96804000,
            end        => 96804001,
            strand     => 1,
        },
        check_subroutine => 'exons_in_target_region',
        status           => 'no_exons_in_target_region',
        status_notes     => qr/Transcript ENSMUST\d+ \( gene: ENSMUSG\d+ \) has intron within target region/,
    },

    {   testname           => 'Design only has non coding exons in target region',
        design_id          => 95294,  
        target_slice       => {
            chromosome => 1,
            start      => 161035860,
            end        => 161035861,
            strand     => 1,
        },
        check_subroutine => 'coding_exons',
        status           => 'non_coding_exons',
        status_notes     => qr/Target region has no coding transcripts overlapping it/,
    },

);

sub set_design_quality_status_tests : Tests {
    my $test = shift;

    for my $t ( @TEST_DESIGN_QUALITY_STATUS_TESTS ) {
        note( 'TEST: ' . $t->{testname} );

        my $design_quality_status_checker = $test->_generate_design_quality_status_checker( $t );

        my $check_subroutine = $t->{check_subroutine};
        lives_ok{ $design_quality_status_checker->$check_subroutine } "can call $check_subroutine";

        is $design_quality_status_checker->status
            , $t->{status}, $t->{testname} . ' Status is correct';

        if ( exists $t->{status_notes} ) {
            like $design_quality_status_checker->status_notes->[0], $t->{status_notes}
                , $t->{testname} . ' Status notes look correct';
        }
    }
}

my @OVERALL_DESIGN_QUALITY_STATUS_TESTS = (
    {   testname           => 'Design passes design quality checks',
        design_id          => 214629,  
        target_slice       => {
            chromosome => 11,
            start      => 96801460,
            end        => 96801470,
            strand     => 1,
        },
        status           => 'valid',
    },

);

sub overall_status : Tests {
    my $test = shift;

    for my $t ( @OVERALL_DESIGN_QUALITY_STATUS_TESTS ) {
        note( 'TEST: ' . $t->{testname} );

        my $design_quality_status_checker = $test->_generate_design_quality_status_checker( $t );

        lives_ok{ $design_quality_status_checker->check_status } "can call check_status";

        is $design_quality_status_checker->status
            , $t->{status}, $t->{testname} . ' Status is correct';
    }
}

sub _generate_design_quality_status_checker{
    my ( $test, $t ) = @_;

    ok my $design_quality_status_checker = HTGT::Utils::DesignChecker::DesignQuality->new(
        target_slice       => $test->_build_target_slice( $t->{target_slice} ),
    ), 'Create design quality status checker object';

    isa_ok $design_quality_status_checker, $test->class, $t->{testname};

    return $design_quality_status_checker;
}

sub _build_target_slice {
    my ( $test, $slice_info ) = @_;

    return $slice_adaptor->fetch_by_region(
        'chromosome',
        $slice_info->{chromosome},
        $slice_info->{start},
        $slice_info->{end},
        $slice_info->{strand},
    );
}
    
1;

__END__

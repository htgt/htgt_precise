package MyTest::HTGT::Utils::DesignChecker::ArtificialIntron;

use strict;
use warnings FATAL => 'all';

use base qw( HTGT::Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::DesignChecker::ArtificialIntron' );
}

use Test::Most;
use HTGT::Utils::DesignChecker::ArtificialIntron;
use HTGT::Utils::DesignCheckRunner;
use Const::Fast;

const my $ASSEMBLY_ID => '101';
const my $BUILD_ID    => 'test_build';

my @TEST_ARTIFICIAL_INTRON_STATUS_TESTS = (
    {   testname           => 'Design is artificial intron but not marked as such',
        design_id          => 393702,  
        check_subroutine   => 'design_marked_artificial_intron',
        status             => 'design_not_marked_artificial_intron',
    },

    {   testname           => 'U5 and U3 oligos are not adjacent to each other, strand +ve',
        design_id          => 393702,  
        check_subroutine   => 'u5_u3_oligos_adjacent',
        status             => 'u5_u3_oligos_not_adjacent',
    },

    {   testname           => 'U5 and U3 oligos are not adjacent to each other, strand -ve',
        design_id          => 369477,  
        check_subroutine   => 'u5_u3_oligos_adjacent',
        status             => 'u5_u3_oligos_not_adjacent',
    },

    {   testname           => 'End phase of target region is 0, -ve design',
        design_id          => 453784,  
        check_subroutine   => 'end_phase_target_region_not_zero',
        status             => 'end_phase_target_region_is_zero',
        status_notes       => qr/Transcript ENSMUST\d+ has target region end phase of 0/,
    },

    {   testname           => 'End phase of target region is 0, +ve design',
        design_id          => 453789,
        check_subroutine   => 'end_phase_target_region_not_zero',
        status             => 'end_phase_target_region_is_zero',
        status_notes       => qr/Transcript ENSMUST\d+ has target region end phase of 0/,
    },

    {   testname           => 'Boundary sequence is not correct, +ve strand',
        design_id          => 453790,  
        check_subroutine   => 'insertion_point_boundary_correct',
        status             => 'boundary_sequence_not_correct',
    },

    {   testname           => 'Boundary sequence is not correct, -ve strand',
        design_id          => 453786,  
        check_subroutine   => 'insertion_point_boundary_correct',
        status             => 'boundary_sequence_not_correct',
    },

);

sub set_artificial_intron_status_tests : Tests {
    my $test = shift;

    for my $t ( @TEST_ARTIFICIAL_INTRON_STATUS_TESTS ) {
        note( 'TEST: ' . $t->{testname} );

        my $artificial_intron_status_checker = $test->_generate_artificial_intron_status_checker( $t );

        ok $artificial_intron_status_checker->is_artificial_intron_design, 'design is artificial intron';

        my $check_subroutine = $t->{check_subroutine};
        lives_ok{ $artificial_intron_status_checker->$check_subroutine } "can call $check_subroutine";

        is $artificial_intron_status_checker->status
            , $t->{status}, $t->{testname} . ' Status is correct';

        if ( exists $t->{status_notes} ) {
            like $artificial_intron_status_checker->status_notes->[0], $t->{status_notes}
                , $t->{testname} . ' Status notes look correct';
        }
    }
}


# intron replacement
my @TEST_ARTIFICIAL_INTRON_REPLACEMENT_STATUS_TESTS = (
    {   testname           => 'Design is intron replacement but not marked as such',
        design_id          => 437840,
        check_subroutine   => 'design_marked_intron_replacement',
        status             => 'design_not_marked_intron_replacement',
    },

    {   testname           => 'Design is intron replacement but not marked as a artificial intron design',
        design_id          => 445983,
        check_subroutine   => 'design_marked_artificial_intron',
        status             => 'design_not_marked_artificial_intron',
    },

);

sub set_intron_replacement_tests : Tests {
    my $test = shift;

    for my $t ( @TEST_ARTIFICIAL_INTRON_REPLACEMENT_STATUS_TESTS ) {
        note( 'TEST: ' . $t->{testname} );

        my $artificial_intron_status_checker = $test->_generate_artificial_intron_status_checker( $t );

        ok $artificial_intron_status_checker->is_intron_replacement_design, 'design is intron replacement';

        my $check_subroutine = $t->{check_subroutine};
        lives_ok{ $artificial_intron_status_checker->$check_subroutine } "can call $check_subroutine";

        is $artificial_intron_status_checker->status
            , $t->{status}, $t->{testname} . ' Status is correct';

        if ( exists $t->{status_notes} ) {
            like $artificial_intron_status_checker->status_notes->[0], $t->{status_notes}
                , $t->{testname} . ' Status notes look correct';
        }
    }
}

my @OVERALL_ARTIFICIAL_INTRON_STATUS_TESTS = (
    {   testname         => 'Design passes artificial intron checks',
        design_id        => 378337,
        additional_check => 'is_artificial_intron_design',
        status           => 'valid',
    },

    {   testname         => 'Design passes intron replacement checks',
        design_id        => 440046,
        additional_check => 'is_intron_replacement_design',
        status           => 'valid',
    },

    {   testname         => 'Incorrectly marked artificial intron design',
        design_id        => 39217,
        check_subroutine => 'check_and_set_status',
        status           => 'incorrectly_marked_artificial_intron_design',
    },

);

sub overall_status : Tests {
    my $test = shift;

    for my $t ( @OVERALL_ARTIFICIAL_INTRON_STATUS_TESTS ) {
        note( 'TEST: ' . $t->{testname} );

        my $artificial_intron_status_checker = $test->_generate_artificial_intron_status_checker( $t );

        lives_ok{ $artificial_intron_status_checker->check_status } "can call check_status";

        if ( my $additional_check = $t->{additional_check} ) {
            ok $artificial_intron_status_checker->$additional_check, "passes $additional_check check";
        }

        is $artificial_intron_status_checker->status
            , $t->{status}, $t->{testname} . ' Status is correct';

        if ( exists $t->{status_notes} ) {
            like $artificial_intron_status_checker->status_notes->[0], $t->{status_notes}
                , $t->{testname} . ' Status notes look correct';
        }
    }
}

sub _generate_artificial_intron_status_checker{
    my ( $test, $t ) = @_;

    ok my $design = $test->eucomm_vector_schema->resultset('Design')->find(
        { design_id => $t->{design_id} }
    ), 'Found test design';

    # creating DesignCheckRunnerer object so I can use its code to get strand and target_slice data
    ok my $design_checker = HTGT::Utils::DesignCheckRunner->new(
        design      => $design,
        schema      => $test->eucomm_vector_schema,
        assembly_id => $ASSEMBLY_ID,
        build_id    => $BUILD_ID,
    ), 'Created design checked object';

    ok my $artificial_intron_status_checker = HTGT::Utils::DesignChecker::ArtificialIntron->new(
        design             => $design,
        features           => $design->validated_display_features,
        strand             => $design_checker->strand,
        target_slice       => $design_checker->target_slice,
    ), 'Create artificial intron status checker object';

    isa_ok $artificial_intron_status_checker, $test->class, $t->{testname};

    return $artificial_intron_status_checker;
}
    
1;

__END__

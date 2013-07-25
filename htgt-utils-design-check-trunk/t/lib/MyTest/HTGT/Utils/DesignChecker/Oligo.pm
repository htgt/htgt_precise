package MyTest::HTGT::Utils::DesignChecker::Oligo;

use strict;
use warnings FATAL => 'all';

use base qw( HTGT::Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::DesignChecker::Oligo' );
}

use Test::Most;
use HTGT::Utils::DesignChecker::Oligo;
use Const::Fast;

const my $ASSEMBLY_ID => '101';
const my $BUILD_ID    => 'test_build';

my @TEST_OLIGO_STATUS_TESTS = (
    {   testname         => 'Design has Multiple Oligos',
        design_id        => 41064,
        check_subroutine => 'no_multiple_oligos',
        status           => 'multiple_oligos',
        status_notes     => [ 'Multiple U5 oligos' ],
    },

    {   testname         => 'Design has Missing Oligos',
        design_id        => 80068,
        check_subroutine => 'expected_oligos',
        status           => 'missing_oligos',
        status_notes     => [ 'Missing oligo U5' ],
    },

    {   testname         => 'Design has Invalid Oligos',
        design_id        => 278619,
        check_subroutine => 'oligo_validity',
        status           => 'invalid_oligos',
        status_notes     => [ 'Oligo U5 has end before start' ],
    },

    {   testname         => 'Design has inconsistent Oligo chromosomes',
        design_id        => 278619,
        check_subroutine => 'consistent_chromosome',
        status           => 'inconsistent_chromosome',
        status_notes     => [ 'Oligos found on multiple chromosomes 1 4' ],
    },

    {   testname         => 'Design has inconsistent Oligo strands',
        design_id        => 278619,
        check_subroutine => 'consistent_strand',
        status           => 'inconsistent_strand',
        status_notes     => [ ],
    },

    {   testname         => 'Design has G5 and G3 oligos in wrong order on +ve strand',
        design_id        => 95294,
        check_subroutine => 'expected_order',
        status           => 'g5_g3_oligos_wrong_order',
        status_notes     => [ 'G5 oligo after G3 oligo on +ve strand' ],
    },

    {   testname         => 'Design has G5 and G3 oligos in wrong order on -ve strand',
        design_id        => 39205,
        check_subroutine => 'expected_order',
        status           => 'g5_g3_oligos_wrong_order',
        status_notes     => [ 'G3 oligo after G5 oligo on -ve strand' ],
    },

    {   testname         => 'Design has unexpected oligo order on +ve strand',
        design_id        => 39496,
        check_subroutine => 'expected_order',
        status           => 'unexpected_oligo_order',
        status_notes     => [ 'Oligos U5 and U3 in unexpected order'],
    },

    {   testname         => 'Design has unexpected oligo order on -ve strand',
        design_id        => 262,
        check_subroutine => 'expected_order',
        status           => 'unexpected_oligo_order',
        status_notes     => [ 'Oligos U3 and U5 in unexpected order'],
    },

);

sub set_oligo_status_tests : Tests {
    my $test = shift;

    for my $t ( @TEST_OLIGO_STATUS_TESTS ) {
        note( 'TEST: ' . $t->{testname} );

        my $oligo_status_checker = $test->_generate_oligo_status_checker( $t );

        my $check_subroutine = $t->{check_subroutine};
        lives_ok{ $oligo_status_checker->$check_subroutine } "can call $check_subroutine";

        is $oligo_status_checker->status
            , $t->{status}, $t->{testname} . ' Status is correct';

        if ( exists $t->{status_notes} ) {
            is_deeply $oligo_status_checker->status_notes, $t->{status_notes}
                , $t->{testname} . ' Status notes are correct';
        }
    }
}

my @OVERALL_OLIGO_STATUS_TESTS = (
    {   testname         => 'Design passes oligo checks, knock out design',
        design_id        => 39217,
        status           => 'valid',
        status_notes     => [ 'Number of bases from G5 to G3 oligo is 10992'],
    },

    {   testname         => 'Design passes oligo checks, deletion design',
        design_id        => 214629,
        status           => 'valid',
        status_notes     => [ 'Number of bases from G5 to G3 oligo is 14720'],
    },

    {   testname         => 'Design fails oligos tests',
        design_id        => 262,
        status           => 'unexpected_oligo_order',
        status_notes     => [ 'Oligos U3 and U5 in unexpected order'],
    },
);

sub overall_oligo_status : Tests {
    my $test = shift;

    for my $t ( @OVERALL_OLIGO_STATUS_TESTS ) {
        note( 'TEST: ' . $t->{testname} );

        my $oligo_status_checker = $test->_generate_oligo_status_checker( $t );

        lives_ok{ $oligo_status_checker->check_status } "can call check_status";

        is $oligo_status_checker->status
            , $t->{status}, $t->{testname} . ' Status is correct';

        if ( exists $t->{status_notes} ) {
            is_deeply $oligo_status_checker->status_notes, $t->{status_notes}
                , $t->{testname} . ' Status notes are correct';
        }
    }
}

sub _generate_oligo_status_checker{
    my ( $test, $t ) = @_;

    ok my $design = $test->eucomm_vector_schema->resultset('Design')->find(
        { design_id => $t->{design_id} }
    ), 'Found test design';

    ok my $oligo_status_checker = HTGT::Utils::DesignChecker::Oligo->new(
        design             => $design,
        assembly_id        => $ASSEMBLY_ID,
        design_type        => $design->design_type ? $design->design_type : 'KO',
    ), 'Create oligo status checker object';

    isa_ok $oligo_status_checker, $test->class, $t->{testname};

    return $oligo_status_checker;
}
    
1;

__END__

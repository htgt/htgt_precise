package MyTest::HTGT::Utils::DesignChecker::Role;

use strict;
use warnings FATAL => 'all';

use base qw( HTGT::Test::Class Class::Data::Inheritable );

use Test::Most;
# Testing role, use Oligo checker, which consumes the role we want to test
use HTGT::Utils::DesignChecker::Oligo;
use Const::Fast;

const my $ASSEMBLY_ID => '101';
const my $BUILD_ID    => 'test_build';

my @DESIGN_CHECK_ROLE_TESTS = (
    {   testname           => 'Design passes oligo checks',
        design_id          => 39217,
        status             => 'valid',
        valid              => 1,
    },

    {   testname           => 'Design fails oligo tests, unexpected_oligo_order',
        design_id          => 262,
        status             => 'unexpected_oligo_order',
        valid              => 0,
    },

    {   testname           => 'Design fails oligo tests, multiple_oligos',
        design_id          => 41064,
        status             => 'multiple_oligos',
        valid              => 0,
    },
);

#override the test that just failed to make it valid
my @OVERRIDE_TESTS = (
   {   testname           => 'Override failed oligo tests, unexpected_oligo_order',
        design_id         => 262,
        status            => 'unexpected_oligo_order',
        table             => 'DaOligoStatus', #so we can crfeate the status if it doesn't exist
        expected_status => 'valid', #rename this
    },
);

sub overall_oligo_status : Tests {
    my $test = shift;

    for my $t ( @DESIGN_CHECK_ROLE_TESTS ) {
        note( 'TEST: ' . $t->{testname} );

        my $oligo_status_checker = $test->_generate_oligo_status_checker( $t );

        lives_ok{ $oligo_status_checker->update_design_annotation_status }
            "can call update_design_annotation_status";

        is $oligo_status_checker->status
            , $t->{status}, $t->{testname} . ' Status is correct';

        is $oligo_status_checker->valid, $t->{valid}, ' and valid flag is correct';

    }
}

sub overridden_status : Tests {
    my $test = shift;

    for my $t ( @OVERRIDE_TESTS ) {
        my $oligo_status_checker = $test->_generate_oligo_status_checker( $t );

        #make sure this status exists as this data isn't copied into the sqlite database
        ok $test->eucomm_vector_schema->resultset($t->{table})->find_or_create(
            oligo_status_id   => $t->{status},
            oligo_status_desc => 'test data for ' . $t->{status},
        );

        #create a new human annotation status
        ok my $human_annotation_status = $test->eucomm_vector_schema->resultset('DaHumanAnnotationStatus')->create(
            {
                override                     => 1,
                human_annotation_status_id   => 'ignore_' . $t->{status},
                human_annotation_status_desc => 'ignores ' . $t->{status},
                oligo_status_id              => $t->{status},
            }
        ), 'Created human annotation status object';

        #create a new human annotation for this design
        ok my $human_annotation = $test->eucomm_vector_schema->resultset('DaHumanAnnotation')->create(
            {
                design_annotation_id       => $oligo_status_checker->design_annotation->design_annotation_id,
                human_annotation_status_id => $human_annotation_status->human_annotation_status_id,
                oligo_status_id            => $t->{ status },
                created_by                 => 'test'
            }
        ), 'Created human annotation object';

        lives_ok{ $oligo_status_checker->update_design_annotation_status }
            "can call update_design_annotation_status";

        #check the new status is what we want
        is $oligo_status_checker->status
            , $t->{ expected_status }, $t->{testname} . ' Status is correct';
    }
}

sub _generate_oligo_status_checker{
    my ( $test, $t ) = @_;

    ok my $design = $test->eucomm_vector_schema->resultset('Design')->find(
        { design_id => $t->{design_id} }
    ), 'Found test design';

    ok my $design_annotation = $test->eucomm_vector_schema->resultset('DesignAnnotation')->create(
        {
            design_id   => $design->design_id,
            assembly_id => $ASSEMBLY_ID,
            build_id    => $BUILD_ID,
        }
    ), 'Created design annotation object';

    ok my $oligo_status_checker = HTGT::Utils::DesignChecker::Oligo->new(
        design             => $design,
        assembly_id        => $ASSEMBLY_ID,
        design_type        => $design->design_type ? $design->design_type : 'KO',
        design_annotation  => $design_annotation,
    ), 'Create oligo status checker object';

    return $oligo_status_checker;
}
    
1;

__END__

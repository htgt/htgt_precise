package MyTest::HTGT::Utils::DesignAnnotationSearch;

use strict;
use warnings FATAL => 'all';
use Const::Fast;

use base qw( HTGT::Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::DesignAnnotationSearch' );
}

use Test::Most;
use HTGT::Utils::DesignAnnotationSearch;

const my $ASSEMBLY_ID => 101;
const my $BUILD_ID    => 69.38;

sub startup : Tests(startup => 2) {
    my $test = shift;
    use_ok $test->class;
    
    my $schema = $test->eucomm_vector_schema;
    
    ok $test->{o} = $test->class->new(
        schema       => $schema,
        input_data   => '446586',
        assembly_id  => $ASSEMBLY_ID,
        build_id     => $BUILD_ID,
    ), '..create test object';
}

sub after : Tests(teardown => 1) {
    my $test = shift;
    ok ( !$test->{o}->clear_errors, '..clear error log');
}

sub constructor :Tests(2) {
    my $test = shift;
    
    can_ok $test->class, 'new';
    isa_ok $test->{o}, $test->class;
}

sub find_design_annotation : Tests(3) {
    my $test = shift;
    
    ok my $design_annotations = $test->{o}->find_annotations
        , '..can grab design_annotation';
    is @{ $design_annotations }, 1, 'have one design annotation';
    isa_ok $design_annotations->[0], 'HTGTDB::DesignAnnotation';
    
}

sub design_with_no_annotation : Tests(3) {
    my $test = shift;

    ok my $o = $test->class->new(
        schema      => $test->eucomm_vector_schema,
        input_data  => '80068',
        assembly_id => $ASSEMBLY_ID,
        build_id    => $BUILD_ID,
    ), 'can create test object';

    ok my $design_annotations = $o->find_annotations
        , '..can grab design_annotation';

    is @{ $design_annotations }, 0, 'have no design annotation';
}

sub get_designs_by_marker_symbol : Tests(3) {
    my $test= shift;

    ok my $designs = $test->{o}->_get_designs_by_marker_symbol('Maoa');
    ok @{ $designs } == 1, '.. return 1 design';
    is $designs->[0], 41064, '.. and is correct design';
}

sub non_existant_marker_symbol : Tests(3) {
    my $test= shift;

    ok ( my $designs_non_existant_gene = $test->{o}->_get_designs_by_marker_symbol('test')
        , '..can not retrieve non existant gene' );
    is_deeply $designs_non_existant_gene, [], '.. returns empty array ref';
    is_deeply $test->{o}->errors, ['Marker Symbol does not exist: test']
        , '.. correct error message';
}
    
sub gene_with_no_projects : Tests(3) {
    my $test= shift;

    ok ( my $designs_no_project_gene = $test->{o}->_get_designs_by_marker_symbol('1700021K19Rik')
        , '..can not retrieve gene with no projects' );
    is_deeply $designs_no_project_gene, [], '.. returns empty array ref';
    is_deeply $test->{o}->errors, ['Marker Symbol does not have any valid projects: 1700021K19Rik']
        , '.. correct error message';
}

1;

__END__

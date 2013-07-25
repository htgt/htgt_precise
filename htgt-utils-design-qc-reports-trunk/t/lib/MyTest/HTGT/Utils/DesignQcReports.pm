package MyTest::HTGT::Utils::DesignQcReports;

use strict;
use warnings FATAL => 'all';

use base qw( HTGT::Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::DesignQcReports' );
}

use Test::Most;
use HTGT::Utils::DesignQcReports;

sub startup : Tests(startup => 2) {
    my $test = shift;
    use_ok $test->class;
    
    my $schema = $test->eucomm_vector_schema;
    
    ok $test->{o} = $test->class->new(
        schema       => $schema,
        input_data   => '41044'
    ), '..create test object';
}

sub constructor :Tests(2) {
    my $test = shift;
    
    can_ok $test->class, 'new';
    isa_ok $test->{o}, $test->class;
}

sub invalid_input : Tests(1) {
    my $test = shift;

    throws_ok {
        $test->class->new(
            schema     => $test->eucomm_vector_schema,
            input_data => undef,
        )
    } qr/Attribute \(input_data\) does not pass the type constraint because: Validation failed for 'Str'/,
    'input data not specified';

}

sub get_design : Tests(5) {
    my $test = shift;
    
    ok my $design = $test->{o}->_get_design('41044'), '..can grab design';
    isa_ok $design, 'HTGTDB::Design';
    
    ok ( !$test->{o}->_get_design('1'), '..can not retrieve non existant design');
    is_deeply $test->{o}->errors, ['Can not find design: 1'], '.. correct error message';
    ok ( !$test->{o}->clear_errors, '..clear error log');
    
}

sub get_designs_by_marker_symbol : Tests(11) {
    my $test= shift;

    ok my $designs = $test->{o}->_get_designs_by_marker_symbol('Ctcfl');
    ok @{ $designs } == 1, '.. return 1 design';
    my $design = $designs->[0];
    isa_ok $design, 'HTGTDB::Design';
    
    ok ( my $designs_non_existant_gene = $test->{o}->_get_designs_by_marker_symbol('test'), '..can not retrieve non existant gene' );
    is_deeply $designs_non_existant_gene, [], '.. returns empty array ref';
    is_deeply $test->{o}->errors, ['Marker Symbol does not exist: test'], '.. correct error message';
    ok ( !$test->{o}->clear_errors, '..clear error log');

    ok ( my $designs_no_project_gene = $test->{o}->_get_designs_by_marker_symbol('1700021K19Rik'), '..can not retrieve gene with no projects' );
    is_deeply $designs_no_project_gene, [], '.. returns empty array ref';
    is_deeply $test->{o}->errors, ['Marker Symbol does not have any valid projects: 1700021K19Rik'], '.. correct error message';
    ok ( !$test->{o}->clear_errors, '..clear error log');
}

1;

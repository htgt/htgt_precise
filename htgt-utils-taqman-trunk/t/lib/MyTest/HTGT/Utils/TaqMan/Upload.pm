package MyTest::HTGT::Utils::TaqMan::Upload;

use strict;
use warnings FATAL => 'all';

use base qw( HTGT::Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::TaqMan::Upload' );
}

use Test::Most;
use HTGT::Utils::TaqMan::Upload;

sub startup : Tests(startup => 2) {
    my $test = shift;
    use_ok $test->class;

    my $schema = $test->eucomm_vector_schema;

    my $test_file = IO::File->new_tmpfile or die('Could not create temp test file ' . $!);
    $test_file->print('Well,Assay_ID,marker_symbol,design_region,design_id,forward_primer_seq,reverse_primer_seq,reporter_probe_seq' . "\n");
    $test_file->print('A02,Adcy5_U_CC89JF6,Adcy5,u,220202,CTAGGAGGGACCTGGATGTCA,AGAAGCCAGCAACAGTTCCT,ACTACAAGCTGGAGTCTGAATCC' . "\n");

    $test_file->seek(0,0);
    $test->{user} = 'test_user';
    $test->{plate_name} = 'QPCRDR0002';

    ok $test->{o} = $test->class->new(
        schema       => $schema,
        csv_filename => $test_file,
        plate_name   => $test->{plate_name},
        user         => $test->{user},
    ), '..create test object';
}

sub constructor :Tests(2) {
    my $test = shift;

    can_ok $test->class, 'new';
    isa_ok $test->{o}, $test->class;
}

sub after : Test(teardown) {
    my $test = shift;
    $test->{o}->clear_errors;
}

sub build : Tests(5) {
    my $test = shift;

    ok my $taqman_assay = $test->eucomm_vector_schema->resultset('DesignTaqmanAssay')->find({ design_id => '220202' }), '.. found taqman assay id object';
    is $taqman_assay->assay_id, 'Adcy5_U_CC89JF6', '.. correct assay id';
    is $taqman_assay->well_name, 'A02', '.. correct well name';
    is $taqman_assay->taqman_plate->name, 'QPCRDR0002', '.. correct plate name';
    is_deeply $test->{o}->update_log, ['assay id: Adcy5_U_CC89JF6, linked to design: 220202'];
}

sub get_design : Tests(4) {
    my $test = shift;

    ok my $design = $test->{o}->_get_design('41044'), '..can grab design';
    isa_ok $design, 'HTGTDB::Design';

    ok ( !$test->{o}->_get_design('1'), '..can not retrieve non existant design');
    is_deeply $test->{o}->errors, ['Could not find design: 1'], '.. correct error message';

}

sub existing_assay_well : Tests(3){
    my $test = shift;

    ok $test->{o}->_existing_assay_well('A01'), '..has existing assay well';
    is_deeply $test->{o}->errors, ['There is already a A01 well associated with plate: QPCRDR0002'], '.. correct error message';
    ok ( !$test->{o}->_existing_assay_well('Z01'), '..does not have new well' );
}

sub existing_assay_id : Tests(3) {
    my $test = shift;

    ok $test->{o}->_existing_assay_id('17_K19_U_CC6RM30'), '..assay id already exists';
    is_deeply $test->{o}->errors, ['Assay ID: 17_K19_U_CC6RM30 already exists in database on plate: QPCRDR0002'], '.. correct error message';
    ok ( !$test->{o}->_existing_assay_id('test_assay_id'), '.. does not have new assay id' );
}

sub invalid_deleted_region : Tests(3) {
    my $test = shift;

    ok $test->{o}->_invalid_deleted_region('z'), '..invalid delete region';
    is_deeply $test->{o}->errors, ['z is not a valid deleted region'], '.. correct error message';
    ok ( !$test->{o}->_invalid_deleted_region('u'), '.. we have valid deleted region' );
}

sub _has_recognised_data : Tests(3) {
    my $test = shift;

    ok $test->{o}->_has_recognised_data( [ qw( Well Assay_ID design_id ) ] ), 'has recognised data';
    ok !$test->{o}->_has_recognised_data( [ qw( Well Assay_ID design_id probe_seq ) ] ), 'has unrecognised data';
    is_deeply $test->{o}->errors, ['Unrecognised column: probe_seq'], '.. correct error message';
}

sub _has_required_data : Tests(3) {
    my $test = shift;

    ok $test->{o}->_has_required_data(
        { design_id => 123, Well => 'A01', Assay_ID => 'asda234', design_region => 'u'  }, 1
    ), 'has required data';
    ok !$test->{o}->_has_required_data(
        { design_id => 123, Assay_ID => 'asda123', Well => 'A01' }, 1
    ), 'does not have required data';
    is_deeply $test->{o}->errors, ['Line 1 is missing required data: design_region'], '.. correct error message';
}

1;

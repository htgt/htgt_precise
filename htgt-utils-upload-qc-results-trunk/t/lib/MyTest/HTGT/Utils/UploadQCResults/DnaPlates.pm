package MyTest::HTGT::Utils::UploadQCResults::DnaPlates;

use strict;
use warnings FATAL => 'all';
use FindBin;
use IO::File;

use base qw( HTGT::Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::UploadQCResults::DnaPlates' );
}

use Test::Most;
use HTGT::Utils::UploadQCResults::DnaPlates;
use IO::File;

sub constructor : Tests(2) {
    my $test = shift;
    use_ok $test->class;
    isa_ok $test->{o}, $test->class, '..constructor returned correct object';
}

sub after : Test(teardown) {
    my $test = shift;
    $test->{o}->clear_errors;
    $test->{o}->clear_log;
    $test->{o}->clear_dna_plate_data;
    $test->{o}->reset_line_number;
}

sub before : Test(setup) {
    my $test = shift;

    my $input_file = IO::File->new_tmpfile()
        or die('Could not create temp input file ' . $!);
    
    $input_file->print("plate,well,clone_name\n");
    $input_file->print(",,,\n");
    $input_file->print("SBDNA00001,C11,EPD0251_5_E01\n");
    $input_file->print("SBDNA00001,C12,EPD0251_5_E02\n");
    $input_file->print("SBDNA00001,C13,EPD0301_3_B05\n");
    $input_file->seek(0,0);

    $test->{o} = $test->class->new(
        schema         => $test->eucomm_vector_schema,
        input          => $input_file,
        user           => 'test_user',
        dna_plate_type => 'SBDNA'
    );
}

sub csv_reader : Tests(2) {
    my $test = shift;

    isa_ok $test->{o}->csv_reader, 'CSV::Reader', 'Initialized a CSV::Reader object';
    ok $test->{o}->csv_reader->use_header, 'CSV::Reader use_header attribute set to true';
}

sub dna_plate_type : Tests(2) {
    my $test = shift;

    is $test->{o}->dna_plate_type, 'SBDNA', 'expected dna_plate_type';

    my $input_file = IO::File->new_tmpfile()
        or die('Could not create temp input file ' . $!);

    throws_ok {
        my $t = $test->class->new(
            schema         => $test->eucomm_vector_schema,
            input          => $input_file,
            user           => 'test_user',
            dna_plate_type => 'test',
        )
    } qr/Unrecognised dna plate type: test/, 'invalid dna plate type'; 
}

sub _get_epd_well : Tests(8) {
    my $test = shift;

    my $t = $test->{o};

    ok !$t->_get_epd_well('blah', 'AO1'), 'return false when invalid well name specified';
    is_deeply( $t->errors, [ 'Unable to find epd clone: blah line 0' ], 'error invalid epd well name');
    $t->clear_errors;

    ok !$t->_get_epd_well('E02', 'FP1138'), 'return false when sending in non epd well';
    is_deeply( $t->errors, [ 'Unable to find epd clone: E02 line 0' ], 'error non epd well');
    $t->clear_errors;

    ok ( my $epd_well = $t->_get_epd_well('EPD0694_3_A05', 'EPD0694_3'), 'valid epd well name' );
    isa_ok $epd_well, 'HTGTDB::Well';
    is $epd_well->well_name, 'EPD0694_3_A05', '.. and is correct epd well';
    is_deeply( $t->errors,[], '... and no errors'); 
    $t->clear_errors;
}

sub find_or_create_plate : Tests(11) {
    my $test = shift;

    my $t = $test->{o};
    
    ok my $plate = $t->find_or_create_plate('SBDNA0001'), 'call find_or_create_plate - create';
    isa_ok $plate, 'HTGTDB::Plate';
    is $plate->name, 'SBDNA0001', '.. plate has right name';
    is $plate->type, 'SBDNA', '.. plate has right type';
    my $plate_id = $plate->plate_id;
    is_deeply( $t->update_log,['Created plate SBDNA0001 : ' . $plate_id], '.. correct log message' );
    is_deeply( $t->errors,[], '.. and no errors' );

    ok my $same_plate = $t->find_or_create_plate('SBDNA0001'), 'call find_or_create_plate - find';
    isa_ok $same_plate, 'HTGTDB::Plate';
    is $same_plate->plate_id, $plate_id, '.. returned same plate';
    is_deeply( $t->update_log,['Created plate SBDNA0001 : ' . $plate_id], '.. log message not changed' );
    is_deeply( $t->errors,[], '.. and no errors' );
}

sub check_and_create_well : Tests(12) {
    my $test = shift;

    my $schema = $test->eucomm_vector_schema;
    my $t = $test->{o};

    ok my $plate = $t->find_or_create_plate('SBDNA0002'), 'grab SBDNA0002 plate';
    $test->{o}->clear_log;
    ok my $epd_well = $t->_get_epd_well('EPD0694_3_A05', 'EPD0694_3'), 'grab parent epd well';

    ok $t->check_and_create_well( $plate, 'A01', $epd_well ), '.. can call check_and_create_well';
    ok my $well = $plate->wells->find( { well_name => 'A01' } ), '.. found newly created well';
    is $well->parent_well->well_name, 'EPD0694_3_A05', '.. has correct parent well';
    is_deeply( $t->update_log, [ 'Created A01 well on plate: SBDNA0002, with parent: EPD0694_3_A05' ]
        , '.. correct log message' );
    is_deeply( $t->errors,[], '.. and no errors' );
    $test->{o}->clear_log;

    my $epd_plate = $epd_well->plate;
    ok my $plate_plate = $schema->resultset('PlatePlate')->find(
        {
            parent_plate_id => $epd_plate->plate_id,
            child_plate_id  => $plate->plate_id,
        }
    ), '.. plate_plate entry entered correctly';

    ok my $epd_well2 = $t->_get_epd_well('EPD0251_5_G02', 'EPD0251_5'), 'grab new epd well';
    ok $t->check_and_create_well( $plate, 'A01', $epd_well2 ), '.. check_and_create_well ok';
    is_deeply( $t->update_log,[ 'SBDNA0002 plate has A01 well that belongs to a ' 
                            . 'different parent well EPD0694_3_A05, changing to new parent well EPD0251_5_G02' ]
               , '.. and has correct errors' );
    is_deeply( $t->errors,[], '.. and update log' );


}

sub parse_csv : Tests(7) {
    my $test = shift;
    my $t = $test->{o};

    lives_ok { $t->parse_csv } 'can parse sample csv';
    is_deeply( $t->errors, [], '..has no errors' );

    ok my $epd_well1 = $t->_get_epd_well('EPD0251_5_E01', 'EPD0251_5'), 'grab parent epd well';
    ok my $epd_well2 = $t->_get_epd_well('EPD0251_5_E02', 'EPD0251_5'), 'grab parent epd well';
    ok my $epd_well3 = $t->_get_epd_well('EPD0301_3_B05', 'EPD0301_3'), 'grab parent epd well';
    is_deeply( $t->dna_plate_data, 
        { SBDNA00001 => { C11 => $epd_well1, C12 => $epd_well2, C13 => $epd_well3 } }
               , '.. dna_plate_data hash is correct' );
    is $t->line_number, 3, '.. only parsed 3 line, blank csv line ignored';
}

sub _parse_line : Tests(15) {
    my $test = shift;
    my $t = $test->{o};

    my $missing_value_data = { plate => 'blah', well => undef, clone_name => 'test' };
    ok !$t->_parse_line( $missing_value_data ), '_parse_line with undef value';
    is_deeply( $t->errors, [ 'Missing well name line 1' ], '.. correct error message' );
    is_deeply( $t->dna_plate_data, {}, '.. empty dna_plate_data hash' );
    $t->clear_errors;

    my $invalid_plate_name_data = { plate => 'blah', well => 'A01', clone_name => 'EPD0251_5_G01' };
    ok !$t->_parse_line( $invalid_plate_name_data ), '_parse_line with invalid plate name';
    is_deeply( $t->errors, [ 'Invalid plate name: blah line 2' ], '.. correct error message' );
    is_deeply( $t->dna_plate_data, {}, '.. empty dna_plate_data hash' );
    $t->clear_errors;

    my $invalid_plate_type_data = { plate => 'QPCRDNA0001', well => 'A01', clone_name => 'EPD0251_5_G01' };
    ok !$t->_parse_line( $invalid_plate_type_data ), '_parse_line with invalid plate type';
    is_deeply( $t->errors, [ 'Invalid plate name: QPCRDNA0001 line 3' ], '.. correct error message' );
    is_deeply( $t->dna_plate_data, {}, '.. empty dna_plate_data hash' );
    $t->clear_errors;

    my $invalid_well_name_data = { plate => 'SBDNA0001', well => 'test', clone_name => 'EPD0251_5_G01' };
    ok !$t->_parse_line( $invalid_well_name_data ), '_parse_line with invalid well name';
    is_deeply( $t->errors, [ 'Invalid well name: test line 4' ], '.. correct error message' );
    is_deeply( $t->dna_plate_data, {}, '.. empty dna_plate_data hash' );
    $t->clear_errors;

    my $invalid_epd_name_data = { plate => 'SBDNA0001', well => 'A01', clone_name => 'test' };
    ok !$t->_parse_line( $invalid_epd_name_data ), '_parse_line with invalid well name';
    is_deeply( $t->errors, [ 'Unable to find epd clone: test line 5' ], '.. correct error message' );
    is_deeply( $t->dna_plate_data, {}, '.. empty dna_plate_data hash' );
    $t->clear_errors;
}

sub update_qc_results : Tests(9) {
    my $test = shift;
    my $t = $test->{o};
    my $schema = $test->eucomm_vector_schema;

    ok !$t->update_qc_results(), 'fails if called without parsing csv';
    lives_ok { $t->parse_csv } 'can parse sample csv';
    is_deeply( $t->errors, [], '.. has no errors' );
    $t->add_error('test');
    ok !$t->update_qc_results(), '.. failed if called when we have errors';
    $t->clear_errors;

    lives_ok { $t->update_qc_results } 'can update well qc results';
    ok my $plate = $schema->resultset('Plate')->find( { name => 'SBDNA00001' } ), '.. can grab qc dna plate';
    is $plate->type, 'SBDNA', '.. has correct plate type';
    ok my $well = $plate->wells->find( { well_name => 'C11' } ), '.. can grab qc dna well';
    is $well->parent_well->well_name, 'EPD0251_5_E01', '.. and well has correct epd parent well';
}

sub update_parent_well : Tests(10) {
    my $test = shift;

    my $t = $test->{o};

    lives_ok { $t->parse_csv } 'can parse sample csv';
    lives_ok { $t->update_qc_results } 'can update well qc results';
    $t->clear_log;

    ok my $plate = $t->find_or_create_plate('SBDNA00001'), 'grab SBDNA00001 plate';
    ok my $well = $plate->wells->find( { well_name => 'C11' } ), '.. can grab qc dna well';
    ok my $new_parent_well = $t->_get_epd_well('EPD0694_3_A05', 'EPD0694_3'), 'grab parent epd well';

    ok $t->update_parent_well( $plate, $well, $new_parent_well ), 'update parent well';
    is $well->parent_well_id, $new_parent_well->well_id, '.. well has correct parent well id';
    is $well->design_instance_id, $new_parent_well->design_instance_id, '.. well has correct design instance';
    is_deeply( $t->update_log, [ 'SBDNA00001 plate has C11 well that belongs to a different parent well EPD0251_5_E01, changing to new parent well EPD0694_3_A05' ], '.. has correct log message' );
    is_deeply( $t->errors, [], '.. has no errors' );
}

sub update_plate_plate : Tests(15) {
    my $test = shift;

    my $t = $test->{o};
    my $schema = $test->eucomm_vector_schema;

    lives_ok { $t->parse_csv } 'can parse sample csv';
    lives_ok { $t->update_qc_results } 'can update well qc results';

    ok my $plate = $t->find_or_create_plate('SBDNA00001'), 'grab SBDNA00001 plate';

    ok my $old_parent_plate = $t->find_or_create_plate('EPD0301_3'), 'grab EPD0301_3 plate';
    ok my $well             = $plate->wells->find( { well_name => 'C13' } ), '.. can grab qc dna well';
    ok my $new_parent_well  = $t->_get_epd_well('EPD0034_2_A03', 'EPD0034_2'), 'grab parent epd well';
    ok $t->update_parent_well( $plate, $well, $new_parent_well ), 'update_plate_plate okay';
    ok my $plate_plate = $schema->resultset('PlatePlate')->find(
        {
            parent_plate_id => $new_parent_well->plate->plate_id,
            child_plate_id  => $plate->plate_id,
        }
    ), '.. created new plate plate relationship';

    ok !$schema->resultset('PlatePlate')->find(
        {
            parent_plate_id => $old_parent_plate->plate_id,
            child_plate_id  => $plate->plate_id,
        }
    ), '.. deleted old plate plate relationship';


    ok my $old_parent_plate2 = $t->find_or_create_plate('EPD0251_5'), 'grab EPD0251_5 plate';
    ok my $well2             = $plate->wells->find( { well_name => 'C12' } ), '.. can grab qc dna well';
    ok my $new_parent_well2  = $t->_get_epd_well('EPD0034_2_C03', 'EPD0034_2'), 'grab parent epd well';
    ok $t->update_parent_well( $plate, $well2, $new_parent_well2 ), 'update_plate_plate okay';
    ok my $plate_plate2 = $schema->resultset('PlatePlate')->find(
        {
            parent_plate_id => $new_parent_well2->plate->plate_id,
            child_plate_id  => $plate->plate_id,
        }
    ), '.. created new plate plate relationship';

    ok my $plate_plate3 = $schema->resultset('PlatePlate')->find(
        {
            parent_plate_id => $old_parent_plate2->plate_id,
            child_plate_id  => $plate->plate_id,
        }
    ), '.. keep old plate plate relationship';
}
1;

__END__

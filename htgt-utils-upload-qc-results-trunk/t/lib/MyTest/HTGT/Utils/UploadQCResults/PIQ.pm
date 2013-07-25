package MyTest::HTGT::Utils::UploadQCResults::PIQ;

use strict;
use warnings FATAL => 'all';
use FindBin;
use HTGT::Constants qw( %QC_RESULT_TYPES );
use IO::File;

use base qw( HTGT::Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::UploadQCResults::PIQ' );
}

use Test::Most;
use HTGT::Utils::UploadQCResults::PIQ;
use IO::File;

sub constructor : Tests(2) {
    my $test = shift;
    use_ok $test->class;
    isa_ok $test->{o}, $test->class, '..constructor returned correct object';
}

sub after : Test(teardown) {
    my $test = shift;
    $test->{o}->clear_errors;
}

sub before : Test(setup) {
    my $test = shift;

    my $input_file = IO::File->new_tmpfile()
        or die('Could not create temp input file ' . $!);
    
    $input_file->print("well_name,test\n");
    $input_file->print("test,test\n");
    $input_file->print("test,test\n");
    $input_file->seek(0,0);

    $test->{o} = $test->class->new(
        schema => $test->eucomm_vector_schema,
        input  => $input_file,
        user   => 'test_user',
    );

    $test->{ov} = $test->class->new(
        schema   => $test->eucomm_vector_schema,
        input    => $input_file,
        user     => 'test_user',
        override => 1,
    );
}

sub valid_plate_types : Tests(1) {
    my $test = shift;

    is_deeply( $test->{o}->valid_plate_types, [ 'PIQ' ], 'Plate type is PIQ');
}

sub csv_reader : Tests(2) {
    my $test = shift;

    isa_ok $test->{o}->csv_reader, 'CSV::Reader', 'Initialized a CSV::Reader object';
    ok $test->{o}->csv_reader->use_header, 'CSV::Reader use_header attribute set to true';
}

sub _validate_result_value : Tests(4) {
    my $test = shift;

    ok $test->{o}->_validate_result_value('pass'), 'Check validate result value pass is true';
    ok $test->{o}->_validate_result_value('fail'), 'Check validate result value fail is true';
    ok $test->{o}->_validate_result_value('FA'), 'Check validate result value FA is true';
    ok !$test->{o}->_validate_result_value('blah'), 'Check validate result value for blah is false';
}

sub _validate_numeric_value : Tests(6) {
    my $test = shift;

    ok $test->{o}->_validate_numeric_value('0.1'), 'Check validate numeric value 0.1 is true';
    ok $test->{o}->_validate_numeric_value('100'), 'Check validate numeric value 100 is true';
    ok $test->{o}->_validate_numeric_value('0.000001'), 'Check validate numeric value 0.000001 is true';
    ok $test->{o}->_validate_numeric_value('-100'), 'Check validate numeric value -100 is true';
    ok $test->{o}->_validate_numeric_value('0'), 'Check validate numeric value 0 is true';
    ok !$test->{o}->_validate_numeric_value('blah'), 'Check validate numeric value for blah is false';

}

sub _validate_confidence_value : Tests(6) {
    my $test = shift;

    ok $test->{o}->_validate_confidence_value('0.1'), 'Check validate confidence value 0.1 is true';
    ok $test->{o}->_validate_confidence_value('< 1'), 'Check validate confidence value 1 is true';
    ok $test->{o}->_validate_confidence_value('>0.000001'), 'Check validate confidence value 0.000001 is true';
    ok $test->{o}->_validate_confidence_value('> 0.999999'), 'Check validate confidence value 0.999999 is true';
    ok !$test->{o}->_validate_confidence_value('blah'), 'Check validate confidence value for blah is false';
    ok !$test->{o}->_validate_confidence_value('2'), 'Check validate confidence value for 2 is false';
}

sub _validate_chromosome_fail : Tests(10) {
    my $test = shift;

    ok $test->{o}->_validate_chromosome_fail('0'), 'Check validate chromosome fail 0 is true';
    ok $test->{o}->_validate_chromosome_fail('1'), 'Check validate chromosome fail 1 is true';
    ok $test->{o}->_validate_chromosome_fail('2'), 'Check validate chromosome fail 2 is true';
    ok $test->{o}->_validate_chromosome_fail('3'), 'Check validate chromosome fail 3 is true';
    ok $test->{o}->_validate_chromosome_fail('4'), 'Check validate chromosome fail 4 is true';
    ok $test->{o}->_validate_chromosome_fail('y'), 'Check validate chromosome fail Y is true';
    ok !$test->{o}->_validate_chromosome_fail('blah'), 'Check validate chromosome fail for blah is false';
    ok !$test->{o}->_validate_chromosome_fail('5'), 'Check validate chromosome fail for 5 is false';
    ok !$test->{o}->_validate_chromosome_fail('15'), 'Check validate chromosome fail for 15 is false';
    ok !$test->{o}->_validate_chromosome_fail('-1'), 'Check validate chromosome fail -1 is false';
}

sub _get_piq_well : Tests(12) {
    my $test = shift;

    my $t = $test->{o};

    ok !$t->_get_piq_well('blah'), 'return false when invalid well name specified';
    is_deeply( $t->errors, [ 'Invalid EPD well name blah' ], 'error on non invalid epd well name');
    $t->clear_errors;

    ok !$t->_get_piq_well('FP1138_E02'), 'return false when sending in non epd well';
    is_deeply( $t->errors, [ 'Unable to find EPD well FP1138_E02' ], 'error on non epd well name');
    $t->clear_errors;

    ok !$t->_get_piq_well('EPD0694_3_B05'), 'return false when epd well has multiple piq child wells';
    is_deeply( $t->errors, 
        [ 'Multiple PIQ child wells found for EPD0694_3_B05: PIQ_BASH001_A03,PIQ_BASH001_A04,PIQ_BASH001_A05' ],
        'error when epd well has multiple piq child wells');
    $t->clear_errors;

    ok !$t->_get_piq_well('EPD0694_3_B06'), 'returns false when sending in epd well with no piq child wells';
    is_deeply( $t->errors, 
        [ 'Found no PIQ child wells linked to epd well EPD0694_3_B06' ],
        'error when epd well has no PIQ child wells');
    $t->clear_errors;

    ok ( my $piq_well = $t->_get_piq_well('EPD0694_3_A05'), 'valid epd well name returns piq well' );
    isa_ok $piq_well, 'HTGTDB::Well';
    is $piq_well->well_name, 'PIQ_BASH001_A01', '.. and is correct PIQ well';
    is_deeply( $t->errors,[], '... and no errors'); 
    $t->clear_errors;

}

sub parse_csv : Tests(15) {
    my $test = shift;

    $test->{o}->reset_line_number;

    $test->{o}->parse_csv;
    is_deeply( $test->{o}->errors, 
        [ 'No epd_clone_name specified for line: 1', 'No epd_clone_name specified for line: 2' ],
        'parse_csv loops correctly through csv_reader object');
    is $test->{o}->line_number, 2, 'line number is correct';

    #parse test csv
    my $test_file  = "$FindBin::Bin/data/" . 'test_parse_csv.csv';
    my $input_file = IO::File->new( $test_file, O_RDONLY );
    $test->eucomm_vector_schema;
    ok my $t = $test->class->new(
        schema => $test->eucomm_vector_schema,
        input  => $input_file,
        user   => 'test_user',
        ),
        '..create test object';
    isa_ok $t, $test->class, '..constructor returned correct object';

    lives_ok { $t->parse_csv } 'can parse sample csv';
    is_deeply( $t->errors, [], '.has no errors' );

    my $current_well = $t->qc_results->{EPD0588_1_A05};
    diag('EPD0588_1_A05');
    is( $current_well->{loa_pass}, 'fail', ' .loaded correct loa_pass value' );
    ok !exists $current_well->{chr1_cn}, '. not loaded chr1 pass information';
    is( $current_well->{chromosome_fail}, 0, '. chromosome fail value is correct' );
    
    $current_well = $t->qc_results->{EPD0588_1_A06};
    diag('EPD0588_1_A06');
    is( $current_well->{loxp_pass}, 'na', '. loaded correct loxp_pass value' );
    ok !exists $current_well->{chr11a_pass}, '. not loaded any chr11a information';
    is( $current_well->{lacz_pass}, 'fail', '. loaded correct lacz_pass value' );
    
    $current_well = $t->qc_results->{EPD0588_1_A07};
    diag('EPD0588_1_A07');
    is( $current_well->{chry_cn}, 1.13, '. loaded correct chry_cn value' );
    ok !exists $current_well->{chr8a_cn}, '. not loaded any chr8a information';
    ok !exists $current_well->{targeting_pass}, '. not loaded any targeting_pass information';
}

sub _parse_line : Tests(2) {
    my $test = shift;
    my $t = $test->{o};

    # epd_clone_name exists
    $t->_parse_line( { epd_clone_name => undef } );
    is_deeply( $t->errors, [ 'No epd_clone_name specified for line: 1' ], 'error no epd well name');
    $t->clear_errors;

    # ignore qc unit with no pass value
    # if has pass value adds qc to well_qc_results
    # adds overall results if they exist
    $t->_parse_line(
        {
            epd_clone_name => 'EPD0694_3_A05',
            loa_min_cn => 2,
            loa_max_cn => 4,
            loa_confidence => 0.8,
            chr8b_pass => 'pass',
            chr8b_min_cn => 2,
            chr8b_max_cn => 6,
            chromosome_fail => 2,
            loxp_pass => 'na',
            targeting_pass => 'pass'
        }
    );

    is_deeply( $t->qc_results, { EPD0694_3_A05 => {
        chr8b_pass => 'pass',
        chr8b_min_cn => 2,
        chr8b_max_cn => 6,
        chromosome_fail => 2,
        loxp_pass => 'na',
        targeting_pass => 'pass',
    } }, 'parses data hash qc units correctly');

}

sub _parse_field : Tests(7) {
    my $test = shift;
    my $t = $test->{o};

    $t->_parse_field( { epd_clone_name => 'test', loa_pass => 'pass' }, { required => 1  }, 'loxp_pass' );
    is_deeply( $t->errors, [ 'No loxp_pass qc result given for well: test' ], 
        'field does not exist in data hash and is required');
    $t->clear_errors;

    $t->_parse_field( { epd_clone_name => 'test', loa_pass => 'pass' }, { required => 0  }, 'loxp_pass' );
    is_deeply( $t->errors, [  ], 'field does not exist in data hash and is not required');
    $t->clear_errors;

    $t->_parse_field( { epd_clone_name => 'test', loa_pass => 'blah' },
        { validation_method => '_validate_result_value'  }, 'loa_pass' );
    is_deeply( $t->errors, [ 'Invalid loa_pass (blah) for: test' ], 'validation fails');
    $t->clear_errors;
    
    $t->_parse_field( { epd_clone_name => 'test', loa_pass => 'blah' },
        { validation_method => '_validate_result_value'  }, 'loa_pass' );
    is_deeply( $t->errors, [ 'Invalid loa_pass (blah) for: test' ], 'validation fails');
    $t->clear_errors;

    my %data;
    $t->_parse_field( { epd_clone_name => 'test', loa_pass => 'fail' },
        { validation_method => '_validate_result_value'  }, 'loa_pass', \%data );
    is_deeply( \%data , { loa_pass => 'fail' },
        'validation passes, qc result added to well_qc_result hash' );
    is_deeply( $t->errors, [ ], '.. and no errors');
    $t->clear_errors;

    my $o = $test->{ov}; #override set
    $o->_parse_field( { epd_clone_name => 'test', loa_pass => 'pass' }, { required => 1  }, 'loxp_pass' );
    is_deeply( $o->errors, [ ], 'no errors when override set and missing required value');
    $o->clear_errors;
}

sub _update_current_targeting_pass_level : Tests(18) {
    my $test = shift;

    my $schema = $test->eucomm_vector_schema;
    my $t = $test->{o};

    my $well_pass = $schema->resultset('Well')->find( { well_name => 'PIQ_BASH001_A01' } );
    my $well_fail = $schema->resultset('Well')->find( { well_name => 'PIQ_BASH001_A02' } );
    my $well_fa   = $schema->resultset('Well')->find( { well_name => 'PIQ_BASH001_A03' } );
    my $well_na   = $schema->resultset('Well')->find( { well_name => 'PIQ_BASH001_A04' } );
    is( $well_pass->well_data_value('targeting_pass'), 'pass', 'well has targeting_pass pass value' );
    is( $well_fail->well_data_value('targeting_pass'), 'fail', 'well has targeting_pass fail value' );
    is( $well_fa->well_data_value('targeting_pass'),   'fa',   'well has targeting_pass fa value' );
    is( $well_na->well_data_value('targeting_pass'),   'na',   'well has targeting_pass na value' );

    ok !$t->_update_current_targeting_pass_level( $well_pass, 'fail' ),
        'do not update when current value = pass, new value = fail';
    is( $well_pass->well_data_value('targeting_pass'), 'pass', '. targeting_pass value stayed same');
    ok !$t->_update_current_targeting_pass_level( $well_na, 'pass' ),
        'do not update when current value = na, new value = pass';
    is( $well_na->well_data_value('targeting_pass'), 'na', '. targeting_pass value stayed same');
    ok !$t->_update_current_targeting_pass_level( $well_fail, 'fa' ),
        'do not update when current value = fail, new value = fa';
    is( $well_fail->well_data_value('targeting_pass'), 'fail', '. targeting_pass value stayed same');

    ok $t->_update_current_targeting_pass_level( $well_pass, 'na' ),
        'update when current value = pass, new value = na';
    is( $well_pass->well_data_value('targeting_pass'), 'na', '. update successful');
    ok $t->_update_current_targeting_pass_level( $well_fa, 'fail' ),
        'update when current value = fa, new value = fail';
    is( $well_fa->well_data_value('targeting_pass'), 'fail', '. update successful');
    ok $t->_update_current_targeting_pass_level( $well_fail, 'pass' ),
        'update when current value = fail, new value = pass';
    is( $well_fail->well_data_value('targeting_pass'), 'pass', '. update successful');

    my $o = $test->{ov}; #override set
    ok $o->_update_current_targeting_pass_level( $well_pass, 'fail' ),
        'update when current value = pass, new value = fail and override is set';
    is( $well_pass->well_data_value('targeting_pass'), 'fail', '. update successful');
}

sub _process_qc_result_unit : Tests(10) {
    my $test = shift;

    my $schema = $test->eucomm_vector_schema;
    my $t = $test->{o};

    # return false when current value better than new
    my $piq_well = $schema->resultset('Well')->find( { well_name => 'PIQ_BASH001_A02' } );
    is( $piq_well->well_data_value('loxp_pass'), 'fail', 'current loxp_pass value is fail' );
    ok !$t->_process_qc_result_unit( $piq_well, { loxp_pass => 'fa' }, 'loxp' ),
        'do not process qc results when current value is fail and new value is fa';

    # otherwise update or create well data
    my $qc_results = { loxp_pass => 'pass', loxp_cn => 2, loxp_max_cn => 4, loxp_min_cn => 1 };
    is( $piq_well->well_data_value('loxp_cn'), 1, 'current loxp_cn value is 1' );
    ok $t->_process_qc_result_unit( $piq_well, $qc_results, 'loxp' ),
        'update qc results when current value is fail and new value is pass';

    is( $piq_well->well_data_value('loxp_cn'),     2, 'new loxp_cn value is 1' );
    is( $piq_well->well_data_value('loxp_max_cn'), 4, 'created loxp_max_cn value of 4' );
    is( $piq_well->well_data_value('loxp_min_cn'), 1, 'created loxp_min_cn value of 1' );
    is( $piq_well->well_data_value('loxp_pass'), 'pass', 'new loxp_pass value is pass' );

    my $o = $test->{ov}; #override set
    ok $o->_process_qc_result_unit( $piq_well, { loxp_pass => 'fa' }, 'loxp' ),
        'process qc results when current value is pass, new value is fa and override set';
    is( $piq_well->well_data_value('loxp_pass'), 'fa', 'new loxp_pass value is fa' );
}

sub _update_qc_result : Tests(15) {
    my $test = shift;

    my $schema = $test->eucomm_vector_schema;
    my $t = $test->{o};

    my $piq_well_a02 = $schema->resultset('Well')->find( { well_name => 'PIQ_BASH001_A02' } );
    ok !$t->_update_qc_result( $piq_well_a02, { targeting_pass => 'fa' } ),
        'skip updating well when new targeting pass value is worse than old one';

    my $piq_well_a01 = $schema->resultset('Well')->find( { well_name => 'PIQ_BASH001_A01' } );
    is( $piq_well_a01->well_data_value('chromosome_fail'),
        1, '. we have expected chromosome_fail result : 1' );
    ok $t->_update_qc_result( $piq_well_a01, { chromosome_fail => 2 } ),
        'update well qc results';
    is( $piq_well_a01->well_data_value('chromosome_fail'),
        2, '. chromosome_fail result has been updated to 2' );
    ok $t->_update_qc_result( $piq_well_a01, { chromosome_fail => 'Y' } ),
        'update well qc results';
    is( $piq_well_a01->well_data_value('chromosome_fail'),
        'Y', '. chromosome_fail result has been updated to Y' );
    ok $t->_update_qc_result( $piq_well_a01, { chromosome_fail => 0 } ),
        'update well qc results';
    is( $piq_well_a01->well_data_value('chromosome_fail'),
        0, '. chromosome_fail result has been updated to 0' );

    my $piq_well_a05 = $schema->resultset('Well')->find( { well_name => 'PIQ_BASH001_A05' } );
    ok $t->_update_qc_result(
        $piq_well_a05,
        {   lacz_pass       => 'pass',
            lacz_cn         => 2,
            lacz_max_cn     => 5,
            lacz_min_cn     => 2,
            lacz_confidence => '< 0.55',
            chr1_cn         => 4
        },
        'update wells lacz qc values'
    );
    is( $piq_well_a05->well_data_value('lacz_pass'),   'pass', '. lacz_pass value is correct' );
    is( $piq_well_a05->well_data_value('lacz_cn'),     2,      '. lacz_cn value is correct' );
    is( $piq_well_a05->well_data_value('lacz_max_cn'), 5,      '. lacz_max_cn value is correct' );
    is( $piq_well_a05->well_data_value('lacz_min_cn'), 2,      '. lacz_min_cn value is correct' );
    is( $piq_well_a05->well_data_value('lacz_confidence'),
        '< 0.55', '. lacz_confidence value is correct' );
    ok !$piq_well_a05->well_data_value('chr1_cn'), '. chr1_cn value was not updated';
}

sub update_qc_results : Tests(15) {
    my $test = shift;

    my $schema = $test->eucomm_vector_schema;
    my $test_file  = "$FindBin::Bin/data/" . 'update_well_qc_results.csv';
    my $input_file = IO::File->new( $test_file, O_RDONLY );
    $test->eucomm_vector_schema;
    ok my $t = $test->class->new(
        schema => $schema,
        input  => $input_file,
        user   => 'test_user',
        ),
        '..create test object';
    isa_ok $t, $test->class, '..constructor returned correct object';
    ok !$t->update_qc_results(), 'fails if called without parsing csv';

    lives_ok { $t->parse_csv } 'can parse sample csv';
    is_deeply( $t->errors, [], '.has no errors' );
    $t->add_error('test');
    ok !$t->update_qc_results(), 'failed if called when we have errors';
    $t->clear_errors;

    lives_ok { $t->update_qc_results } 'can update well qc results';

    my $piq_well = $schema->resultset('Well')->find( { well_name => 'PIQ_BASH001_A06' } ); 
    is( $piq_well->well_data_value('loxp_pass'), 'na', 'loxp_pass is na' );
    ok !$piq_well->well_data_value('loxp_cn'), 'loxp_cn has not been set';
    ok !$piq_well->well_data_value('loa_pass'), 'loa_pass has not been set';
    ok !$piq_well->well_data_value('loa_cn'), 'loa_cn has not been set';

    is( $piq_well->well_data_value('targeting_pass'), 'pass', 'targeting_pass is pass' );
    is( $piq_well->well_data_value('chromosome_fail'), 2, 'chromosome_fail is 2' );
    is( $piq_well->well_data_value('chr1_pass'), 'pass', 'chr1_pass is pass' );
    is( $piq_well->well_data_value('chr1_confidence'), '> 0.99', 'chr1_confidence is > 0.99' );

}
    
1;

__END__

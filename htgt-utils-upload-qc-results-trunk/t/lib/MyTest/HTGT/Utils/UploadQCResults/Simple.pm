package MyTest::HTGT::Utils::UploadQCResults::Simple;

use strict;
use warnings FATAL => 'all';
use HTGT::Constants qw( %QC_RESULT_TYPES );

use base qw( HTGT::Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::UploadQCResults::Simple' );
}

use Test::Most;
use HTGT::Utils::UploadQCResults::Simple;
use IO::File;

my @TEST_DIE_DATA = (
    {   testname => 'Invalid qc result type',
        input    => 'LOA00039_A02,pass',
        qc_type  => 'test',
        errors   => qr(Unrecognised qc result type: test),
    },
);

my @TEST_FAIL_DATA = (
    {   testname => 'Non CSV style input',
        input    => 'LOA00039_A02:pass',
        qc_type  => 'LOA',
        errors   => ['No qc result given for LOA00039_A02:pass'],
    },
    
    {   testname => 'Missing QC Result',
        input    => 'LOA00039_A02',
        qc_type  => 'LOA',
        errors   => ['No qc result given for LOA00039_A02'],
    },

    {   testname => 'Invalid well name',
        input    => 'LOA9999999,pass',
        qc_type  => 'LOA',
        errors   => ['well: LOA9999999 does not exist'],
    },

    {   testname => 'Non REPD well',
        input    => 'DFP0148_D06,pass',
        qc_type  => 'LOA',
        errors   => ['well: DFP0148_D06 does not belong to plate type: REPD'],
    },

    {   testname => 'Invalid qc result',
        input    => 'LOA00039_A03,test',
        qc_type  => 'LOA',
        errors   => ['Invalid QC result (test) for LOA00039_A03'],
    },

);

my @TEST_PASS_DATA = (
    {   testname   => 'Valid input - pass - LOA',
        input      => 'LOA00039_A03,pass',
        result     => 'pass',
        qc_type    => 'LOA',
        update_log => ['Created loa_qc_result for LOA00039_A03: pass'],
        skip_header => 0,
    },

    {   testname   => 'Valid input - fail - LOA',
        input      => 'LOA00039_B03,fail',
        result     => 'fail',
        qc_type    => 'LOA',
        update_log => ['Created loa_qc_result for LOA00039_B03: fail'],
        skip_header => 0,
    },

    {   testname   => 'Valid input - FA - LOA',
        input      => 'LOA00039_B04,FA',
        result     => 'FA',
        qc_type    => 'LOA',
        update_log => ['Created loa_qc_result for LOA00039_B04: FA'],
        skip_header => 0,
    },

    {   testname   => 'Valid input - fail - LoxP_Taqman',
        input      => 'LOA00039_A04,fail',
        result     => 'fail',
        qc_type    => 'LoxP_Taqman',
        update_log => ['Created taqman_loxp_qc_result for LOA00039_A04: fail'],
        skip_header => 0,
    },

    {   testname   => 'Valid input - FA - LoxP_Taqman',
        input      => 'LOA00039_A05,FA',
        result     => 'FA',
        qc_type    => 'LoxP_Taqman',
        update_log => ['Created taqman_loxp_qc_result for LOA00039_A05: FA'],
        skip_header => 0,
    },

    {   testname   => 'Valid input - pass - LoxP_Taqman',
        input      => 'LOA00039_B03,pass',
        result     => 'pass',
        qc_type    => 'LoxP_Taqman',
        update_log => ['Created taqman_loxp_qc_result for LOA00039_B03: pass'],
        skip_header => 0,
    },
    
    {   testname   => 'Valid input - pass - LoxP_Taqman - Skip Header',
        input      => "LOA00039_B04,pass",
        result     => 'pass',
        qc_type    => 'LoxP_Taqman',
        update_log => ['Created taqman_loxp_qc_result for LOA00039_B04: pass'],
        skip_header => 1,
    },
    
    {   testname    => 'Well already has loa result (pass) - we have FA, no update',
        input       => 'LOA00039_A02,FA',
        result      => 'pass',
        qc_type     => 'LOA',
        update_log  => ['LOA00039_A02 already has a better loa_qc_result (pass) - NOT updating to FA'],
        skip_header => 0,
    },
    
    {   testname    => 'Well already has same loa result (pass) - no update',
        input       => 'LOA00039_A02,pass',
        result      => 'pass',
        qc_type     => 'LOA',
        update_log  => ['LOA00039_A02 already has the same loa_qc_result (pass) - NOT updating'],
        skip_header => 0,
    },
    
    {   testname    => 'Well already has loa result (FA) - we have pass, so we update it',
        input       => 'LOA00039_H05,pass',
        result      => 'pass',
        qc_type     => 'LOA',
        update_log  => ['Updating loa_qc_result for LOA00039_H05 from FA to pass'],
        skip_header => 0,
    },
    
    {   testname    => 'Well already has loa result (fail) - we have FA, no update',
        input       => 'LOA00039_H04,FA',
        result      => 'fail',
        qc_type     => 'LOA',
        update_log  => ['LOA00039_H04 already has a better loa_qc_result (fail) - NOT updating to FA'],
        skip_header => 0,
    },
    
    {   testname    => 'Well already has loa result (fail) - we have pass, so we update it',
        input       => 'LOA00039_H04,pass',
        result      => 'pass',
        qc_type     => 'LOA',
        update_log  => ['Updating loa_qc_result for LOA00039_H04 from fail to pass'],
        skip_header => 0,
    },

    {   testname    => 'Well already has same loa result (pass) - no update',
        input       => 'LOA00039_A02,pass',
        result      => 'pass',
        qc_type     => 'LOA',
        update_log  => ['LOA00039_A02 already has the same loa_qc_result (pass) - NOT updating'],
        skip_header => 0,
        override    => 1,
    },

    {   testname    => 'Well already has loa result (pass) - we have FA, override set, update',
        input       => 'LOA00039_A02,FA',
        result      => 'FA',
        qc_type     => 'LOA',
        update_log  => ['Updating loa_qc_result for LOA00039_A02 from pass to FA'],
        skip_header => 0,
        override    => 1,
    },

);

#project 25723

sub die_tests : Tests {
    my $test = shift;

    for my $t (@TEST_DIE_DATA) {
        note( 'TEST: ' . $t->{testname} );
        
        my $input_file = IO::File->new_tmpfile()
            or die('Could not create temp input file ' . $!);
        
        $input_file->print($t->{input});
        $input_file->seek(0,0);
        
        throws_ok {
            my $loa_qc_updater = HTGT::Utils::UploadQCResults::Simple->new(
                schema         => $test->eucomm_vector_schema,
                input          => $input_file,
                user           => 'LOAQCResults Test',
                qc_result_type => $t->{qc_type},
                )
        } $t->{errors} ,$t->{testname} . ' die on object creation';
    }
}

sub fail_tests : Tests {
    my $test = shift;

    for my $t (@TEST_FAIL_DATA) {
        note( 'TEST: ' . $t->{testname} );
        
        my $input_file = IO::File->new_tmpfile()
            or die('Could not create temp input file ' . $!);
        
        $input_file->print($t->{input});
        $input_file->seek(0,0);
        
        ok my $loa_qc_updater = HTGT::Utils::UploadQCResults::Simple->new(
            schema         => $test->eucomm_vector_schema,
            input          => $input_file,
            user           => 'LOAQCResults Test',
            qc_result_type => $t->{qc_type},
            ),
            $t->{testname} . ' object creation';

        isa_ok $loa_qc_updater, 'HTGT::Utils::UploadQCResults::Simple', $t->{testname};
        $loa_qc_updater->parse_csv;
        $loa_qc_updater->update_qc_results;


        is $loa_qc_updater->has_errors,  1, $t->{testname} . ' has errors';
        is $loa_qc_updater->has_updates, 0, $t->{testname} . ' has no updates';

        is_deeply $loa_qc_updater->errors, $t->{errors}, $t->{testname} . ' has expected errors';
    }
}

sub pass_tests : Tests {
    my $test = shift;

    for my $t (@TEST_PASS_DATA) {
        note( 'TEST: ' . $t->{testname} );
        
        my $input_file = IO::File->new_tmpfile()
            or die('Could not create temp input file ' . $!);
        
        if ( $t->{skip_header} ) {
            $input_file->print("Well,Pass\n");
        }
        $input_file->print($t->{input});
        $input_file->seek(0,0);

        ok my $loa_qc_updater = HTGT::Utils::UploadQCResults::Simple->new(
            schema         => $test->eucomm_vector_schema,
            input          => $input_file,
            user           => 'LOAQCResults Test',
            qc_result_type => $t->{qc_type},
            skip_header    => $t->{skip_header},
            override       => $t->{override} ? 1 : 0
            ),
            $t->{testname} . ' object created';

        my ( $well_name, $qc_result ) = split qr/,/, $t->{input};
 
        isa_ok $loa_qc_updater, 'HTGT::Utils::UploadQCResults::Simple', $t->{testname};
        $loa_qc_updater->parse_csv;
        $loa_qc_updater->update_qc_results;
        is $loa_qc_updater->has_errors, 0, $t->{testname} . ' has no errors';

        is_deeply $loa_qc_updater->update_log, $t->{update_log},
            $t->{testname} . ' has correct output';

        ok my $well
            = $test->eucomm_vector_schema->resultset('Well')->find( { well_name => $well_name, } ),
            $t->{testname} . ' found well row';

        ok my $data_type = $QC_RESULT_TYPES{$t->{qc_type}}{well_data_type}, $t->{testname} 
            . ' grabbed data type ';

        ok my $well_data = $well->well_data->find( { data_type => $data_type } ),
            $t->{testname} . ' found well data row';

        is $well_data->data_value, $t->{result}, $t->{testname} . ' and well data value is correct';
    }
}

sub qc_results : Tests {
    my $test = shift;

    my %test_data = (
        EPD0001_A01 => 'pass',
        EPD0001_A02 => 'fail',
        EPD0001_A02 => 'FA'
    );    

    my %expected_qc_results_data = (
        EPD0001_A01 => { loa_qc_result => 'pass' },
        EPD0001_A02 => { loa_qc_result => 'fail' },
        EPD0001_A02 => { loa_qc_result => 'FA' },
    );

    for my $line_ending ( "\r", "\n", "\r\n" ) {
        my $input_file = IO::File->new_tmpfile()
            or die "Could not create temporary file for input: $!";

        $input_file->print( "Well name, QC Result\r" );
    
        while ( my ( $well, $qc_result ) = each %test_data ) {
            $input_file->print( "$well,$qc_result$line_ending" );        
        }

        $input_file->seek(0,0);

        ok my $loa_qc_updater = HTGT::Utils::UploadQCResults::Simple->new(
            schema         => $test->eucomm_vector_schema,
            input          => $input_file,
            user           => 'LOAQCResults Test',
            qc_result_type => 'LOA',
            skip_header    => 1
        ), 'Create UploadQCResults object with CR-delimited data';
        $loa_qc_updater->parse_csv;
        $loa_qc_updater->update_qc_results;
        
        can_ok $loa_qc_updater, 'qc_results';
        
        ok my $qc_results = $loa_qc_updater->qc_results, 'qc_results should succeed';
        
        is_deeply $qc_results, \%expected_qc_results_data, 'qc_results returns expected data structure';
    }    
}
    
1;

__END__

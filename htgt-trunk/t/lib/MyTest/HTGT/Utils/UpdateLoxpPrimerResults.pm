package MyTest::HTGT::Utils::UpdateLoxpPrimerResults;

use strict; 
use warnings FATAL => 'all';
use Const::Fast;

use base qw( HTGT::Test::Class Class::Data::Inheritable );
const my $PRIMER_RESULT_PREFIX => 'SRLOXP-';

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::UpdateLoxpPrimerResults' );
}

use Test::Most;
use HTGT::Utils::UpdateLoxpPrimerResults;

my @TEST_FAIL_DATA = (
    {   testname        => 'invalid epd well',
        epd_well_primer => 'EPD99999999-LR1',
        result          => 'pass',
        errors          => qr/Well does not exist: EPD99999999/,
    },
    {   testname        => 'valid well but non epd',
        epd_well_primer => 'HFP0527_8_C09-LR1',
        result          => 'pass',
        errors          => qr/Well \(HFP0527_8_C09\) does not belong to a EPD plate/,
    },
    {   testname        => 'invalid primer name',
        epd_well_primer => 'HEPD0527_8_H09-TEST',
        result          => 'pass',
        errors          => qr/Invalid primer name: TEST/,
    },
    {   testname        => 'invalid result',
        epd_well_primer => 'HEPD0527_8_H09-LR1',
        result          => 'true',
        errors          => qr/Result for LR1 is invalid: true/,
    },
);

my @TEST_PASS_DATA = (
    {   testname        => 'current and new results same',
        epd_well_primer => 'HEPD0527_8_H09-LR1',
        result          => 'not_used',
    },
    {   testname        => 'modify current result',
        epd_well_primer => 'HEPD0527_8_H09-LR2',
        result          => 'fail',
        update          => qr/\(HEPD0527_8_H09\) Updated primer result for LR2 to fail/,
    },
    {   testname        => 'delete current result',
        epd_well_primer => 'HEPD0527_8_H09-LR3',
        result          => 'not_used',
        update          => qr/\(HEPD0527_8_H09\) Set primer result to not used for LR3/,
    },
    {   testname        => 'add new result',
        epd_well_primer => 'HEPD0527_8_H09-PNFLR1',
        result          => 'pass',
        update          => qr/\(HEPD0527_8_H09\) Created primer result for PNFLR1 to pass/,
    },    
);


sub fail_tests :Tests {
    my $test = shift;
 
    for my $t (@TEST_FAIL_DATA) {
        throws_ok { my $update_primers = HTGT::Utils::UpdateLoxpPrimerResults->new(
            schema          => $test->eucomm_vector_schema,
            epd_well_primer => $t->{epd_well_primer},
            result          => $t->{result},
            user            => 'test')
        } $t->{errors} ,$t->{testname};
    }
}

sub pass_tests :Tests {
    my $test = shift;
    
    for my $t (@TEST_PASS_DATA) {
        ok my $update_primers = HTGT::Utils::UpdateLoxpPrimerResults->new(
            schema          => $test->eucomm_vector_schema,
            epd_well_primer => $t->{epd_well_primer},
            result          => $t->{result},
            user            => 'test'),
        $t->{testname} . ' object created';
        
        ok $update_primers->update, $t->{testname} . ' update called';
        
        ok $test->check_update_value($t), $t->{testname} . ' update completed successfully';
        
        if ( $t->{update} ) {
            like $update_primers->update_log, $t->{update}, $t->{testname} . ' correct log message';
        }
    }    
}

sub check_update_value {
    my ($test, $t) = @_;
    
    my ($epd_well_name, $primer_name) = split /-/, $t->{epd_well_primer};
    
    my $epd_well = $test->eucomm_vector_schema->resultset('Well')->find({ well_name => $epd_well_name });
    return unless $epd_well;
    
    my $epd_well_data = $epd_well->well_data->find({ 'data_type' => $PRIMER_RESULT_PREFIX . $primer_name });

    if ( $t->{result} eq 'not_used' ) {
        return 1 unless $epd_well_data;
    }
    return unless $epd_well_data;
    
    return 1 if $epd_well_data->data_value eq $t->{result};
    
    return;
}

1;

__END__

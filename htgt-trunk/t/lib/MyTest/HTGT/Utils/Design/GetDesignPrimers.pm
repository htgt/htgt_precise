package MyTest::HTGT::Utils::Design::GetDesignPrimers;

use strict; 
use warnings FATAL => 'all';

use base qw( HTGT::Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::Design::GetDesignPrimers' );
}

use Test::Most;
use HTGT::Utils::Design::GetDesignPrimers;

my @TEST_FAIL_DATA = (
    {   testname    => 'empty data',
        input       => '',
        errors      => ['No Data Entered'],
        has_designs => 0,
    },

    {   testname    => 'Invalid epd well name',
        input       => 'EPD999999999999',
        errors      => ['EPD well does not exist: EPD999999999999'],
        has_designs => 0
    },

    {   testname    => 'Non Existant marker symbol',
        input       => 'test',
        errors      => ['Marker Symbol / EPD well does not exist: test'],
        has_designs => 0
    },

    {   testname    => 'Gene marker symbol with no projects',
        input       => 'D19Mit32',
        errors      => ['Marker Symbol does not have any valid projects: D19Mit32'],
        has_designs => 0
    },
    
    {   testname    => 'duplicate epd wells',
        input       => 'HEPD0527_8_H09, HEPD0527_8_H09',
        errors      => ['Duplicate epd well entered: HEPD0527_8_H09'],
        has_designs => 1,
    },
    
    {   testname    => 'duplicate marker symbol wells',
        input       => 'Ncaph, Ncaph',
        errors      => ['Duplicate gene marker symbol entered: Ncaph'],
        has_designs => 1,
    }, 
);

my @TEST_PASS_DATA = (
    {   testname    => 'Valid Input Data - Gm12824 - no primers',
        input       => 'Gm12824',
        data_return => {
            columns => [ 'design_id', 'marker_symbol', 'primer_name', 'sequence' ],
            primers => [
                {   design_id     => '99198',
                    marker_symbol => 'Gm12824',
                    primer_name   => 'No primers found',
                    sequence      => 'N/A',
                }
            ]
        }
    },
    {   testname    => 'Valid Input Data - epd well name - ',
        input       => 'HEPD0527_8_H09',
        data_return => {
            columns => [ 'design_id', 'marker_symbol', 'primer_name', 'sequence' ],
            primers => [
                {   design_id     => '41258',
                    marker_symbol => 'Adam15',
                    primer_name   => 'LF1',
                    epd_well_name => 'HEPD0527_8_H09',
                    sequence      => 'TCCTCGGTAGCAGCAGTTTT',
                },
                {   design_id     => '41258',
                    marker_symbol => 'Adam15',
                    primer_name   => 'LF2',
                    epd_well_name => 'HEPD0527_8_H09',
                    sequence      => 'GGATCCGAGAAATGACAGGA',
                    result        => 'pass',
                },
                {   design_id     => '41258',
                    marker_symbol => 'Adam15',
                    primer_name   => 'LF3',
                    epd_well_name => 'HEPD0527_8_H09',
                    sequence      => 'GGCAGTGTTCACACCATGTC',
                    result        => 'fail',
                },
                {   design_id     => '41258',
                    marker_symbol => 'Adam15',
                    primer_name   => 'LR1',
                    epd_well_name => 'HEPD0527_8_H09',
                    sequence      => 'GGAAAGAGACTGGGACACCA'
                },
                {   design_id     => '41258',
                    marker_symbol => 'Adam15',
                    primer_name   => 'LR2',
                    epd_well_name => 'HEPD0527_8_H09',
                    sequence      => 'TTGGGGACTTATGGGTGAAA',
                    result        => 'pass',
                },
                {   design_id     => '41258',
                    marker_symbol => 'Adam15',
                    primer_name   => 'LR3',
                    epd_well_name => 'HEPD0527_8_H09',
                    sequence      => 'GAAAGGAAGAGGAGGATGGG',
                    result        => 'fail',
                },
                {   design_id     => '41258',
                    marker_symbol => 'Adam15',
                    primer_name   => 'PNFLR1',
                    epd_well_name => 'HEPD0527_8_H09',
                    sequence      => 'GTGAGTGGAAAGGAGGAGGC'
                },
                {   design_id     => '41258',
                    marker_symbol => 'Adam15',
                    primer_name   => 'PNFLR2',
                    epd_well_name => 'HEPD0527_8_H09',
                    sequence      => 'CAGTGTGAGTGGAAAGGAGGA',
                    result        => 'pass',
                },
            ]
        }
    },
    {   testname    => 'Valid Input Data - Ncaph - ',
        input       => 'Ncaph',
        data_return => {
            columns => [ 'design_id', 'marker_symbol', 'primer_name', 'sequence' ],
            primers => [
                {   design_id     => '48020',
                    marker_symbol => 'Ncaph',
                    primer_name   => 'LF1',
                    sequence      => 'ATGAATGTGAGGCGGAAAAG'
                },
                {   design_id     => '48020',
                    marker_symbol => 'Ncaph',
                    primer_name   => 'LF2',
                    sequence      => 'TCCAAATCCATCCAGCTTTC'
                },
                {   design_id     => '48020',
                    marker_symbol => 'Ncaph',
                    primer_name   => 'LF3',
                    sequence      => 'CGTTCAGTGTTCAGAGGCAA'
                },
                {   design_id     => '48020',
                    marker_symbol => 'Ncaph',
                    primer_name   => 'LR1',
                    sequence      => 'CTTTCGGCTTGCATTTGATT'
                },
                {   design_id     => '48020',
                    marker_symbol => 'Ncaph',
                    primer_name   => 'LR2',
                    sequence      => 'TAACAAATCTCTGACCGCCC'
                },
                {   design_id     => '48020',
                    marker_symbol => 'Ncaph',
                    primer_name   => 'LR3',
                    sequence      => 'GGCTTACAGGCAAATGGTGT'
                },
                {   design_id     => '48020',
                    marker_symbol => 'Ncaph',
                    primer_name   => 'PNFLR1',
                    sequence      => 'AGTAAACCACCCATCCCAAGA'
                },
                {   design_id     => '48020',
                    marker_symbol => 'Ncaph',
                    primer_name   => 'PNFLR2',
                    sequence      => 'GTAAACCACCCATCCCAAGAG'
                },
                {   design_id     => '48020',
                    marker_symbol => 'Ncaph',
                    primer_name   => 'PNFLR3',
                    sequence      => 'AACCACCCATCCCAAGAGAC'
                }
            ]
        }
    },
);

sub fail_tests :Tests {
    my $test = shift;
    
    for my $t (@TEST_FAIL_DATA) {
        ok my $design_primers = HTGT::Utils::Design::GetDesignPrimers->new(
            schema     => $test->eucomm_vector_schema,
            input_data => $t->{input}
        ), $t->{testname} . ' object creation';
        
        isa_ok $design_primers, 'HTGT::Utils::Design::GetDesignPrimers', $t->{testname};
        
        is $design_primers->has_designs, $t->{has_designs}, $t->{testname} . ' has no designs';
        is $design_primers->has_errors, 1, $t->{testname} . ' has errors';
        
        is_deeply $design_primers->errors, $t->{errors}, $t->{testname} . ' has expected errors';
    }
}

sub pass_tests :Tests {
    my $test = shift;

    for my $t (@TEST_PASS_DATA) {
        ok my $design_primers = HTGT::Utils::Design::GetDesignPrimers->new(
            schema     => $test->eucomm_vector_schema,
            input_data => $t->{input}
        ), $t->{testname} . ' object created';
        
        isa_ok $design_primers, 'HTGT::Utils::Design::GetDesignPrimers', $t->{testname};
        
        is $design_primers->has_designs, 1, $t->{testname} . ' has designs';
        is $design_primers->has_errors,  0, $t->{testname} . ' has no errors';    
        
        is_deeply $design_primers->create_report, $t->{data_return}, $t->{testname} . ' has correct output';
    }
}

1;

__END__
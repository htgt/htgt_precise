package MyTest::HTGT::Utils::DesignQcReports::DnaWells;

use strict;
use warnings FATAL => 'all';

use base qw( MyTest::HTGT::Utils::DesignQcReports Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::DesignQcReports::DnaWells' );
}

use Test::Most;
use HTGT::Utils::DesignQcReports::DnaWells;

sub startup : Tests(startup => 2) {
    my $test = shift;
    use_ok $test->class;
    
    my $schema = $test->eucomm_vector_schema;
    
    ok $test->{o} = $test->class->new(
        schema     => $schema,
        input_data => '41044',
        plate_type => 'SBDNA',
    ), '..create test object';
}

sub get_data_for_design : Tests() {
    my $test = shift;

    ok my $design = $test->eucomm_vector_schema->resultset('Design')->find({ design_id => '258111' }), '.. get design';


    ok my $data = $test->{o}->get_data_for_design($design), '.. can qc dna data for design';
    is_deeply $data, [ 
        { 
            design_id     => 258111,
            marker_symbol => '-',
            plate         => 'SBDNA00001',
            well          => 'SBDNA00001_A01',
        } 
    ], '.. has correct qc dna well data';


    ok my $design_no_assay = $test->eucomm_vector_schema->resultset('Design')->find({ design_id => '41044' }), '.. get design';
    ok my $no_assay_data = $test->{o}->get_data_for_design($design_no_assay), '.. can get taqman data';
    is_deeply $no_assay_data, [ { design_id => 41044, marker_symbol => 'Ctcfl' } ], '.. has correct data';
}

1;

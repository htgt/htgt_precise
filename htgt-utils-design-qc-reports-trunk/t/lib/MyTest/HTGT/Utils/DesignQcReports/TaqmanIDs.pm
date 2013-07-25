package MyTest::HTGT::Utils::DesignQcReports::TaqmanIDs;

use strict;
use warnings FATAL => 'all';

use base qw( MyTest::HTGT::Utils::DesignQcReports Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::DesignQcReports::TaqmanIDs' );
}

use Test::Most;
use HTGT::Utils::DesignQcReports::TaqmanIDs;

sub get_data_for_design : Tests(6) {
    my $test = shift;

    ok my $design = $test->eucomm_vector_schema->resultset('Design')->find({ design_id => '258111' }), '.. get design';
    ok my $data = $test->{o}->get_data_for_design($design), '.. can get taqman data for design';
    is_deeply $data, [ 
        { 
            design_id          => 258111,
            marker_symbol      => '-',
            assay_id           => '17_K19_U_CC6RM30',
            forward_primer_seq => 'TGACTTTCGATTCCACGTGCAT',
            reporter_probe_seq => 'ACCACACATAAATACATATCAAAAATT',
            reverse_primer_seq => 'ACATGGGAACAGGCATACAAACAT',
            deleted_region     => 'u',
            plate              => 'QPCRDR0002',
            well               => 'QPCRDR0002_A01',
        } 
    ], '.. has correct taqman data';

    ok my $design_no_assay = $test->eucomm_vector_schema->resultset('Design')->find({ design_id => '41044' }), '.. get design';
    ok my $no_assay_data = $test->{o}->get_data_for_design($design_no_assay), '.. can get taqman data';
    is_deeply $no_assay_data, [ { design_id => 41044, marker_symbol => 'Ctcfl' } ], '.. has correct data';
}

1;

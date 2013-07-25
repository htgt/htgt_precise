#!/usr/bin/env perl

use 5.008;
use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Test::Most;
use HTGT::DBFactory;

use_ok 'HTGT::Utils::Report::QCResultsAndPrimers', ':all';
can_ok 'HTGT::Utils::Report::QCResultsAndPrimers', qw(retrieve_data_for);

TODO: {
    local $TODO = 'should add tests for the optimize option';

    my $model  = HTGT::DBFactory->connect("vector_qc");
    my $run_id = 12155;
    my $clone  = retrieve_data_for( $model, $run_id, { order => 'clone' } );
    my $synvec = retrieve_data_for( $model, $run_id );

    ok scalar( map { @{ $_->{qc_results} } } @{$synvec} ) ==
      scalar( @{$clone} ), 'ConstructClone count == QctestResult count';
}

done_testing();

exit 0;

__END__

=for DATA BY SYNVEC (first):

$VAR1 = {
    'available_primers' => [ 'PGO', 'R3', 'LR', 'R3w', 'L1', 'PNF' ],
    'qc_results'        => [
        {
            'pass_status' => 'pass4.1',
            'primers'     => [
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PGO',
                    'primer_status' => 'valid',
                    'read_length'   => 792,
                    'align_length'  => '795'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'R3',
                    'primer_status' => 'valid',
                    'read_length'   => 723,
                    'align_length'  => '725'
                },
                {
                    'primer_name'   => 'R3w',
                    'primer_status' => 'no_hits',
                    'read_length'   => 0
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'LR',
                    'primer_status' => 'valid',
                    'read_length'   => 717,
                    'align_length'  => '717'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PNF',
                    'primer_status' => 'valid',
                    'read_length'   => 678,
                    'align_length'  => '678'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'L1',
                    'primer_status' => 'valid',
                    'read_length'   => 619,
                    'align_length'  => '620'
                }
            ],
            'qctest_result_id' => '1615687',
            'construct_clone'  => 'PG00174_Z_G12_1',
            'best_for_design'  => '1',
            'clone_well'       => 'G12',
            'clone_plate'      => 'PG00174_Z'
        },
        {
            'pass_status' => 'pass4.1',
            'primers'     => [
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PGO',
                    'primer_status' => 'valid',
                    'read_length'   => 795,
                    'align_length'  => '799'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PNF',
                    'primer_status' => 'valid',
                    'read_length'   => 684,
                    'align_length'  => '686'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'R3',
                    'primer_status' => 'valid',
                    'read_length'   => 707,
                    'align_length'  => '708'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'LR',
                    'primer_status' => 'valid',
                    'read_length'   => 670,
                    'align_length'  => '670'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'L1',
                    'primer_status' => 'valid',
                    'read_length'   => 662,
                    'align_length'  => '663'
                }
            ],
            'qctest_result_id' => '1615688',
            'construct_clone'  => 'PG00174_Z_G12_5',
            'best_for_design'  => '0',
            'clone_well'       => 'G12',
            'clone_plate'      => 'PG00174_Z'
        },
        {
            'pass_status' => 'pass4.1',
            'primers'     => [
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PGO',
                    'primer_status' => 'valid',
                    'read_length'   => 653,
                    'align_length'  => '656'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'R3',
                    'primer_status' => 'valid',
                    'read_length'   => 351,
                    'align_length'  => '369'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PNF',
                    'primer_status' => 'valid',
                    'read_length'   => 658,
                    'align_length'  => '659'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'L1',
                    'primer_status' => 'valid',
                    'read_length'   => 686,
                    'align_length'  => '687'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'LR',
                    'primer_status' => 'valid',
                    'read_length'   => 776,
                    'align_length'  => '776'
                }
            ],
            'qctest_result_id' => '1615689',
            'construct_clone'  => 'PG00174_Z_G12_3',
            'best_for_design'  => '0',
            'clone_well'       => 'G12',
            'clone_plate'      => 'PG00174_Z'
        },
        {
            'pass_status' => 'pass4.1',
            'primers'     => [
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PGO',
                    'primer_status' => 'valid',
                    'read_length'   => 593,
                    'align_length'  => '594'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'L1',
                    'primer_status' => 'valid',
                    'read_length'   => 625,
                    'align_length'  => '626'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'R3',
                    'primer_status' => 'valid',
                    'read_length'   => 503,
                    'align_length'  => '503'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'LR',
                    'primer_status' => 'valid',
                    'read_length'   => 607,
                    'align_length'  => '607'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PNF',
                    'primer_status' => 'valid',
                    'read_length'   => 682,
                    'align_length'  => '684'
                }
            ],
            'qctest_result_id' => '1615690',
            'construct_clone'  => 'PG00174_Z_G12_4',
            'best_for_design'  => '0',
            'clone_well'       => 'G12',
            'clone_plate'      => 'PG00174_Z'
        },
        {
            'pass_status' => 'pass4.1',
            'primers'     => [
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PGO',
                    'primer_status' => 'valid',
                    'read_length'   => 644,
                    'align_length'  => '647'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'R3',
                    'primer_status' => 'valid',
                    'read_length'   => 686,
                    'align_length'  => '686'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'LR',
                    'primer_status' => 'valid',
                    'read_length'   => 671,
                    'align_length'  => '671'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'L1',
                    'primer_status' => 'valid',
                    'read_length'   => 623,
                    'align_length'  => '623'
                },
                {
                    'primer_name'   => 'PNF',
                    'primer_status' => 'no_hits',
                    'read_length'   => 0
                }
            ],
            'qctest_result_id' => '1615691',
            'construct_clone'  => 'PG00174_Z_G12_2',
            'best_for_design'  => '0',
            'clone_well'       => 'G12',
            'clone_plate'      => 'PG00174_Z'
        },
        {
            'pass_status' => 'pass4.1',
            'primers'     => [
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PGO',
                    'primer_status' => 'valid',
                    'read_length'   => 701,
                    'align_length'  => '704'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'R3',
                    'primer_status' => 'valid',
                    'read_length'   => 624,
                    'align_length'  => '627'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'LR',
                    'primer_status' => 'valid',
                    'read_length'   => 586,
                    'align_length'  => '586'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'L1',
                    'primer_status' => 'valid',
                    'read_length'   => 714,
                    'align_length'  => '715'
                },
                {
                    'primer_name'   => 'PNF',
                    'primer_status' => 'no_hits',
                    'read_length'   => 0
                }
            ],
            'qctest_result_id' => '1615692',
            'construct_clone'  => 'PG00174_Z_G12_7',
            'best_for_design'  => '0',
            'clone_well'       => 'G12',
            'clone_plate'      => 'PG00174_Z'
        },
        {
            'pass_status' => 'warn_3arm_',
            'primers'     => [
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PGO',
                    'primer_status' => 'valid',
                    'read_length'   => 589,
                    'align_length'  => '592'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PNF',
                    'primer_status' => 'valid',
                    'read_length'   => 493,
                    'align_length'  => '493'
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'L1',
                    'primer_status' => 'valid',
                    'read_length'   => 628,
                    'align_length'  => '629'
                },
                {
                    'primer_name'   => 'LR',
                    'primer_status' => 'no_hits',
                    'read_length'   => 0
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'R3',
                    'primer_status' => 'valid',
                    'read_length'   => 532,
                    'align_length'  => '532'
                }
            ],
            'qctest_result_id' => '1615693',
            'construct_clone'  => 'PG00174_Z_G12_8',
            'best_for_design'  => '0',
            'clone_well'       => 'G12',
            'clone_plate'      => 'PG00174_Z'
        },
        {
            'pass_status' => 'fail',
            'primers'     => [
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PGO',
                    'primer_status' => 'valid',
                    'read_length'   => 592,
                    'align_length'  => '595'
                },
                {
                    'primer_name'   => 'PNF',
                    'primer_status' => 'no_hits',
                    'read_length'   => 0
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'R3',
                    'primer_status' => 'valid',
                    'read_length'   => 767,
                    'align_length'  => '770'
                },
                {
                    'primer_name'   => 'LR',
                    'primer_status' => 'no_hits',
                    'read_length'   => 0
                },
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'L1',
                    'primer_status' => 'valid',
                    'read_length'   => 700,
                    'align_length'  => '702'
                }
            ],
            'qctest_result_id' => '1615694',
            'construct_clone'  => 'PG00174_Z_G12_6',
            'best_for_design'  => '0',
            'clone_well'       => 'G12',
            'clone_plate'      => 'PG00174_Z'
        },
        {
            'pass_status' => 'fail',
            'primers'     => [
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PGO',
                    'primer_status' => 'valid',
                    'read_length'   => 599,
                    'align_length'  => '441'
                },
                {
                    'primer_name'   => 'R3',
                    'primer_status' => 'no_hits',
                    'read_length'   => 667
                },
                {
                    'primer_name'   => 'LR',
                    'primer_status' => 'no_hits',
                    'read_length'   => 817
                },
                {
                    'primer_name'   => 'L1',
                    'primer_status' => 'no_hits',
                    'read_length'   => 465
                },
                {
                    'primer_name'   => 'PNF',
                    'primer_status' => 'no_hits',
                    'read_length'   => 312
                }
            ],
            'qctest_result_id' => '1615695',
            'construct_clone'  => 'PG00174_Z_D10_7',
            'best_for_design'  => '0',
            'clone_well'       => 'D10',
            'clone_plate'      => 'PG00174_Z'
        },
        {
            'pass_status' => 'fail',
            'primers'     => [
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PGO',
                    'primer_status' => 'valid',
                    'read_length'   => 487,
                    'align_length'  => '441'
                },
                {
                    'primer_name'   => 'R3',
                    'primer_status' => 'no_hits',
                    'read_length'   => 381
                },
                {
                    'primer_name'   => 'LR',
                    'primer_status' => 'no_hits',
                    'read_length'   => 757
                },
                {
                    'primer_name'   => 'R3w',
                    'primer_status' => 'no_hits',
                    'read_length'   => 556
                },
                {
                    'primer_name'   => 'PNF',
                    'primer_status' => 'no_hits',
                    'read_length'   => 684
                },
                {
                    'primer_name'   => 'L1',
                    'primer_status' => 'no_hits',
                    'read_length'   => 774
                }
            ],
            'qctest_result_id' => '1615696',
            'construct_clone'  => 'PG00174_Z_F04_1',
            'best_for_design'  => '0',
            'clone_well'       => 'F04',
            'clone_plate'      => 'PG00174_Z'
        },
        {
            'pass_status' => 'fail',
            'primers'     => [
                {
                    'loc_status'    => 'ok',
                    'primer_name'   => 'PGO',
                    'primer_status' => 'valid',
                    'read_length'   => 562,
                    'align_length'  => '441'
                },
                {
                    'primer_name'   => 'R3',
                    'primer_status' => 'no_hits',
                    'read_length'   => 651
                },
                {
                    'primer_name'   => 'LR',
                    'primer_status' => 'no_hits',
                    'read_length'   => 714
                },
                {
                    'primer_name'   => 'L1',
                    'primer_status' => 'no_hits',
                    'read_length'   => 685
                },
                {
                    'primer_name'   => 'PNF',
                    'primer_status' => 'no_hits',
                    'read_length'   => 505
                }
            ],
            'qctest_result_id' => '1615697',
            'construct_clone'  => 'PG00174_Z_C05_8',
            'best_for_design'  => '0',
            'clone_well'       => 'C05',
            'clone_plate'      => 'PG00174_Z'
        }
    ],
    'design_plate' => '174',
    'design_well'  => 'G12',
    'name' =>
'final_234708_ENSMUSE00000264291_L1L2_Bact_P_R3R4_pBR_DTA+_Bsd_amp_174_G12',
    'good_clones' => [
        {
            'pass_status'      => 'fail',
            'ok_primers_count' => 3,
            'best_for_design'  => '0',
            'clone_name'       => 'PG00174_Z_G12_6'
        },
        {
            'pass_status'      => 'warn_3arm_',
            'ok_primers_count' => 4,
            'best_for_design'  => '0',
            'clone_name'       => 'PG00174_Z_G12_8'
        },
        {
            'pass_status'      => 'pass4.1',
            'ok_primers_count' => 4,
            'best_for_design'  => '0',
            'clone_name'       => 'PG00174_Z_G12_2'
        },
        {
            'pass_status'      => 'pass4.1',
            'ok_primers_count' => 5,
            'best_for_design'  => '1',
            'clone_name'       => 'PG00174_Z_G12_1'
        },
        {
            'pass_status'      => 'pass4.1',
            'ok_primers_count' => 5,
            'best_for_design'  => '0',
            'clone_name'       => 'PG00174_Z_G12_3'
        },
        {
            'pass_status'      => 'pass4.1',
            'ok_primers_count' => 5,
            'best_for_design'  => '0',
            'clone_name'       => 'PG00174_Z_G12_4'
        },
        {
            'pass_status'      => 'pass4.1',
            'ok_primers_count' => 4,
            'best_for_design'  => '0',
            'clone_name'       => 'PG00174_Z_G12_7'
        },
        {
            'pass_status'      => 'pass4.1',
            'ok_primers_count' => 5,
            'best_for_design'  => '0',
            'clone_name'       => 'PG00174_Z_G12_5'
        }
    ],
    'is_genomic' => 0
};

=for DATA BY CLONE (first):

$VAR1 = {
    'pass_status'      => 'fail',
    'clone_plate'      => 'PG00174_Z',
    'qctest_result_id' => '1616207',
    'primers'          => [
        {
            'primer_name'   => 'PGO',
            'primer_status' => 'no_hits',
            'read_length'   => 0
        },
        {
            'loc_status'    => 'ok',
            'primer_name'   => 'R3',
            'primer_status' => 'valid',
            'read_length'   => 691,
            'align_length'  => '691'
        },
        {
            'primer_name'   => 'L1',
            'primer_status' => 'no_hits',
            'read_length'   => 0
        },
        {
            'primer_name'   => 'PNF',
            'primer_status' => 'no_hits',
            'read_length'   => 0
        },
        {
            'primer_name'   => 'LR',
            'primer_status' => 'no_hits',
            'read_length'   => 0
        }
    ],
    'construct_clone' => 'PG00174_Z_A01_8',
    'clone_well'      => 'A01',
    'best_for_design' => '1',
    'synthetic_vector' =>
'final_233029_ENSMUSE00000175423_L1L2_Bact_P_R3R4_pBR_DTA+_Bsd_amp_174_A01'
};

=cut

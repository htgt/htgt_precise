#!/usr/bin/env perl -T

use 5.008;
use strict;
use warnings FATAL => 'all';

use Test::Most;

use_ok 'HTGT::Utils::Report::QCResultsAndPrimers', ':all';

# we (will) need the qc_run_id that will return this synthetic vector
# qc run_id = 13454
my $expected_data_structure = [
    {
        name =>
'final_233029_ENSMUSE00000175423_L1L2_Bact_P_R3R4_pBR_DTA+_Bsd_amp_174_A01',
        design_well  => 'A01',
        design_plate => 174,
        is_genomic   => 0,

        # all the qc results for this synthetic vector
        qc_results => [
            {
                qctest_result_id => 1616212,
                pass_status      => 'fail',
                construct_clone  => 'PG00174_Z_C09_2',
                clone_plate     => 'PG00174_Z',
                clone_well      => 'C09',
                primers          => [
                    {
                        primer_name   => 'LR',
                        primer_status => 'valid',
                        read_length   => 366,
                        align_length  => 144,
                        loc_status    => 'ok'
                    },
                    {
                        primer_name   => 'PGO',
                        primer_status => 'valid',
                        read_length   => 674,
                        align_length  => 425,
                        loc_status    => 'ok'
                    },
                    {
                        primer_name   => 'R3',
                        primer_status => 'ori_fail',
                        read_length   => 580,
                        align_length  => 75,
                        loc_status    => 'ori_fail'
                    }
                  ]

            },
            {
                qctest_result_id => 1616213,
                pass_status      => 'fail',
                construct_clone  => 'PG00174_Z_D05_6',
                clone_plate     => 'PG00174_Z',
                clone_well      => 'D05',
                primers          => [
                    {
                        primer_name   => 'PGO',
                        primer_status => 'valid',
                        read_length   => 601,
                        align_length  => 425,
                        loc_status    => 'ok'
                    },
                    {
                        primer_name   => 'R3',
                        primer_status => 'valid',
                        read_length   => 312,
                        align_length  => 135,
                        loc_status    => 'ok'
                    }
                ]
            },
            {
                qctest_result_id => 1616214,
                pass_status      => 'fail',
                construct_clone  => 'PG00174_Z_D05_3',
                clone_plate     => 'PG00174_Z',
                clone_well      => 'D05',
                primers          => [
                    {
                        primer_name   => 'PGO',
                        primer_status => 'valid',
                        read_length   => 478,
                        align_length  => 425,
                        loc_status    => 'ok'
                    },
                    {
                        primer_name   => 'R3',
                        primer_status => 'valid',
                        read_length   => 295,
                        align_length  => 130,
                        loc_status    => 'ok'
                    }
                ]
            },
        ],

        # clones with min ok primers >= 2
        good_clones => [
            {
                clone_name       => 'PG00174_Z_D05_3',
                ok_primers_count => 2,
                pass_status      => 'fail',
                best_for_design  => 1
            },
            {
                clone_name       => 'PG00174_Z_D05_6',
                ok_primers_count => 2,
                pass_status      => 'fail',
                best_for_design  => 0
            },
        ],

        # all primer names in the qc_results for this synthetic vector
        available_primers => [ 'LR', 'PGO', 'R3' ],
    },
];

# retrieve all results for the qcrun_id sorted by plate and well
# my @test_structure = sort {
#          $a->{plate} <=> $b->{plate}
#       || $a->{clone_well} cmp $b->{clone_well}
# } map { @{ $_->{qc_results} } } @{$expected_data_structure};

# use Data::Dumper;
# print Dumper \@test_structure;

TODO: {
    local $TODO = 'retrieve the data correctly';

    # is_deeply(
    #     retrieve_data_for(),
    #     $expected_data_structure,
    #     'got the expected data structure'
    # );
}

done_testing();

exit 0;

=for template_code:

data_structure
primer_names

[% FOR synvec IN expected_data_structure %]
  <table>
    <th>
      <td>
        Engineered Seq Name
      </td>
      <td>
        Clone name, Valid primers count, pass level
      </td>
    </th>
    <tr>
      <td>[% synvec.synvec_name %]</td>
      <td>
        [% FOR clone IN good_clones %]
           [[% clone.clone_name %], [% clone.ok_primers_count %], [% clone.pass_status %]]
       [% IF clone.best_for_design == 1 %]*[% END %]
    [% END %]
      </td>
    </tr>
    <tr>
       <table>
         <th>
       <tr>
        <td rowspan=2 >
           QC test Result ID
        </td>
        <td rowspan=2>
           Pass Status
        </td>
        <td rowspan=2>
           Construct Clone
        </td>
        <td rowspan=2>
           Design Plate
        </td>
        <td rowspan=2>
           Design Well
        </td>
        [% FOR primer IN synvec.available_primers %]
          <td colspan=4>
            [% primer %]
          </td>
        [% END %]
       </tr>
           <tr>
        [% FOR primer IN expected_primer_names %]
            <td>Primer status</td>
            <td>Read Length</td>
            <td>Align Length</td>
            <td>Loc status</td>
        [% END %]
       </tr>
       [% FOR result IN synvec.qc_results %]
       <tr>
          <td>
            [% result.qctest_result_id %]
          </td>
          <td>
            [% result.pass_status %]
          </td>
          <td>
            [% result.construct_clone %]
          </td>
          <td>
            [% result.clone_plate %]
          </td>
          <td>
            [% result.clone_well %]
          </td>
           [% FOR primer_name IN expected_primer_names;
                    this_primer = result.primers.$primer_name;
                  -%]
                     <td>[% this_primer.primer_status %]</td>
                     <td>[% this_primer.read_length %]</td>
                     <td>[% this_primer.align_length %]</td>
                     <td>[% this_primer.loc_status %]</td>
                  [% END %]
       </tr>
       [% END %]
     </th>
       </table>
    </tr>
  </table>    
[% END %]

=cut

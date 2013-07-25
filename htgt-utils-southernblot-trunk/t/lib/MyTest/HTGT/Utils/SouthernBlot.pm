package MyTest::HTGT::Utils::SouthernBlot;

use strict;
use warnings FATAL => 'all';

use base qw( Test::Class Class::Data::Inheritable );

use Smart::Comments;
use Bio::Seq;

BEGIN {
    __PACKAGE__->mk_classdata( 'class'        => 'HTGT::Utils::SouthernBlot' );
    __PACKAGE__->mk_classdata( 'enzyme_names' => [qw(SanDI BstPI BspEI AccI)] );
    __PACKAGE__->mk_classdata('seq');
    __PACKAGE__->mk_classdata('enzymes');
    __PACKAGE__->mk_classdata('o');
    __PACKAGE__->mk_classdata('o2');

    __PACKAGE__->mk_classdata(
        _restriction_enzymes => {
            fivep_enzymes => {
                BstPI => {
                    distance_g5        => 5546,
                    distance_g5_num    => 5546,
                    distance_probe     => 2066,
                    distance_probe_num => 2066,
                    fragment_size      => 20104,
                    fragment_size_num  => 20104,
                    is_preferred       => 'no',
                    enzyme             => 'BstPI',
                    is_fuzzy           => 0
                },
                SanDI => {
                    distance_g5        => 290,
                    distance_g5_num    => 290,
                    distance_probe     => 2751,
                    distance_probe_num => 2751,
                    fragment_size      => 15533,
                    fragment_size_num  => 15533,
                    is_preferred       => 'no',
                    enzyme             => 'SanDI',
                    is_fuzzy           => 0
                }
            },
            threep_enzymes => {
                BspEI => {
                    distance_g3        => 3707,
                    distance_g3_num    => 3707,
                    distance_probe     => 611,
                    distance_probe_num => 611,
                    fragment_size      => 9990,
                    fragment_size_num  => 9990,
                    is_preferred       => 'no',
                    enzyme             => 'BspEI',
                    is_fuzzy           => 0
                }
            }
        }
    );

    __PACKAGE__->mk_classdata(
        _restriction_enzymes2 => {
            fivep_enzymes => {
                BstPI => {
                    distance_g5        => 5546,
                    distance_g5_num    => 5546,
                    distance_probe     => 2083,
                    distance_probe_num => 2083,
                    fragment_size      => 20104,
                    fragment_size_num  => 20104,
                    is_preferred       => 'no',
                    enzyme             => 'BstPI',
                    is_fuzzy           => 0
                },
                SanDI => {
                    distance_g5        => 290,
                    distance_g5_num    => 290,
                    distance_probe     => 2768,
                    distance_probe_num => 2768,
                    fragment_size      => 15533,
                    fragment_size_num  => 15533,
                    is_preferred       => 'no',
                    enzyme             => 'SanDI',
                    is_fuzzy           => 0
                }
            },
            threep_enzymes => {
                BspEI => {
                    distance_g3        => 3707,
                    distance_g3_num    => 3707,
                    distance_probe     => 664,
                    distance_probe_num => 664,
                    fragment_size      => 9990,
                    fragment_size_num  => 9990,
                    is_preferred       => 'no',
                    enzyme             => 'BspEI',
                    is_fuzzy           => 0
                }
            }
        }
    );

    __PACKAGE__->mk_classdata(
        _threep_enzymes => [
            {   'enzyme'             => 'BspEI',
                'fragment_size'      => 9990,
                'fragment_size_num'  => 9990,
                'distance_g3'        => 3707,
                'distance_g3_num'    => 3707,
                'distance_probe'     => 611,
                'distance_probe_num' => 611,
                is_fuzzy             => 0,
                is_preferred         => 'no',
            }
        ]
    );

    __PACKAGE__->mk_classdata(
        _fivep_enzymes => [
            {   'enzyme'             => 'SanDI',
                'fragment_size'      => 15533,
                'fragment_size_num'  => 15533,
                'distance_g5'        => 290,
                'distance_g5_num'    => 290,
                'distance_probe'     => 2751,
                'distance_probe_num' => 2751,
                is_fuzzy             => 0,
                is_preferred         => 'no'
            },
            {   'enzyme'             => 'BstPI',
                'fragment_size'      => 20104,
                'fragment_size_num'  => 20104,
                'distance_g5'        => 5546,
                'distance_g5_num'    => 5546,
                'distance_probe'     => 2066,
                'distance_probe_num' => 2066,
                is_fuzzy             => 0,
                is_preferred         => 'no',
            },
        ]
    );

    __PACKAGE__->mk_classdata(
        neo_probe_seq => Bio::Seq->new(
            -alphabet => 'dna',
            -seq =>
                'GCTATTCGGCTATGACTGGGCACAACAGACAATCGGCTGCTCTGATGCCGCCGTGTTCCGGCTGTCAGCGCAGGGGCGCCCGGTTCTTTTTGTCAAGACCGACCTGTCCGGTGCCCTGAATGAACTGCAGGACGAGGCAGCGCGGCTATCGTGGCTGGCCACGACGGGCGTTCCTTGCGCAGCTGTGCTCGACGTTGTCACTGAAGCGGGAAGGGACTGGCTGCTATTGGGCGAAGTGCCGGGGCAGGATCTCCTGTCATCTCACCTTGCTCCTGCCGAGAAAGTATCCATCATGGCTGATGCAATGCGGCGGCTGCATACGCTTGATCCGGCTACCTGCCCATTCGACCACCAAGCGAAACATCGCATCGAGCGAGCACGTACTCGGATGGAAGCCGGTCTTGTCGATCAGGATGATCTGGACGAAGAGCATCAGGGGCTCGCGCCAGCCGAACTGTTCGCCAGGCTCAAGGCGCGCATGCCCGACGGCGAGGATCTCGTCGTGACCCATGGCGATGCCTGCTTGCCGAATATCATGGTGGAAAATGGCCGCTTTTCTGGATTCATCGACTGTGGCCGGCTGGGTGTGGCGGACCGCTATCAGGACATAGCGTTGGCTACCCGTGATATTGCTGAAGAGCTTGGCGGCGAATGGGCTGACCGCTTCCTCGTGCTTTACGGTATCGCCGCTCCCGATTCGCAGCGCATCGCCTTCTATCGCCTTC'
        )
    );

}

use HTGT::Utils::SouthernBlot;
use Test::Most;
use Bio::SeqIO;
use Bio::Restriction::EnzymeCollection;
use FindBin;

sub make_fixture : Test(startup) {
    my $class = shift;

    my $seq_io = Bio::SeqIO->new(
        -file   => "$FindBin::Bin/data/221342.gbk",
        -format => 'genbank'
    );
    $class->seq( $seq_io->next_seq );

    my $complete_collection = Bio::Restriction::EnzymeCollection->new();
    my $my_collection = Bio::Restriction::EnzymeCollection->new( -empty => 1 );
    $my_collection->enzymes( map $complete_collection->get_enzyme($_), @{ $class->enzyme_names } );
    $class->enzymes($my_collection);

    $class->o( $class->class->new( sequence => $class->seq, enzymes => $class->enzymes, probe => 'NeoR' ) );
    $class->o2(
        $class->class->new( sequence => $class->seq, enzymes => $class->enzymes, probe_seq => $class->neo_probe_seq ) );

}

sub constructor : Tests(8) {
    my $test = shift;

    can_ok $test->class, 'new';
    ok my $ra1 = $test->class->new( sequence => $test->seq, probe => 'NeoR' ),
        'probe/sequence only constructor should succeed';
    isa_ok $ra1, $test->class;

    ok my $ra2 = $test->class->new( sequence => $test->seq, enzymes => $test->enzymes, probe => 'NeoR' ),
        'probe/sequence/enzymes constructor should succeed';
    isa_ok $ra2, $test->class;

    ok my $ra3
        = $test->class->new( sequence => $test->seq, enzymes => $test->enzymes, probe_seq => $test->neo_probe_seq ),
        'sequence/enzymes/probe_seq constructor should succeed';
    isa_ok $ra3, $test->class;

    throws_ok { $test->class->new( probe => 'NeoR' ) } qr/es_clone_name must be given when sequence is not supplied/,
        'constructor with no sequence or es_clone_name';

}

sub locations : Tests(9) {
    my $test = shift;

    for my $method (qw( five_arm three_arm probe_loc )) {
        can_ok $test->o, $method;
        isa_ok $test->o->$method,  'Bio::LocationI';
        isa_ok $test->o2->$method, 'Bio::LocationI';
    }
}

sub restriction_enzymes : Tests(5) {
    my $test = shift;

    can_ok $test->o, 'restriction_enzymes';
    isa_ok $test->o->restriction_enzymes,  'HASH';
    isa_ok $test->o2->restriction_enzymes, 'HASH';

    is_deeply $test->o->restriction_enzymes,  $test->_restriction_enzymes;
    is_deeply $test->o2->restriction_enzymes, $test->_restriction_enzymes2;
}

sub threep_enzymes : Tests(3) {
    my $test = shift;

    can_ok $test->o, 'threep_enzymes';
    isa_ok $test->o->threep_enzymes,    'ARRAY';
    is_deeply $test->o->threep_enzymes, $test->_threep_enzymes;
}

sub fivep_enzymes : Tests(3) {
    my $test = shift;

    can_ok $test->o, 'fivep_enzymes';
    isa_ok $test->o->fivep_enzymes,    'ARRAY';
    is_deeply $test->o->fivep_enzymes, $test->_fivep_enzymes;
}

sub max_fragment_size : Tests(6) {
    my $test = shift;

    can_ok $test->o, 'max_fragment_size';
    is $test->o->max_fragment_size, 0, 'default max_fragment_size should be 0';

    ok my $sb = $test->class->new(
        sequence          => $test->seq,
        enzymes           => $test->enzymes,
        max_fragment_size => 16000,
        probe             => 'NeoR'
        ),
        'constructor with max_fragment_size';

    is $sb->max_fragment_size, 16000, 'max_fragment_size is 16000';

    for my $e ( @{ $sb->fivep_enzymes }, @{ $sb->threep_enzymes } ) {
        ok $e->{fragment_size} <= 16000, 'fragment size for ' . $e->{enzyme};
    }
}

sub es_clone_name : Tests(7) {
    my $test = shift;

    can_ok $test->o, 'es_clone_name';
    ok !$test->o->es_clone_name, 'es_clone_name unset for object constructed with sequence only';

    ok my $sb = $test->class->new( es_clone_name => 'EPD0347_2_G01', enzymes => $test->enzymes, probe => 'NeoR' ),
        'constructor with es_clone_name';

    is $sb->es_clone_name, 'EPD0347_2_G01', 'es_clone_name is EPD0347_2_G01';

    ok $sb->sequence,                   'got sequence from targ_rep';
    isa_ok $sb->sequence,               'Bio::SeqI';
    is_deeply $sb->restriction_enzymes, $test->_restriction_enzymes;
}

sub es_clone_name_and_all_enzymes : Tests(2) {
    my $test = shift;

    ok my $sb = $test->class->new( es_clone_name => 'EPD0347_2_G01', probe => 'NeoR' ),
        'constructor with es_clone_name, default enzymes';
    isa_ok $sb->restriction_enzymes, 'HASH', 'restriction_enzymes';
}

1;

__END__

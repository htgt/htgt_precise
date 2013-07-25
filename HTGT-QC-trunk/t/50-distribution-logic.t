#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use Test::Exception;
use Log::Log4perl ':levels';

die_on_fail;

my $valid_config = get_valid_config();

my %loxp_three_arm_distribute = (
    primer_band_GR3 => 1,
    primer_band_GR4 => 1,
    primer_read_A_LR => 1,
);
my %five_arm_targeted_trap = (
   primer_band_GF1 => 1,
   primer_band_GF2 => 1
);
my %all_fail = (
   primer_band_TR_PCR => 1
);
my %invalid_qc_data = (
   primer_band_AG => 1
);

use_ok 'HTGT::QC::DistributionLogic';

ok my $dl = HTGT::QC::DistributionLogic->new( {
   config   => $valid_config,
   qc_data  => \%loxp_three_arm_distribute,
   profile  => 'standard'
} ), 'the constructor succeeds';

ok my $parser = $dl->parser, 'parser creation succeeds';
isa_ok $parser, 'Parse::BooleanLogic', 'parser object correct';

ok( $dl->five_arm_pass != 1,  'valid 5-arm fail');
ok( $dl->three_arm_pass == 1, 'valid 3-arm pass');
ok( $dl->loxp_pass == 1,      'valid loxp pass');
ok( $dl->targeted_trap !=1,   'valid targeted_trap fail');
ok( $dl->distribute == 1,     'valid distribute pass');

$dl = HTGT::QC::DistributionLogic->new( {
    config   => $valid_config,
    qc_data  => \%five_arm_targeted_trap,
    profile  => 'standard'
} );

ok( $dl->five_arm_pass == 1,  'valid 5-arm pass');
ok( $dl->three_arm_pass != 1, 'valid 3-arm fail');
ok( $dl->loxp_fail == 1,      'valid loxp fail');
ok( $dl->targeted_trap ==1,   'valid targeted_trap pass');
ok( $dl->distribute != 1,     'valid distribute fail');   

$dl = HTGT::QC::DistributionLogic->new( {
    config   => $valid_config,
    qc_data  => \%all_fail,
    profile  => 'standard'
} );

ok( $dl->five_arm_pass != 1,  'valid 5-arm fail');
ok( $dl->three_arm_pass != 1, 'valid 3-arm fail');
ok( $dl->loxp_fail == 1,      'valid loxp fail');
ok( $dl->targeted_trap !=1,   'valid targeted_trap fail');
ok( $dl->distribute != 1,     'valid distribute fail');

throws_ok { HTGT::QC::DistributionLogic->new( {
    config    => $valid_config,
    qc_data  => \%invalid_qc_data,
    profile  => 'standard'
} ) } "HTGT::QC::Exception", 'throws appropriate exception for invalid test in qc_data';

my $invalid_config = get_invalid_config();

throws_ok { HTGT::QC::DistributionLogic->new( {
    config   => $invalid_config,
    qc_data  => \%loxp_three_arm_distribute,
    profile  => 'standard'
} ) } "HTGT::QC::Exception", 'throws appropriate exception for invalid config';

done_testing;
           
sub get_valid_config{

    my %config;

    $config{'profile'}{'standard'} = {
        'loxp_pass'      => '(GR AND (LR OR LRR OR LF)) OR (TR AND B_R2R)',
        'five_arm_pass'  => '(GF AND R1R) OR GF>=2',
        'three_arm_pass' => '(GR AND (LR OR LRR OR LF)) OR (GR>=2) OR (GR AND (A_R2R OR Z_R2R OR R_R2R))',
        'distribute'     => '(five_arm_pass OR three_arm_pass) AND loxp_pass',
        'targeted_trap'  => '(five_arm_pass OR three_arm_pass) AND loxp_fail'
    };

    return \%config;
}

sub get_invalid_config{

    my %config;

    $config{'profile'}{'standard'} = {
        'loxp_pass'      => '(GR AND (LR OR LRR OR LF)) OR (TR AND B_R2R)',
        'five_arm_pass'  => '(GF AND R4R) OR GF>=2',
        'three_arm_pass' => '(GR AND (LR OR LRR OR LF)) OR (GR>=2) OR (GR AND (A_R2R OR Z_R2R OR R_R2R))',
        'distribute'     => '(five_arm_pass OR three_arm_pass) AND loxp_pass',
        'targeted_trap'  => '(five_arm_pass OR three_arm_pass) AND loxp_fail'
    };

    return \%config;
}

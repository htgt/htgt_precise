#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN { $ENV{TARMITS_CLIENT_CONF} = '/software/team87/brave_new_world/conf/tarmits-client-live.yml' }

use Test::Most;
use HTGT::Utils::SouthernBlot;
use Log::Log4perl ':levels';
use Const::Fast;

Log::Log4perl->easy_init( $ERROR );

const my $ES_CLONE_NAME => 'EPD0155_1_B07';

die_on_fail;

{    
    ok my $sb = HTGT::Utils::SouthernBlot->new( es_clone_name => $ES_CLONE_NAME, tolerance_pct => 0, probe => 'NeoR' ),
        'constructor should succeed (zero tolerance)';    
    ok !check_drdi( $sb->threep_enzymes ), "DrdI is not valid for 3' analysis with zero tolerance";    
}

{
    ok my $sb = HTGT::Utils::SouthernBlot->new( es_clone_name => $ES_CLONE_NAME, tolerance_pct => 25, probe => 'NeoR' ),
        'constructor should succeed (25% tolerance)';
    ok( check_drdi( $sb->threep_enzymes ), "DrdI is valid for 3' analysis with 25% tolerance" );    
}    

done_testing;

sub check_drdi {
    my $enzymes = shift;

    for ( @{$enzymes} ) {
        return 1 if $_->{enzyme} eq 'DrdI';
    }

    return;
}


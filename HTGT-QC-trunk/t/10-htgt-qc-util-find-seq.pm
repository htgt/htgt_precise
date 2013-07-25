#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use FindBin;

use_ok 'HTGT::QC::Util::FindSeq';

{

    my $id = 'vector_374239_ENSMUSE00000436236_Ifitm2_intron_R1_ZeoPheS_R2_R3R4_pBR_amp';
    
    ok my $gbk = find_seq( "$FindBin::Bin/data", $id, 'genbank' ), 'find genbank seq succeeds';
    isa_ok $gbk, 'Bio::SeqI', '...the object it returns';
    is $gbk->display_id, $id, 'genbank seq has the expected display_id';

    ok my $fsa = find_seq( "$FindBin::Bin/data", $id, 'fasta' ), 'find fasta seq succeeds';
    is $fsa->display_id, $id, 'fasta seq has the expected display id';

    throws_ok { find_seq( "$FindBin::Bin/data", $id, 'spacedust' ) }
        qr/Unrecognized format/, 'attempt to retrieve spacedust throws exception';
}

done_testing;

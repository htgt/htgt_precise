#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use FindBin;
use Bio::SeqIO;

use_ok 'HTGT::QC::Util::FindSeqFeature';

my $seq = Bio::SeqIO->new( -file   => "$FindBin::Bin/data/Gpc3_AI_374239_intermediate.gbk",
                           -format => 'genbank' )->next_seq;

{
    ok my @features = find_seq_feature( $seq, primary_tag => 'gateway', label => 'B4' ), 'find gateway/B4';
    is @features, 1, 'there is only 1 gateway/B4';
}

{    
    ok my @features = find_seq_feature( $seq, label => qr/^B/ ), 'we can match a regexp';
    is @features, 4, 'there are 4 features labelled qr/^B/';
}

{
    my @features = find_seq_feature( $seq, label => 'NoSuchFeatureBeDamned' );
    is @features, 0, 'match no features';
}

ok !find_seq_feature( $seq, label => 'NoSuchFeatureBeDamned' ),
    'matching no feature in scalar context returns nothing';    

dies_ok { my $feature = find_seq_feature( $seq, label => qr/^B/ ) }
    'matching multiple features in scalar context dies';

done_testing;


    

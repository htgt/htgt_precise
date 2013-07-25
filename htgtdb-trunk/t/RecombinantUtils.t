#!/usr/bin/perl
# test for RecombinantUtils.pm
# David K. Jackson <david.jackson@sanger.ac.uk>
use Test::More tests => 72;
use Test::Exception;
use strict;
use Bio::SeqIO;
use Bio::Seq;
use Bio::SeqUtils;
use Bio::Perl;
use List::MoreUtils qw(uniq);

my $si = Bio::SeqIO->new(-format=>'genbank', -fh=>\*DATA);
my %sh;
while(my $seq = $si->next_seq){ 
  $sh{$seq->display_id} = $seq;
  #diag("have seq ".$seq->display_id);
}
my $backbone = Bio::Seq->new(-alphabet=>'dna',is_circular=>1);
Bio::SeqUtils->cat($backbone, $sh{pR3R4AsiSI_synvect_U}, Bio::Seq->new(-alphabet=>'dna', -seq=>'N'x200), $sh{pR3R4AsiSI_synvect_D});

sub sequence_match {#quick non exhaustive (as new origin cannot overlap 200bp used for recognition) check if sequences match
  our ($resultseq, $resultseq2) = @_;
  return 1 if (($resultseq2->seq eq $resultseq->seq) or ($resultseq2->revcom->seq eq $resultseq->seq));
  return 0 unless ($resultseq2->is_circular or $resultseq->is_circular);
  unless($resultseq2->is_circular){($resultseq2, $resultseq)=($resultseq, $resultseq2)} #ensure resultseq2 is circular
  my $offset = index($resultseq2->seq,$resultseq->subseq(1,200));
  if($offset<0){
    $resultseq2 = Bio::SeqUtils->revcom_with_features($resultseq2);
    $offset = index($resultseq2->seq,$resultseq->subseq(1,200));
  }
  return 0 if $offset<=0;
  return $resultseq2->subseq(1+$offset,$resultseq2->length).$resultseq2->subseq(1,$offset) eq $resultseq->seq;
}

use_ok(q(RecombinantUtils),qw(recombineer gateway));

### lets check some of the internal helper functions
my $pseq1 = new Bio::PrimarySeq(-id=>'AGseq', -alphabet=>'dna', -seq=>('A'x20).('G'x30));
my ($pos, $strand);
lives_ok { ($pos, $strand) = RecombinantUtils::_simple_primer_align($pseq1, 'CT')} '_simple_primer_align lives with findable primer';
cmp_ok($pos, '==', 20, ' position');
cmp_ok($strand, '==', -1, ' strand');
lives_ok { ($pos, $strand) = RecombinantUtils::_simple_primer_align($pseq1, 'AG')} '_simple_primer_align lives with findable primer';
cmp_ok($pos, '==', 21, ' position');
cmp_ok($strand, '==', +1, ' strand');
throws_ok { ($pos, $strand) = RecombinantUtils::_simple_primer_align($pseq1, 'CC')} qr/more than once/,'_simple_primer_align throws on repeated primer';
throws_ok { ($pos, $strand) = RecombinantUtils::_simple_primer_align($pseq1, 'CAC')} qr/not found/,'_simple_primer_align throws on not finding primer';
lives_ok { ($pos, $strand) = RecombinantUtils::_simple_re_align($pseq1, 'CT')} '_simple_re_align lives with findable primer';
cmp_ok($pos, '==', 20, ' position');
cmp_ok($strand, '==', -1, ' strand');
lives_ok { ($pos, $strand) = RecombinantUtils::_simple_re_align($pseq1, 'AG')} '_simple_re_align lives with findable primer';
cmp_ok($pos, '==', 21, ' position');
cmp_ok($strand, '==', +1, ' strand');
throws_ok { ($pos, $strand) = RecombinantUtils::_simple_re_align($pseq1, 'CC')} qr/more than once/,'_simple_re_align throws on repeated primer';
throws_ok { ($pos, $strand) = RecombinantUtils::_simple_re_align($pseq1, 'CAC')} qr/not found/,'_simple_re_align throws on not finding primer';


### Check "recombineer"

my $gseq = $sh{allele_45286_OTTMUSE00000380587_wt};
my ($g5g_f,  $g3g_f)  = @{{map{($_->get_tagset_values('note'))[0]=>$_}grep{$_->primary_tag eq 'rcmb_primer'}$gseq->get_SeqFeatures}}{qw(G5 G3)};
my ($g5bb_f, $g3bb_f) = @{{map{($_->get_tagset_values('note'))[0]=>$_}grep{$_->primary_tag eq 'primer_bind'}$backbone->get_SeqFeatures}}{'R3 primer','R4 primer'};
my ($g5g,  $g3g, $g5bb, $g3bb) = map{$_->seq->seq} ($g5g_f,  $g3g_f, $g5bb_f, $g3bb_f); 
my $resultseq;
lives_ok{ $resultseq = recombineer($backbone, $gseq, $g5bb, $g5g, $g3bb, $g3g); } 'recombineer lives with suitable Seq and primer strings';
unlike($resultseq->seq, qr/N/i, ' drops expected sequence');
cmp_ok($resultseq->length, '==', (11150+($sh{pR3R4AsiSI_synvect_U}->length)+($sh{pR3R4AsiSI_synvect_D}->length)), ' expected length');
ok($resultseq->is_circular, ' circular expected');
{my @orientations_of_features_in_same_orientation = map{$_->strand}grep{join(' ',$_->get_tagset_values('note'))=~/pBR322|OTTMUSE00000380588/}$resultseq->get_SeqFeatures;
cmp_ok(@orientations_of_features_in_same_orientation, '==', 3, ' expected certain feature count');
ok(scalar(uniq @orientations_of_features_in_same_orientation) == 1, ' expected certain features in same orientation');
my $manualseq = Bio::Seq->new(-alphabet=>q(dna));
Bio::SeqUtils->cat($manualseq, 
  $sh{pR3R4AsiSI_synvect_U},
  Bio::SeqUtils->trunc_with_features($gseq,10147,21296),
  $sh{pR3R4AsiSI_synvect_D},
);
ok(sequence_match($resultseq, $manualseq), ' sequence matches manually constructed');
}


dies_ok{ recombineer($backbone, $gseq, $g5bb, $g5g, $g3bb, revcom_as_string($g3g)); } 'recombineer dies with dodgy primer orientation';

my $resultseq2;
lives_ok{ $resultseq2 = recombineer($gseq, $backbone, $g5g, $g5bb, $g3g, $g3bb); } 'recombineer lives with suitable Seq, swap order';
ok(sequence_match($resultseq, $resultseq2), ' produces same sequence');
ok($resultseq2->is_circular, ' circular expected');
my $gseqr = Bio::SeqUtils->revcom_with_features($gseq);
$backbone->is_circular(0);
lives_ok{ $resultseq2 = recombineer($backbone, $gseqr, $g5bb, $g5g, $g3bb, $g3g); } 'recombineer lives with one input Seq reverse complemented, other no longer circular';
ok(sequence_match($resultseq, $resultseq2), ' produces same sequence');
ok((not $resultseq2->is_circular), ' not circular expected');
$backbone->is_circular(1);
{my @orientations_of_features_in_same_orientation = map{$_->strand}grep{join(' ',$_->get_tagset_values('note'))=~/pBR322|OTTMUSE00000380588/}$resultseq2->get_SeqFeatures;
cmp_ok(@orientations_of_features_in_same_orientation, '==', 3, ' expected certain feature count');
ok(scalar(uniq @orientations_of_features_in_same_orientation) == 1, ' expected certain features in same orientation');
}

my $rbackbone = Bio::SeqUtils->revcom_with_features($backbone);
$rbackbone->is_circular(1);
lives_ok{ $resultseq2 = recombineer($rbackbone, $gseq, $g5bb, $g5g, $g3bb, $g3g); } 'recombineer lives with other input Seq reverse complemented';
ok(sequence_match($resultseq, $resultseq2), ' produces same sequence');
ok(($resultseq2->is_circular), ' circular expected');
{my @orientations_of_features_in_same_orientation = map{$_->strand}grep{join(' ',$_->get_tagset_values('note'))=~/pBR322|OTTMUSE00000380588/}$resultseq2->get_SeqFeatures;
cmp_ok(@orientations_of_features_in_same_orientation, '==', 3, ' expected certain feature count');
ok(scalar(uniq @orientations_of_features_in_same_orientation) == 1, ' expected certain features in same orientation');
}

lives_ok{ $resultseq2 = recombineer($backbone, $gseq, $g5bb_f, $g5g_f, $g3bb_f, $g3g_f); } 'recombineer lives using SeqFeatures';
ok(sequence_match($resultseq, $resultseq2), ' produces same sequence');

{my ($g5rbb_f,$g3rbb_f) = @{{map{($_->get_tagset_values('note'))[0]=>$_}grep{$_->primary_tag eq 'primer_bind'}$rbackbone->get_SeqFeatures}}{'R3 primer','R4 primer'};
lives_ok{ $resultseq2 = recombineer($rbackbone, $gseq, $g5rbb_f, $g5g_f, $g3rbb_f, $g3g_f); } 'recombineer lives using SeqFeatures, revcom one seq';
ok(sequence_match($resultseq, $resultseq2), ' produces same sequence');
lives_ok{ $resultseq2 = recombineer($gseq, $rbackbone, $g5g_f, $g5rbb_f, $g3g_f, $g3rbb_f); } 'recombineer lives using SeqFeatures, revcom one seq, swap order';
ok(sequence_match($resultseq, $resultseq2), ' produces same sequence');
}

my $dodgyplasmid = Bio::Seq->new(-alphabet=>'dna');
Bio::SeqUtils->cat($backbone, Bio::SeqUtils->revcom_with_features($sh{pR3R4AsiSI_synvect_U}), Bio::Seq->new(-alphabet=>'dna', -seq=>'N'x200), $sh{pR3R4AsiSI_synvect_D});
dies_ok{ recombineer($dodgyplasmid, $gseq, $g5bb, $g5g, $g3bb, $g3g); } 'recombineer dies with dodgy plasmid';

my $backbonerotated = Bio::Seq->new(-alphabet=>'dna',is_circular=>1);
Bio::SeqUtils->cat($backbonerotated, Bio::Seq->new(-alphabet=>'dna',-seq=>'N'x100), $sh{pR3R4AsiSI_synvect_D}, $sh{pR3R4AsiSI_synvect_U}, Bio::Seq->new(-alphabet=>'dna',-seq=>'N'x100));
lives_ok{ $resultseq2 = recombineer($backbonerotated, $gseq, $g5bb, $g5g, $g3bb, $g3g); } 'recombineer lives with a suitable Seq rotated';
ok(sequence_match($resultseq, $resultseq2), ' produces same sequence');


### Check gateway
my $resultseq3;
lives_ok{ $resultseq3 = gateway($resultseq, $resultseq); } 'gateway lives with same Seqs (okay as we\'re only looking for B sites)';
cmp_ok($resultseq3->length, '==', $resultseq->length, ' expected length');
ok($resultseq3->is_circular, ' circular expected');
my $wseq = $sh{'pL3L4_(+)_DTA_Map2'};

my $resultseq4;
lives_ok{ $resultseq4 = gateway($resultseq, $wseq); } 'gateway lives with suitable Seqs';
ok((not grep{scalar(grep{/\bR3F primer\b/ or /this bit going/ or /pBR322/}$_->get_tagset_values($_->get_all_tags))}$resultseq4->get_SeqFeatures), ' drops expected features');
cmp_ok($resultseq4->length, '==', ($resultseq->length-(1180+2029-49)+(1111+5644-2752)), ' expected length');
ok($resultseq4->is_circular, ' circular expected');
{my @orientations_of_features_in_same_orientation = map{$_->strand}grep{join(' ',$_->get_tagset_values('note'))=~/L3 primer|DTA|OTTMUSE00000380588/}$resultseq4->get_SeqFeatures;
cmp_ok(@orientations_of_features_in_same_orientation, '==', 3, ' expected certain feature count');
ok(scalar(uniq @orientations_of_features_in_same_orientation) == 1, ' expected certain features in same orientation');
}
my ($b3_f, $b4_f) = @{{map{($_->get_tagset_values('note'))[0]=>$_}grep{$_->primary_tag eq 'gateway'}$resultseq->get_SeqFeatures}}{'B3','B4'};
{my $manualseq = Bio::Seq->new(-alphabet=>q(dna));
Bio::SeqUtils->cat($manualseq, 
  Bio::SeqUtils->trunc_with_features($wseq,1,1111),
  Bio::SeqUtils->trunc_with_features($resultseq,$b3_f->start,$b4_f->end),
  Bio::SeqUtils->trunc_with_features($wseq,2753,$wseq->length),
);
ok(sequence_match($resultseq4, $manualseq), ' sequence matches manually constructed');
}
{my $altinputR = Bio::Seq->new(-alphabet=>q(dna));
Bio::SeqUtils->cat($altinputR,
  Bio::SeqUtils->trunc_with_features($resultseq,($resultseq->length/2)+1,$resultseq->length),
  Bio::SeqUtils->trunc_with_features($resultseq,1,$resultseq->length/2),
);
$altinputR->is_circular(1);
my $resultseq5;
lives_ok{ $resultseq5 = gateway($altinputR, Bio::SeqUtils->revcom_with_features($wseq)); } 'gateway lives with rotated R seq, revcom L Seq';
ok(sequence_match($resultseq4, $resultseq5), ' produces same sequence');
lives_ok{ $resultseq5 = gateway(Bio::SeqUtils->revcom_with_features($altinputR), $wseq); } 'gateway lives with revcom rotated R seq';
ok(sequence_match($resultseq4, $resultseq5), ' produces same sequence');
lives_ok{ $resultseq5 = gateway(Bio::SeqUtils->revcom_with_features($resultseq), Bio::SeqUtils->revcom_with_features($wseq)); } 'gateway lives with revcom R seq, revcom L Seq';
ok(sequence_match($resultseq4, $resultseq5), ' produces same sequence');
lives_ok{ $resultseq5 = gateway(Bio::SeqUtils->revcom_with_features($resultseq), $wseq); } 'gateway lives with revcom R seq';
ok(sequence_match($resultseq4, $resultseq5), ' produces same sequence');
}

my $w2seq = $sh{'pL4L3_DONR223_DTAminusMap'};
lives_ok{ $resultseq4 = gateway($resultseq, $w2seq); } 'gateway lives with suitable Seqs (different L containing plasmid)';
ok((not grep{scalar(grep{/\bR3F primer\b/ or /this bit going/ or /pBR322/ or /ccdB ORF/}$_->get_tagset_values($_->get_all_tags))}$resultseq4->get_SeqFeatures), ' drops expected features');
ok($resultseq4->is_circular, ' circular expected');
{my @orientations_of_features_in_same_orientation = map{$_->strand}grep{join(' ',$_->get_tagset_values('note'))=~/pUC ori|Spectinomycin Promoter|G5/}$resultseq4->get_SeqFeatures;
cmp_ok(@orientations_of_features_in_same_orientation, '==', 3, ' expected certain feature count');
ok(scalar(uniq @orientations_of_features_in_same_orientation) == 1, ' expected certain features in same orientation');
}
{my $manualseq = Bio::Seq->new(-alphabet=>q(dna));
Bio::SeqUtils->cat($manualseq, 
  Bio::SeqUtils->revcom_with_features(Bio::SeqUtils->trunc_with_features($w2seq,2802,$w2seq->length)),
  Bio::SeqUtils->trunc_with_features($resultseq,$b3_f->start,$b4_f->end),
  Bio::SeqUtils->revcom_with_features(Bio::SeqUtils->trunc_with_features($w2seq,1,1160)),
);
cmp_ok($resultseq4->length, '==', $manualseq->length, ' expected length');
ok(sequence_match($resultseq4, $manualseq), ' sequence matches manually constructed');
}


__DATA__
LOCUS       allele_45286_OTTMUSE00000380587_wt        31540 bp    dna     linear   UNK 
DEFINITION  
ACCESSION   unknown
COMMENT     design_id : 45286
FEATURES             Location/Qualifiers
     rcmb_primer     complement(10147..10196)
                     /type="G5"
                     /note="G5"
     rcmb_primer     15002..15051
                     /type="U5"
                     /note="U5"
     rcmb_primer     complement(15105..15154)
                     /type="U3"
                     /note="U3"
     rcmb_primer     16366..16415
                     /type="D5"
                     /note="D5"
     rcmb_primer     complement(16491..16540)
                     /type="D3"
                     /note="D3"
     rcmb_primer     21247..21296
                     /type="G3"
                     /note="G3"
     exon            12972..13409
                     /db_xref="ens:OTTMUSE00000380589"
                     /note="OTTMUSE00000380589"
     exon            15512..16220
                     /db_xref="ens:OTTMUSE00000380587"
                     /type="targeted"
                     /note="target exon 1"
                     /note="OTTMUSE00000380587"
     exon            20885..22121
                     /db_xref="ens:OTTMUSE00000380588"
                     /note="OTTMUSE00000380588"
     LRPCR_primer    complement(21504..21533)
                     /type="GR3"
                     /note="GR3"
     LRPCR_primer    complement(21502..21530)
                     /type="GR4"
                     /note="GR4"
     LRPCR_primer    9500..9528
                     /type="GF3"
                     /note="GF3"
     LRPCR_primer    8451..8479
                     /type="GF4"
                     /note="GF4"
     LRPCR_primer    complement(15967..15992)
                     /type="EX32"
                     /note="EX32"
     LRPCR_primer    16176..16205
                     /type="EX52"
                     /note="EX52"
BASE COUNT     9057 a   7247 c   7148 g   8088 t
ORIGIN
        1 aaatggatgg acctggaggg catcatcctg agtgaggtaa cccaatcaca aaggaactca
       61 cacaatatgt actcactgat aagtggctat tagcccagaa acttaggata cccaaaatat
      121 aagatacaat ttgcaaaaca catgaaactc aagaagaatg aagaccaaag tgtggacact
      181 ttgccccttc ttagaattgg gaacaaaaca cccatggaag gagttacaga gacaaaattt
      241 ggagctgtga cgaaaggatg gaccatctag tgattgccat atccagggat ccatcccata
      301 atcagcttcc aaacgcagac accattgcat acactagcaa gattttgctg aaaggaccct
      361 gatatagctg tctcttgtga gactatgccg gggcctagca aacacagaag tggatgatca
      421 cagtcagcta ttggatgtat cacagggccc ccaatggagg agcttgagaa agtacccaag
      481 gagctaaagg gaactgcaac cctataggtg gaacaacaat atgaactaac cagtaccccg
      541 gagctcttga ctctagctgc atatgtatca aaagatggcc tagtcggcta tcactggaaa
      601 gagaggccca ttggacttgc aaactttata tgccccagta caggggaacg ccagggccaa
      661 aaagggggag tggatgggga ggggaggggg tgggtatggg ggactttggg gatagcattg
      721 gaaatgtaaa tgaggaaaat acctaataaa aattttaaaa aaaagagctt caactctgat
      781 tctaatcaat atatctggag agcctggttc acatacagtg gacactctca ctacagaaca
      841 cagaaagagt ttcacataac tccagaaaca cttgggaacc tcggatcctt cacactggga
      901 ggctgggtgg cgaaagaagt cagtgtcttc ctcatggggt aatcaactct gcccatcagg
      961 aaaagacagg gcttccatag aagaaagaaa accaccttga tgccccggta atgcatttct
     1021 tgctacttct cagatgagcg gtgatagtag gcggatgaag caaacccaaa gacaatgaag
     1081 ggagctaagt tcaccacact caagagtggg gttgtatgac tccaggtaag ttggacactg
     1141 gggtcaccag aaatgctgag agttagggaa gctgagagca gggaatccct cagagggaga
     1201 cagcacacat tagtggtggc cttgcaacca gccacagctc taaccttcac agaccatggc
     1261 tttctgggag gtgagaacta ccaccaccaa gagctaacac cgaaggaaac attatacaga
     1321 tggaaaggag acttctattg cataaaaact ggaaaataat attttcatca aaccagcaca
     1381 gcatctggga gtaactagaa cctctccgtc atcatctctt cctgggaaag aggccaacca
     1441 gagagtcctg gaggagctgc taccaaaaca gcctatttgg agctagcttc agaagagact
     1501 gtaatgtctc ggttctcaac ctgtgggtcg tgagcccctt gaggtcaaag gtcactttta
     1561 catgagtcac ctaagacaat tggaaaactc aagatgttta cgttatgatt cataacagta
     1621 gcaaacttat atgcttggag gtcacaatgt gcggagttct attagagggt tgcagcactg
     1681 ggaaggttga agggcacggc cctaagagaa tagagttctg ctggcaccac gttgtcagtg
     1741 tcatgacgtc tatttcagtt atgactgtca gagattatag gctaatatgt cttagcatct
     1801 taagcaacat ttgtggaatt ttattactaa gatagtataa tgacttagcg atgtaggaag
     1861 gaaggcaagg acacaaacct gcggaaaaaa aataagataa ataaacaaac aaacaaggat
     1921 gaagcacagg agtgagggga agtggctgag acagctgaga cgcatggcaa agaggtgggc
     1981 taaagacagg gtggaaaccc tgttcgtgtc tcacagacga ttatgttaaa aatacgttac
     2041 agaatgattt ggaaatgatt ttgtcaaagt aaacgtatat cctacatcca gttatataac
     2101 tcatttgtat ttcaataaag atggaaatgt cagttaaaaa aagaaaccgt tgctgctcgc
     2161 ccgtctagta cacaggaggc atctgtgtgc tatgagatgt atctatgagc tcctttagag
     2221 aaatgaactg gctgacccaa gggggttttt ccatctctcc tttttctgaa ttcaggcatt
     2281 gaaagggaac caggaaacat gaaagccggc aacctgagtc atctggggtt gttaaagcac
     2341 gaggttaagc tttgaaaaat actgttcaag aaacgcactc ctcactcact tagttaaaac
     2401 aggacgcttt ttatgatgtt tgcctagaaa ctctctgatc cctctactct gggtacagcc
     2461 acacacaacg cttgtctccc agctcctttc atctaaggat aatgctcact ccttctggca
     2521 acaaataaaa acataataac caatctgcac acacatggat gtttccaaac agcctgagca
     2581 agagttctga ctcttggggg aatcttggaa agacacaaaa agggtaatgg ctcttgtatt
     2641 ttaaaattat tcgaagaaaa ttctatttgc tatgatttac tccagcaata agttggaccc
     2701 caaacactac agtgtacaaa aaaaaaaaaa aaaagctggg gaggtgggag agagagagag
     2761 aaatacaaaa gaaatggggt cgttgtttcc cagttgaata ttcagagcaa cagattctgg
     2821 ctggtgttct gctggaaaac tgctgtatgc ccacatagac ttttcaactt tgctgttatt
     2881 gtatcttgtg tgcgtgcgtg tgtgtgtgtg tgtgtgtgtg tgtgtgtgtg tgtgtgtgtg
     2941 tgtgtatgtc tgtatgtctg tatgtctgtg tgtctgtgtg tccatgtgtg tgtgagcatg
     3001 tgtgtctgta tgtgtgcata tgcgtgtgca tgtatgtctg tatgtgtatc tctatgtgtg
     3061 tttgtatgtg tgtgtctggg tatgtgtgta tgcatgtgtg tgtctatatg tgtgcatatt
     3121 catgtgcatg tgtgtcggtg tgtttgtctg tatgtgtttg tgtgtgtgtg tgtgcttcca
     3181 tgtttgcata tgtgtgtgca tatgtctttg tgtgtgtgtt tgtgtgtgtg tgtgtgtgtg
     3241 tgtgtgtgtg tgtgtgtgtg tgtgtgaccc agtaaatgtc attaaagttg tttacaggca
     3301 tatgggcacc ttgccaatag ctacacttcc gatagcaaag tctccccctc ccttattaac
     3361 aatcctcctg agggggtgga cacccatgag ccctctttct tgtgtgatga ggtgctgacg
     3421 ggcccaatcc tctacaaatc tttcttacta gggaaatcac aactgtgatt tccaagaatg
     3481 tcttaatcag aaactggaac ccgcacagag caggcttgcg ttttctgtat aacattagaa
     3541 cagggactct ccatttttca tcattgaaaa tcaatgtgac gagtcattgc aacaaacatt
     3601 tttgcaagca aagacatatg gccaagagga tgtactgagg gacacacagt gacacaccgc
     3661 agcttcagat gtgtgaccaa gagggtatac tgagggacac agtgacacac tacagcttcc
     3721 acaacaaaat ttgtggaata caaaaagtca taatgagtgt catcattagg cataattaaa
     3781 atgtgctagt gatttgtttt aaatatttaa aaaagcttag gaagagaaag agatcatttt
     3841 ctactgaaaa gcaatcagcc ctttttctag aatgcactag atcctttgga caaaaatcaa
     3901 ataatcttgc aagagggaaa aataaaactg tccttcagaa tataaaaata tttacagatt
     3961 ttttttttac ccctttgcac tctgtgacct gaaagatgaa aagaaggttc tgatccaaac
     4021 caaaacctgc ctgtggtttt ctccaagctg gactgagttt cttacagtgg ccactgggaa
     4081 gcttcaaagc ccggcttcag gtctgtgcct gcctggcgtg cacacactta acaatttaaa
     4141 caatactgtg atttatctcc tcacactgaa gcaaacacac attacttgta gaggctaagc
     4201 aagaactggg tggggtgagt tacagttgta gactttaagc ttttgaactg gccctatgtg
     4261 ctctacagag tcatcccagt gtctttcttg aagagcctct ggctttccca cagctttccc
     4321 accaggcggc cccacacaac agcttcttac ctacctaagg ctctgctcct tagggtgccc
     4381 cagatgcgct catagaaaat tggtgtagtg ccctcattgt ggtctcaatt gcaaaacaga
     4441 caccttagga gatagcagtt caccaaagag gcctctggat ggactccatt tggtggcttc
     4501 actccttcct ttgttgtcac acttcatcct tgtctggcat tttagaacct gtagctcttt
     4561 ggaaaggctg ggctggaaga cttgctcctt cctgaagggt atgggatgca aatctccttc
     4621 ctcaccagca gtttctctca aagcttaact ggggcgtgtt caggacataa cttcttatgt
     4681 cttctgatgt ctcaactcta gagagaaaag cctaaacttg gaaaagcaga gcccccatac
     4741 acacatagat aggccagtct catgaagacc cacccacatg tgtttgaaag cgcaggacac
     4801 tgatgcatct cttaaatcag gatggatgcc tgtatcctgc tcatttcatt agtctatact
     4861 gtatgagcta gagattaggg gaccacatcc agagaaggca cacagaaggc aatggcactt
     4921 aagactaagc ctgtcgatga tagctcagtg gttagggtgt tcggctacct tgtacaaggc
     4981 cctaggttta gttcccagaa ctgatggtgt gcatgtctgt tatctcagcc ctcgggaggt
     5041 ggaggcagag gatctgaagt tcaaagtcat gcttagttag atagtgtcct taggaagcgt
     5101 caaaactcaa tagctgagtg cttgcctgtg gtaggtgagg accaggttca ttccccaaca
     5161 tcgcaaaaaa tagattaagt aaacataaca gcaaccattt gctagtaatc ccaaatcact
     5221 tttgttttgt tttaaatttc tagcgcaaat ctttaatata atggtttccc tttattacac
     5281 atagaaatat aaaaacgtgc tatggatctc tgcattttct aaaactcaaa tgctttttta
     5341 aaaggtcatc gtttatgtta cgtgcatgag tattggcctg catgatgtat gcgtgctgtg
     5401 tgcttgtgtg cccgtggaag ccggaagagg gtgtctgatc ccctgaaact gaaattacat
     5461 gtggttgtga gcggctacgc agatgctagg gaccaaacca ggatcctgtg caggagcagc
     5521 aaatgttctc agccaatgaa ccatctccat ggcccctcaa atgcttttta aactaaatct
     5581 tattgatgtt tttttttttc atttaaaaaa aatccatgta aaatactaaa agagatctgt
     5641 gtacccagta accctaattt ccccaccctc cctccgccac tctttattgc ttggaaaaat
     5701 ggaatctggt atcagcttct tcgattcacg tccctgttaa aaatctccct gtgatgaaca
     5761 agcctccgcc cgtctcggca ccctataaca tgttccataa tgaccgcttc tgaagattca
     5821 tctacctctg tgacctgaaa gccaagacta aggtcacgga gtccgaggtt gggtctggcc
     5881 cacgtgatca agcaagagac caggcatgtc ggctccccat cctatcccgc tgctggctta
     5941 gatcatcatg gttcaaatca cggggagaat tagaactggc cattctaccg gtcaatatgt
     6001 gaacagtgtc taagctggac tccgagtgtg agtagctgtt tttcctgctc attagtcaca
     6061 aaatgtcaat gtttatgtga ctgcagttgg aatccagagg caccagattg accaaaactt
     6121 tcctttctca acattacagt tttgtacaca acttacatga aagcgtaact gcggtcgctc
     6181 gcacattggc tgcaaaacaa tgttttcctt gacagcaatt agggttttgc ccaaagatct
     6241 gccagcctga aacaacattt aaagacatat ttttttaatt aaggaaagaa aattactatt
     6301 aatgaagcga tgaaaccaca tgctaagacc agaaaaccta tgttacgttt cagctaaaat
     6361 gtgtcttgct ggtttctaca ttaggataac agtatcgagt tgttcagtta acacatttac
     6421 aatcaaaagt gtgttgaact tgaaaagcct ttgtttgcaa gatatacact gcaccatctt
     6481 cttctatagg aacaatgaca acaaaataca gtcatcctta aaacatccat gacagaatag
     6541 gaatccactg agctagcaag accaaatcag gaagccttta agatgctatt ttcccccact
     6601 gtgtacgcac ctaaagaaaa gctcacttag ccactggcac aactgatgcc atgtgtatga
     6661 catctctaag gatctgcaga gctcacctgg gaagctggaa agcatctaaa acaaaaatct
     6721 cttgtctcta cctggcttta cgggacctaa gctgctggca ataaaagagg tcaagttcta
     6781 gaacaaatta gatatttaaa attaagccaa ctctaggtag acatggcggc acaagcctgt
     6841 aattgtagca tcttaggaga ggcaggagga tcagggttac aaatggtact tggatagctt
     6901 gaggccacct ggattacgtg agaccctgtg atgaaaataa ataataatct gtcaaacaaa
     6961 aaggatggaa atattgcatt gccataaccc acggtgatgt ctctaaggac cgtgggaact
     7021 gggaaaaaat ttgtcttaga gcctagagaa gctgcaagaa aaacagaagg gaaaattaag
     7081 tagacgtgtg tgtaagattc cagagaatgt ggaaactatg aggtgtggat ccctgcctac
     7141 cagtgtccag ctcagctcca gttgtatttc cgtgggttgc cctatgtctt agcaacggtc
     7201 tgacttcctt gtctgtatcc tggagaccct cgacttcatg cacaattggc agctaattgt
     7261 attaggagtt aacatcttac ttaggggtgt gtgtgtgtgt gtgtgtgtgt gtgtgtgtgt
     7321 gtgtgtgtgt gtgtatcata attttctcac ctcttccagt ctggtgtccc ctgctttttc
     7381 cttactgctg ggcctgttgt aggtggagga ggggactctc tctcctggca cagccttgaa
     7441 cttagtttgt gggaaagaat tgagaataaa catacacttc tcttgggtct gggtttctcg
     7501 aagttcctaa aataattcac ctatgcacac acataaagtt caaaaccttc cctgcaagtg
     7561 acgctgcaga tgctcacgta agacaggtcc agtcctgtgc tctcccaacc atcgcctcca
     7621 tcctgtttcc tatggatgag cccactcact gtatccctga aggaggtcct ccctgtgtct
     7681 agggagagga ggaagcgcct gcttcacatt gttttcagtt gctgagtact tcggactggg
     7741 aaagttatca agaaggaaga ggttttgtag gcagagtctt gtgtaggctg agaaaggtgt
     7801 aaccatgcct ggttttacac cagttctgag gggtgaactc agaggctcat gaatgctaac
     7861 agagcatcct tccaactcgg ccacatcctc ggcctcaata agggagacca aagaactcag
     7921 ggtgaaaagc acttgccacc aagaccgatg acctgggcca tcagagtgga ggaagaagac
     7981 ccattccttt acattgtcct gactgccaac acgctagctg tgcatctccc taggttttaa
     8041 caattttttt taaagtaaag atttatttag cacatggctt tgcagagtgg gattcccaat
     8101 ccctactaag gccttcttcc cgcttctcaa catagcagag gtgtcacttg gctggaacac
     8161 ggagctacaa ggcctacatc gttccaggct ctgttatgtc cagctgtagc acggagagtg
     8221 ttttacagga agacagtgag cgttttaact ccatgagagc tgttcgcagg ataacaccca
     8281 cccacccttg caaggctctg gggacttcgc agagacgggt ggcagaacag gaagggttgg
     8341 agtcatggag taccaaggta taacagtgac cactggaagc ggcagcacct ctgtcttctg
     8401 gaacccacag cagctctggt ctccggcaca aggctaagcc aacgagcatt ctaacatgga
     8461 gtggagagtc ttatgagtcc ccaccctaaa tgagacgcta tcgatggcca atggcttctg
     8521 ggaaggcaga ctattcttct ttaggtgggt gtcccctgga cggtcaagca cactcctgtg
     8581 gatggccccg aacccatgag tatatgggta gcacacatgg acttggtggg atatttgtaa
     8641 aaaggatgca aagttgggag aggccggggg aggtgggatg cagactcagg aggagctggg
     8701 ggaggggcgg aaaagcaata tgatcagaat ggactgcata agatcttcaa ggagctgata
     8761 aacatattat agtgttcaga ggtctgtcca gaataaagga atgtatgggg aggatgagca
     8821 gcactgggta ctgacatttc accacagtcc ctccctccct cccttgttca ttcattcatt
     8881 cattcattca ttcattcatt caacaaacac ttctccagct gttgtagggc tcaggtacag
     8941 cctaagatgc tttcttgata gggcagagag tggattgatt cacagtcacc gcggtagctg
     9001 acagcttcac tcacttctct gaggatgttg acggtaaatg ataactgaga gttacaaagt
     9061 acaggcagct taaaaatgat ttgactgtcg aatacggggc ctctaccaaa ctcctctcct
     9121 ggcaacagca cggatttcta gcagtaagat gcctcgtcga taaaaccgac acacgggtga
     9181 gagttcaaga tctcaacagg agctgctgag aatcgagtag ggctatacaa gcatctccca
     9241 cccctaaact ctaggcaaga ccctcccagt gactaaacta cttaatgtaa ggcctgaaaa
     9301 aaaatcacac tgaaaaacac tttccttttc ctcctgcaac acacaacaca gggaatcaca
     9361 ttaaatgtta tcaaagttcc tgctgccctc tactggtcta agtctagaag tggcattcac
     9421 agtaagaatg ttagcgaacg ctgcccaaac aataattaca aactgacacc actcatttcg
     9481 agcttgggga gacagtggag tatgaaggac aggagagtaa gtaactcgtt caatttccca
     9541 aaacctcacc tcagtagcca catctaggga gtgaaagtta aggtgactct ttcgggactg
     9601 gagaggtggc acagatgtta acagcactta ctgctcttgc agagaacctg agttcaattc
     9661 ccacacagag aggttcacac ctacctatca aacctgaggg tgtgggttca cagccaccta
     9721 tcaaacctga agatgcgatg ccctcctctg acctccacag gcaccaggca cacatgtggc
     9781 aaacagatac atgaaagcaa aacattcatc caataaaaat gaagataaaa ggttctaaat
     9841 gtctctactc ctgactctct tgcaggctga gaaaacaagc ataaagccaa acagaagagg
     9901 tgcccagcag agtctctcac gaaagcagga gtctgacctc gctaaccttc ctgagtctgt
     9961 gaggcccagc aagatgtctc accttaaagc tagcttagcc agtgtgtgaa tgagtgagga
    10021 gcacggtggt aacgctcaga ttctaactcc agttcttgcc atgcctccaa tacccaggag
    10081 cagctggtaa tggggaatct aagaatttca aacatcttaa gaggccattt caaacatcgc
    10141 tggtggctgc cattaaacct aaatatacac attcatatct cagcggtcag ttctctcgat
    10201 tatgtcttca agcatacaga aaacacactc aggctcgtgc tgcaagcatg tccgagagtt
    10261 agcaacgata gtccaaaacg gaacattaaa gggaaggcac tcagtggtcc cttagcagga
    10321 gcacctaatg aaagactatt atacaaccgc aaaacctaag tcctgcatgt cggcctcaag
    10381 ggcattacgc tgagtgggga aaggttaaaa aacatcaaca ccctgtgtgc tttgtttatc
    10441 caatatcctt caagtgacaa atctgcaggg gcaatgggaa aacagttatt tctagagatt
    10501 aggggtggca gggaggagag agaagccatg actcctagag gtcacaaggt cacgattagg
    10561 tttatgtagt gatatgtagt tttccatttt tcttatattt tatttatttg tctatttatt
    10621 tgtgtgtgag agagagggtg ttctgcctgc ttgcaagtct acgcagcaca tgtgtacctt
    10681 ttgtctgtgg agactggatg aggatataag accccctgta gctggagtta cagttcactg
    10741 tgagctgccg tgtgggtgct gggagtcaaa cccagctcct ctgtgagggt ggcaaaccgt
    10801 cttacccact gagccatctc tccagcccct ggatttacat ctttatagtg gccgagtgcg
    10861 tctcctaaag gctctgcaag tgatgaaagg cgacagacgt gcacacgttc cattccacca
    10921 gaatctgtct cctggctgtc atactgtgtc atggttcatg agacacagct acaggaaaga
    10981 actgtgtgtg gcagagcaca caggcttcac tgtgccgggt caaatccatg gccagttcaa
    11041 attgctgtta ggttaaaggt aagtttaaga cttacagagc cgctggctgt ggcgacaaac
    11101 acctttaatc agagcactca gggagcaggg gcagcatatc tctgtaacac tgaggccagt
    11161 ctacacaaac tgttccaggc tagccaaggc tacagagtta gactcggtca caaagaaggg
    11221 gggagggagg aagaagaaaa gaagggaaga aagagaaaaa tgaaccacag agtaaaatct
    11281 tatttaaaag ccatttttaa agtccattaa gaaactggct gagtttcacc tcctcgcggt
    11341 acattctcta tgcttgccct tgcctaatcc tcgctagttc cgatgtctcc acctatgcac
    11401 ctattctgat cctgagcagc tagtcaattt tgtcaagtat taggtattag tgggaaacag
    11461 taaacatggc tttatcttaa gtttggagct cttgagcaca tctgtaatcc cagcactcct
    11521 gagacaggga cagagaatca agaattcaag gcaagttcga gctacacaca cacacacaca
    11581 cacacacaca cacacacaca cacacacaca cattaatagt aaatgttaca gtgctggctg
    11641 ctgatgcagc tgcattggtc gagtgcttgt ctagcataaa ggcctggcag tctgaccccc
    11701 cagtaccata gaaacaggtt atgatggctt acccctgcta ttccagtacc caggagatag
    11761 agacagagga tcaaagattg agtgtcagcc tcagttccat attgagttca aaaccagcct
    11821 cggatatatg agacactatc ttgaaaaaaa cccttgaaaa attaatcatt agggctggaa
    11881 agacggctct gctgggaagg cactggccat gcagctcaca ggaactcatc aggcagagca
    11941 acaacagaac aaacgcagca cgcgcctgca gtcctagtat ggggacgcag acacggggct
    12001 tctcaatcca ctaccaaatc tgtgagctcc aggttcactg aaagcccgga tcaaaaacta
    12061 aggtggagag tgaggggtag gaagacactc aagttgaaca cacacacaag cacacacaca
    12121 cacacacaca cttgtgagaa acaaacaaat aaataaataa aacattaatg ggaaacaaac
    12181 agtatacaaa gtcttgtgat ttcacttctg ctctgtgtgt gtgtgtgtgt gtgtgtgtgt
    12241 gtgtgtgtgt gtgtgttgtg ggtataaagc caaaatgtaa atcaaaatag tggctttctc
    12301 caagcaatca ttttgaataa ttagcgttcc ttcttttatg cttctatgac ttgggaaact
    12361 tcagacagac caatatttaa cgtggtaaaa agaaagcagg accacaattc ccaagaacgg
    12421 aatttggttc ttgtcacagt tagataagag gcagggaaca taaacaacgt ctgcgagcca
    12481 gcagactctg aaaggtcggg agtagtggaa ggacagccag acttgagcag gaaatgtggt
    12541 taacagtgga aagtcggact taactcctgc ctgcgggcct cattgcagat tacaatagat
    12601 agaaaacctg aagctctcaa aagaaataaa cattcaaagc tgtgactcca acagcccccg
    12661 tctctgaacg gggatgtttc aaacacaccg tggagaggca gcaaagaaca cacaacatta
    12721 aaagcctgtg ctgctggagg gcaatcattc cagggcaggg ctatcagcac tgccagatga
    12781 gcctgacaca ggtccacctt aagatcgcat ctccccagct gcgcttcatg tgccactgca
    12841 gtggctcaca gggaaagcct ggggctgcag ataatgggac ttggcccgag tactcctgga
    12901 gcatgccttt tcttgtcgat ctgggaaagg caaggctgaa ctgcacagcc tgaccctgaa
    12961 cagacccttg gcattcccct gcatgccgac tagacagaga gacggttttt gccttcttta
    13021 cactgaaaac cattctgtgc cgcgcacatc tggccctttc gcggagactt caacactgca
    13081 aaggcgctag acttctacct tggaggaaac tgtcggttgt tgaggttgtt gatattcaac
    13141 agaagtcaca gttgcggcag gagcagaacc tcagacacag ccggaaaaga aaatgccaaa
    13201 ggaggactct agagcgtatt ctgggacgag gctttcagaa taaagaagtg ttgctgacac
    13261 aaaccaccaa gctgcccact gaccagtaga tctaagagaa cgtgtctacc aagtgctaca
    13321 gacaggagga tggcgctgtg gcttccagga gggcagctca ccctgctgct actgctctgg
    13381 gtccagcaga cacccgcggg gagcactgag gtaggggcta tcgaaaagtt ggtctctcat
    13441 gatcaacgat gcaccaacag gctattcacc tgggggccac ctaattgcta agaacttagc
    13501 cactggcaat ctaagaataa acaatgttag taaagagtga cagggaaaat tgctataaaa
    13561 attaaaaatt tttaagtcat aaatctggca taattgatgt gagtgccatt gagttatttt
    13621 cccgattctt ttaagtatta aagcaatgat tccaccgggg caataatgta gactaacctg
    13681 tttaactcaa aaccgcttta tacagatagc acacatttgg agtatcctaa ttttaaatat
    13741 ctataaacta aaaataagct aatgataatg ggtgacacag gaaacatttg agatctggag
    13801 acatgttaaa aatgtgtcag agttcatttt gatatttgac agaatgtgat tcttggcttg
    13861 gattaatgga agcttgtttt aaaatctggt gcactggttc acatcatcca atcagtctgt
    13921 aaaattgact ctagattgta tgtaactaga cagcatgaca tcataaatca cacggttaaa
    13981 ataccaaacc gtgtgttctc tagctccgcc cccaacaacg ctggccttgg gcagaatctt
    14041 gccttttggt gagtgctgct catgagaaaa gcatcgttgt tttgcccaga aatggttgag
    14101 tgtaggtgat gctgatacag ttctcactaa cgagctgacc gaagccaggg agcctccttt
    14161 cggcaccctc tagacaacat tcaactgttt ccccacctcc aagaggggtg tactttccag
    14221 cccctcgctc accaagagga ggtgctccca ggcacggccc cactgctccc ctgaaacgct
    14281 gtttctcgag ctttggaagc gcagctgcat gcacgggttc tgccctgctc tccaccctgg
    14341 agcctggcta gtcttatgtc tgtggcataa gtgcttctcc cccaagacaa gctgttacct
    14401 gagaggtctc agtcctgcac tgccagtagc tggagagaca agtctgacag gctctggaat
    14461 ttactcttag tccaactttc caccagatcc agaggtgtgt gtgcacccgg gggctaattg
    14521 aggaagaagg tgacacttca gcttccttgt ttgctttagg ttttttcccc tcctttttgt
    14581 cctagaatct aagtcagcaa gaaggttttt atttacagaa gtctctcttg gaaaacctaa
    14641 cgctagatgt acgatagggt ggctggaaag atggcttggt ggttaacggg gcttgatgca
    14701 caagggtgag gacctgagtt cgggtcccca gaatgcacat aaaacccagg agtggaggaa
    14761 tgcacatctg gaagcctagc ttgggcagtg agaaaaagtt gcagagacgg gccgatccct
    14821 gttgctccag agatcactag ccaaccactc agctaaactg caaagctctt ggcttagggc
    14881 atgaccttgt ctcaaaaaat aaagtggaga gtaatggagc aagacctatg tcattgacct
    14941 ctggcttctc tgtgcatgca cacacatagc aaaatgtaca gttaaaatta tatgtatgaa
    15001 tataagcttg ctttagtttt agtttggtta ggctgagaca gagcccccca ttgcaatgca
    15061 ggccagcctt gaactcacaa gccttctcag actcacagca cctcttgtat ttcggccttc
    15121 taaggacgat aagcataagc cacccccccc cccagctctg agcatgcttt atgacatgca
    15181 tgagagaata ggaggaggaa gaaactgaag aagtggaaag tagataaacc agaaggttag
    15241 tgctttattg tcaacagact caaatatgga aacaccatga gttctaaggt aaagaacact
    15301 tcctccctgg ggagatgagc cttggagttt tctgtgccat ttatgaataa taacaacccc
    15361 agaccaggta ggaatagcat ggagtcatta tagtgggcac agcttgagca ttccgtgtaa
    15421 aatacttcag ccagctctgt tgggcacaaa aatctgcaac cttgtttcca tctgatctga
    15481 ataatgtaaa tcgaggtttc ttttcctcat aggctcctct taaggtcgac gtggacttga
    15541 cacctgattc ctttgatgat caataccaag gctgtagcga acagatggtg gaggagctaa
    15601 atcaaggaga ctatttcata aaggaagtag atactcataa gtattactcc agagcatggc
    15661 aaaaagccca cctaacctgg ctgaaccagg caaaggccct cccggagagc atgaccccgg
    15721 tgcatgctgt ggccattgtg gttttcaccc tgaatctcaa tgtgagctct gacttggcca
    15781 aggccatggc cagggctgcg ggatctcctg ggcagtacag tcagtcattc cacttcaagt
    15841 atctgcacta ctacctcacc tcagccatcc agctgctgag gaaagacagc tctacaaaga
    15901 acggcagtct gtgttacaag gtgtaccacg ggatgaagga tgtgagcatt ggagccaacg
    15961 taggttccac cattcgattc ggccagttcc tctctgcctc cctgctaaag gaagagacac
    16021 gggtgtctgg aaaccaaacc ctgtttacca ttttcacttg tctgggtgcc tctgtgcaag
    16081 acttctctct caggaaggaa gtcttgatcc ccccctatga gttatttgaa gtcgtaagta
    16141 agagcggcag ccccaaagga gatttgataa acttgcggtc tgctgggaac atgagcacgt
    16201 ataactgcca gctgctaaaa ggtgagcttg ctctaaattg ggtctgtaca tagaagagtc
    16261 agaaatcaat cttcatttat agaagggttt tctttttctt tttctttttc tctttctttt
    16321 tctttttcgt tttctttttc cttttctttt tctttttctt cctttttctt tttctgagtg
    16381 ggctaggagt agggagttga aaacagggaa acctgtcccc agtaatgatg gaactgacca
    16441 cctaagttta cgttctgctt catgtccctc cctcttctac ctttaaaaaa aaaaaaagag
    16501 tctctgaagt ggtactgtat taggtcctta tccactgggc tatgttccag caacccagaa
    16561 gttggttgca aacctaggta ctaccaaact ctacaaaatg atgtttcttt cctatatata
    16621 catacctgtg gtaccactga atttataata agccaaaagt attttaaacg ttcactctcc
    16681 ccatcccaca atatcttatt gtaacttacc cccctctcct tgctataacg tgactcaata
    16741 ccatttgtgt gtcatgagaa gacgtgaggg aatggcctgg gcaggcaaca tatacagtgt
    16801 ggaaacatgg gacgaaagta tgattggcag cccactcggg acggaccaca agatttcatc
    16861 ttgctatgca gaatgagatc caatctagtt tatgagtggt gacatttctg aaatacttca
    16921 tgtacaattt tcagagcaca cttgactaaa aatcaagtca taaaaaagta aaattgatga
    16981 ttttatattc cttattctat agaaaacaca gatttttaat aagctttgat tgttgcccag
    17041 gttccaagta ccaaggagct ggaccataga gaagtaaggc aagagctcaa actggtagca
    17101 aaagaagatt caagggagga aatatgagaa ggaaaagtta aattattcta cactgcccta
    17161 tctcccctgt aattattttg ttgcccccca catgacctat actggttacc atagtaacat
    17221 gttttcatgt ttcctaaaag attcaaagta tgccaactaa tgttaatttg tttttctccc
    17281 ttaagtggtt tctttcagca aaacaatatg tgccaaacac acacacacac acacacacac
    17341 acacacacag acacacacac acacacacac acacacaatc tgctctttat agctgcattt
    17401 acaaagaagg atttatgtca aaatatttca gatcatcaaa attcttggca tgctttctag
    17461 aaaaaaaaaa cacaggcagc tgtttgtagc agcttagttt tacctgtgac ctttgccagt
    17521 gacaaaccat ggtattgtgg ccttggggga ggggcttagc ctctgggcct gttgcttccc
    17581 atgagagggg gtcagcagca atgaggcctg tgaggaggcc tgaagccctg agctgcttcc
    17641 tctgctgatg aaagagaagc aatgtctgct tggggaaatg acgcagcaga acctaggcga
    17701 gcactacctg ctcaaacaga agcaagaaac tgggaaggcc tctgcaaggg aaagagggat
    17761 aatggcttag cagtgtagcc gtgggcttta gtgagacaga cagagaggac agagacagac
    17821 acaggagctc cactacaggt ccagtgccca ctttttcctg gggaatcttc taaagattaa
    17881 caggaaggaa aagctacttt aacctggtag ggcggcatta aaaaatacat aattggggcc
    17941 tggagagatg gctcattagt caagaacatg tactggttgg tacttggcaa agggcctgag
    18001 ttcggtctcc agaacacaaa acaaccagcc acaactagtt ttcagtccag gcccagagac
    18061 tgaagcatcc agcttcctca ggtacctggc ctcacggtgg ggaactgctc agtggagacc
    18121 tctgtcctcg ggggacttcc acttcagtgt ggggagacaa cccagagtga gagaaccaaa
    18181 tggaccatag aggaggaggt ggaggctacc acagaataga attgagatag accaggggct
    18241 aggagatgct gtgtgaggcg gttgcagtat taatgtggtc attaaggaaa gcaccagggg
    18301 ttacactgag taaagggggc gggaggagag ttagtcatag aagaatctaa ggaaagagcc
    18361 tcccaaggag gactcagcct ctgcctgcac acacctgtga cacttactga caagcctctg
    18421 cctgcacaca cctgtgacac ttactgacaa gcctctgcct gcacacacct gtgacactga
    18481 cacacctcta cctacacaca cctgtgacac cgacatgcct gtctgcacac acctgtgaca
    18541 ccgacatgcc tgtctgcaca cacctgtgac actgtcacac ctctgcctgc acacacctgt
    18601 gacaccgaca tgcctctgcc tgcaagcacc tctgacaccg acacccctct gcctgcacac
    18661 acttctgaca ctgacatgcc tctgcctgca catacctgtg acaccgacat gcctgtctgc
    18721 acacacctgt gacactgtca cgcctctgcc tgcacacacc tgtgacaccg acatgcctct
    18781 gcctgcaagc acctctgaca ccaacacccc tctgcttgca cacacctgtg acactgcctc
    18841 tgcctgcaca cacctgtgac attgacacac ctgtctgcac acacctgtga caccaacatg
    18901 cctctgcctg cacacacctg tgacaccaac acccctctgc ctgcacacac ctgtgacacc
    18961 aacacccctc tgcctgcaca catctgtgac actgcctctg cttgcacaca cctgtgacac
    19021 tgacacccct ctgcctgcac acacctgtga cactgacacc cctctgcctg cacacacctg
    19081 tggcactgac acccctctgc ctgcacacac ctgtgacact gcctctgcct gcacacacct
    19141 gtgacattga cacacctgtc tgcacacacc tgtgacacca acatgcctct gcctgcacac
    19201 acctgtgaca ccaacacccc tctgcctgta cacatctgtg acactgcctc tgcttgcaca
    19261 tacctgtgac actgacaccc ctctgccagc acacacctgt gacactgaca cccctctgcc
    19321 tgcacacacc tgtggcactg acacccctct gcctgcacac acctgtgaca ctgcctctgc
    19381 ctgcacacac ctgtgacact gacacgcctg tgcctgtaca cacctgtggc actgacaccc
    19441 ctctgcctgc acacacctgt gacactgcct ctgcttgcac acacttgtga cactgacatg
    19501 cctctgcctg cacacacctg tgacactgtc atgcctctgc ctgaacacac aaaagccagt
    19561 aaacacattt aaaaaaaaaa acatcaagtg tcatgacaca catctacaaa cctagcacta
    19621 aaggggacag gaagagacag gtggaaccct agcctaaatg gccgaccatt atagtcaatc
    19681 agttagctcc agggccaggg agagactgtc tcaaaaaata aagtggagag tgatagagaa
    19741 aaaccctcaa tgacctatgg cctccacatg tatgtgcaga caggcacatg tgcactttta
    19801 cacatgctca catagaaact ttatacacac atttttaatg ccaagggcta aaagcagatc
    19861 cagaataacc atcaaacatt agctttcatg gcagtggtga aaatgatgat aaagataggg
    19921 acgagggagt agagtcaaga tgatgatgat gaccatgacg acgatgatgc caggacagct
    19981 gagcaagtct ctggacctct ccctgtgcct ctctctagtc tcgttatatg gacaataact
    20041 tgagctctca gccaggaaac ctaagaggat gctgctgggt tcctgttctt gataacatga
    20101 cagttcctta agggacaaat ggtttatttg ggctcatgct tgaggagacg cagttcatcc
    20161 cagtggggaa ggccctgggg caggagcata acgctgcttc tcagggtgag gccacaggaa
    20221 acaggaagca gacaagaaac agggtcccct ccagtgagta agtctcccac cctggctgca
    20281 cctagacagg ggcagcacac agcaccacca gcaggagcag agacttgctt gagtttgggt
    20341 ttttataagt aactgatgtg aaaggtttca atgagagagt cgttgtgtta tgttgaacca
    20401 gggaagaaat gagctagttt ccaaagaaaa ttctctgctg ctggggctgg tgacatggcc
    20461 catgagttaa gagccactgc aacttctgca gaggaatatg gttcagtccc cagcacacat
    20521 taggtggctc acaactgccc atatgcctac actcggttat ttcaaagcaa aaggcagagg
    20581 caaaggcagg tggatctctg tgagttagag actacctgtc tatatagtaa gttgcagacc
    20641 agccaggact acagagtgag actcaattca aagatacaaa catacataca tacatacata
    20701 catacataca tacatacata catacatacc tctgatgcac tgcctcacta tgtagccctg
    20761 gctggtcttg aactcacaga gaaccccttg cttctggcac ctaagtggga ggactgaagc
    20821 cctgtcacgg tgccccctct gccacccagc tcatctctaa gttgtgtctt ctttgttttt
    20881 cacagcttgc agcaagaagt gcgcccctgc tccagtggtt atcggctgcc tctttttggt
    20941 cactgttgtt atctcgtcca aaagcagagc gcaaaggaat ctactggctc ctttttaaag
    21001 gagctgctta aatttgatgc tcctatttgt gttaccaaag tctgaggccc acacttccca
    21061 caataccaca gaagatgtgc aagaaaagtt catggggggg gagagggggc ggggacaacc
    21121 ctaagttcaa atctaggcct aaataaggca gaagactgtc agaaatccct gcctaaaagg
    21181 atttaggcta ctttttcctg ttgctgtcag caaaaccaat cacagaagct caaacaaagt
    21241 tcaggatgaa agctttgctt ccacttataa acttacagaa catcgtagac cagaagtgtt
    21301 tggtcccagc agcaccaggc actacagaag cagataccag gcagactatc aaatctcaag
    21361 gcctgcccct tgtgactcac ttcctccagc aaggctccac ctccggaaga ctctacagcc
    21421 acgaaaaata acaccaccag aaggagacaa agatctcaac acatgaggca catttaacct
    21481 tcaaaccaca gcaaggtctt agtgttcagc gctctcttcc aggagaggag atgggagtcc
    21541 tgacagacaa gggcagaaca tccctgctct gtgaaggttt ttcctaccca gacccgtctt
    21601 tgctctgccc tcctcaggaa cctcacaaag gaccactctc ctgcagccag ccaaccagaa
    21661 ctgaaaaggg ccttcagcac actgctactg aaagccatgc atggcgtctt ccttgcctgt
    21721 ccatttgccc ttcccagtct cagggccttg gtcttattca gtgaagacac ccaaggatac
    21781 cacttgccca ttacttggcc agagatccat gacaaaatga caatcttgtg gcagcatatg
    21841 agacagaatt aggatacgtt ttctagatta gttttgggag cgcagcattc agaatctatt
    21901 gtgagtgatt ataaaagctg agcacatggc acgctgcgtt gcctgtagct gcctcgccac
    21961 caagagataa gaatttgcct ccctaagaaa ctaattcagt ggaggcagtg ctaagaaaca
    22021 gagagaagat aggcaagatg agcctctagc gccaaactgg gcctgaacca gatagtcagc
    22081 ttcatcattt tcatggatta ataaatgata tctgtgctaa cgaagggtgg ctgtgttttc
    22141 tatctcaagc actcggagag gtgcaggtga gtacagactt gcgctgtttg cttttcaaac
    22201 tagtgactaa gtagtaacag atcaaagagg agccagtaga gaggcgaacg atctttctcc
    22261 agagattttt ttattggctt tcaagatcag atcaatgtgc tcacaaagca gaaggcacgt
    22321 ggaaaccaga gagagaaaaa aatgggatgt attagtgtgg gaattcttag gcagtggaga
    22381 gagacagaaa aagagcctga ttgcaacaga cctggttgtt tattccagaa cagggtggga
    22441 cagacactct cccgagggaa aggggtgcct gtgtccagca aagtctcttc ctgggggtgg
    22501 agtgagggta ttgcctgtac ccataatgga tagagcagtt ccaaagtctc tctctctctg
    22561 tgagcttagg atgccgccag ggggcagcac tgaggtgcca ggtgcaggac agatgattaa
    22621 ctgccccttg tgtggccaca gaagccagca cctctggctc tctgttcttt ctggcctccc
    22681 tctctgagac aggctgcccc agcaaggtca ttggtaggca ccctgtctta tgaccaaggc
    22741 attctatcag ttagtaaaaa cttcatccat gcctgtaaca agctcctaca tgcatatccc
    22801 ccagaataat attaaacatt ggaatttagg cacgtttcct tattgactag atggaaacct
    22861 ttatttcaaa tttgtataga aaagtatctg ttgtcagggg aggatgtgtg tggaagtcaa
    22921 ggtgagaatg tggaaaagct gaacatcact gaccaccaaa atagttgagc ttcattgtgc
    22981 actaggagat gcagactata aactaccaaa gttcagacct ggaaacattt tccacccttt
    23041 ccctcaggaa gtgcacagtg taaatgcaga cctgatcgcc aaaggccctg ccactcaggt
    23101 acgtggaggg aggagtctgg ggcaactttg agcttctgag ctgtgactac atgggccatt
    23161 cttggcccct tgaagaatga gatttaaaaa aaagtagcag acttggaaac caacccctgt
    23221 gcaccagaga gaggggctgt gctacaattc aagcaacaga atggatagct agcgatgtta
    23281 accacctgct ggataccagg gctgtcttag gtagggtttc tattgctgca acaaagcaca
    23341 gtgaccaaag caacttgaag aggaaagggt ttattcggct tactcttcca cagcactgtt
    23401 catcatcaaa ggaagtcagg acaggaactc acccagggca ggatcctgga ggaaggagct
    23461 gatgcagagg ccatggagga gtgctgctta ctggcctggt agaatttact cggtttgctt
    23521 tcttatagaa tccaggacca tgagcctagg gatggcatga ctcagtctgg gccctcaccc
    23581 atcaatcact taagaaaatg cactacaggc ttgcctacag cccaacctta ttaaggcatg
    23641 gtttttaaat tgaggttccc tcctcggata catatatgtg tgtgtgtata catatacata
    23701 tacatataca tatacacata cacatacaca tacacataca catacacata cacatacaca
    23761 tacacataca catacacata cacatataca tacatgcata tatatattac tatccagcac
    23821 agagaacaag aatttccaca aataattcct gtcaagcttt gcatatatat attactatcc
    23881 agcacagaga acaagaattt ccacaaataa ttcctgtcaa gctttgcata gggtctttgg
    23941 tagctatctg tgggacatct ttgcagtgag ccctggaaag gtaacagtga aatgacattg
    24001 caggaaaaga agccacccaa catctggcat atagttggtt ttttgtgcca tataaattca
    24061 cttattgatc tgtgtgatat gcaaagtatc ttgggcatta gaagttgaga atagggtggg
    24121 caagatggtt ccacaggtaa aggtgctggc tgcacagcct aacaatgcag atttgatatc
    24181 tggagctcat gtgaagaacc agatatggtc atgtacatct gcaatcccag tacttctaca
    24241 gtgagacggg aaacagacag aagagccgcc atgaaactca tgggaggcca gccaaacaga
    24301 aacatccaaa agagcatgcc ttaaacacaa ggtggtaggg gagaccaact tccaaaggca
    24361 ccttctgatg gccatatgca tgccatgggc atgcctacaa tcacacacac atacaacagt
    24421 agttacaaac ttcatttctc ttcctttttt ttttccttta aaagttgaat acacttgaat
    24481 agatctctca taaatttgta atctcttaag aagaaattta aaaacaagcc acaagaggaa
    24541 tatcaaaaga aaggaacacc aagtcttcta tttgtgagag tccaagcaaa agctgccttg
    24601 aagaaccagg aagctttgga ggagggcagc atttgagcca gggcgtagga tgtagagtgg
    24661 gaggaaagcg ggaggaggga gagagacaat cacacattgt atgtgccagt gctttgtgcc
    24721 caaagcatga ttgaactgta gatgcttgaa actgagaaga aaacaaaacg tttctggtcc
    24781 caggagaatg aaggtttcta gcagagaaaa gggtttgttt aggtgagatg ggtggggcct
    24841 tgtgtaggaa agaggaaagt agaaaggcac cgcaaagcag agatgatccg agaactcaca
    24901 gagccagggg aaagttggat gtggcagagg aagggggaag gcggtggaag gatttaaagc
    24961 tacacaggtg gggctggcaa gagggctctt cagcaaaggt gcttcctgct aagcccactg
    25021 aactgaacct gatcccacaa cctacatggt agaaggagac ttccaaaagt tgtcctctca
    25081 cctccacatg agcatcatgc gcccacttac acacacacac acacacacac acacatgccc
    25141 ctttacacac acacagacac acacagacac acacatttta tttaaaatat tttcaaattt
    25201 acaaagccac acagtgaaga aagaaagtca ggcttctgag tagaacagtt tttacaagtg
    25261 agtcttaaag agtgctctcc acacacaaca tcagattttt tgttattatt tcttttttgt
    25321 ttgtttttgt tggtttccgg tttggtttgg tttggtttgg gttttgtttt gagcatcctt
    25381 tagtgaacat agtggaaatg tggactctaa agccaagagc tgtgtcagca gactcattag
    25441 caatctgtgc ctccatacaa ctctgctctc tcctccaaca atggaaaaca ttgtgcctgg
    25501 gatgtggtca tgactctcag gacgtaagtt ttcaaaggat gactttgttc tccctcctcc
    25561 tgctgttgat ggacccttta aagctctgaa gacagagata attctcttca aattatgtag
    25621 atgtataagt ttggttaagg gtaaaaacag ggctcatatt cccttgagct atcccagaag
    25681 atcaacaatt tatagtacaa aatctgtaaa gtgggccatt tatttaaatt aagcccaagt
    25741 ccaagctgac atttcttgat tgaagttaga catgataaca cacctaaaat cccagcactg
    25801 ggaggctggg aggtggagtc aggaggatgc ctagagtttg ctagaagtta gttgtaggca
    25861 atctgtgggc tccagggtca gaaacagaac ctttctcaaa aaataaggtg gaaggcaata
    25921 gaggaagaca cttaatatgg acctttggcc tctactctct ctctctctct ctctctctct
    25981 ctctctctct ctccctctct ctctcccaca ctcatgaaac catacaagac tcatttagat
    26041 atttcaatgt aatttctcat ttctcttcct ctgttagtcg gggtatcttc tataggtaaa
    26101 accagtgctc agattataaa tttgcacaga ctgttaaaag aaacttctag acaaggtata
    26161 tagtgaggaa tctcccatag tgatttcatt gaaatgatac aagcatgtct tagggtttta
    26221 ctgctgtgaa cagacaacat gaccaagaca aatcttataa aggacattta cttggggccg
    26281 gattacaggt tcagaggttc agttcatcat catcaaggtg ggagcaggca gcatccaggc
    26341 aggcatagtg caggcagagc tgagagttct acatcttcat ctgaaggctg atagtggaag
    26401 actgacttcc aggcagctaa gatgggggtc ttaaagccca cacccacagt aacatactta
    26461 atccaacagg gccacacctt ctaatagtac tgctccctgg gccaagcata tgcaaaccac
    26521 cacaaagcat atgttgtcta tgtatataaa aatatcctga atcagtttac tattttattt
    26581 ctgtcatagt gcagtgttct ctttaatagg tccacccatc tgaagttctg tgtgtactct
    26641 ttcagttaaa acagcagaat ggcttggaga atggtccatc actggctctt cttgcatagg
    26701 acctagcttc actccccagc atccacatgg tcacttacaa tactctaaac ctccagttcc
    26761 agggactctt ctccagttcc tctgctcttc tctggcttct gagggatcct gcatgtatgt
    26821 gatacatatg cagggaaaac acccataact taaaatgaga agaaattaat cttaaaacaa
    26881 aaacaaaaaa aacaaaaaaa aacaaaaaaa caagtggaaa aaattctgga taatttgctt
    26941 acaaaatcag gattttctaa tttccttctt cagtgatccg attccagtta tttaggttgg
    27001 attaactcat tttccttttt aaatcgtctg ttggtttgtt ttctgagaca atgttcctga
    27061 gctccaggcc agcctcaaac tccctactta gctgagtgtg gtcttgaact tctggccttc
    27121 ctgcctccac ctcaggagca ctaggcctgc aggtggcctg gggccaccaa ccccagtttt
    27181 actcagtcct ggggatcgag ccaaggggtt agtccagaca agacaagcag ttctacaact
    27241 cagctagatc ctcagcccaa tctaatcttg atttggcaaa attcaactgt caattcgctt
    27301 ccttcacaaa tgcttaagga caatagcttt gcatccacca acatcctaca tgtaagtatt
    27361 ataaagacaa tgaaatatga tttttaattt acttttattt aagtttttaa atattttgat
    27421 catgttttcc atgccccaaa ctcttcccag aacttaccca cctccctatc caccctactt
    27481 catgttcttt ctccctgtcc ctctccctgt ccttctctct ctccctctct ctctctctct
    27541 ctctttgtct ctcacacaca cacacctctc tcaaaattat ctactcaggc aaatcaaaaa
    27601 caaacaaaca aagcaccaat tagacaaaac taaaaataag acaaaaatcc aacaaaaatg
    27661 gaggttgctt tgcattggcc agctatccct gggcgtggtg cctgtctaga gtgtgcattg
    27721 gagtgagttg attggagaga aactcagtat ctgcattgga ggaaacggat tttctcttcc
    27781 cagcagctgt caactgcaaa cagctccctg gttagggtgt aactgtgtcc atttcatcgt
    27841 ttcaataccc aggttgcagt gtgactccat cagaggagac cacactcaca cacgtggagg
    27901 ttcccctgtg tgtttagagt atatagtaag aagactcgta tagtaaactg tggctcttcc
    27961 tggacaagcc caggcctaag ctctgggtgt gtcttacttt ccttgtgaga acttcattta
    28021 accttcaatc tttcctaagc cccaattctt tgttacactg gccacgccta aaattgttcc
    28081 ctgcactgaa gccacgattc ctcatttggc ctgagaggag cccccctaaa atattagagg
    28141 aactttttgt actgctgtca gtgggagagt ggagctgtgc ctcctctgtc caccctgaca
    28201 aaaataccta tcctttttag ctaccagtat tcccttaccc tgagaccttc gagagagcag
    28261 atgggaacaa accgtgtgct ctggtcttac ttgtgtaagt aagaaaatta tattgccatc
    28321 cactcattgt tttacgtagt cctaagtaaa tcatatccgg aatatctagt agtttatgac
    28381 agtcaagaca ctggacatta cagaacttgt actgaggcag gagaataggg ctgagagagg
    28441 gccatgaaaa acctgataca aatgaagtac aaagcgttct ttggaaagtc agttgtgttg
    28501 gaaggtgttc tgctggggca aacctgtgaa ggagtgtttt cttgaagtgg acacaggtac
    28561 aaggcaaagg cagacgtgtg aaggaaggaa gcagacgcag gagagagggt actctgctaa
    28621 agcaagcaca tgaaaggaca cgtgatgaag gattctttgc caacaacaca catgtattgg
    28681 tcagccttac actgcatagt agagctgcat ttgtgggact ctgtggactt gatacatttg
    28741 ctgaggcaag gcacgtggag gacatgttat gtttgcaggg taaaaagagg gtataaacag
    28801 gactcgacaa agtgatggag acagagcttg gcttgctggt gcagctagct gtgcaaagct
    28861 tatgagtctt gcatctttgc tgatcttcac ttccctgaga gaggaacagc tgagaactcc
    28921 ttctggtgtc cctccaggtc tctcctggtg actcaagcca aggctgaggc ctggctgtct
    28981 ctgctaggtt gtgccacctc tgcttgctac cccaatgtta cctgactgga ctgctggtgt
    29041 atctgtgaag tgtttgcagt ggatccatct gccgctgcct gctaacatat gaactaagct
    29101 gatttccaga caacaaagac ttcactccaa agaacccttc taagcaggcc cacttatttt
    29161 cctttctttt ctacaacctc cggtgagtgg tgagctacaa gggagattaa agtgtttaag
    29221 agccatcatt taaaaaggga tttgaaaaaa ttaaagtcat aacaaaggct gtgcaactac
    29281 cacatgaagc aaacttctag cataaggaaa gacgttgtct cctgtaggta ggacagcttg
    29341 ggcacaaaag cccataacaa aaaacataac aaagctggca ttatgcaagt gccccatcaa
    29401 ggatcacaac tcttccaggg cgacaccatt gagcatctga ccttccctct caactctggc
    29461 ccacttcctc tcctgaaagc gcatcctttc tgtatttctg ctacaggata gatttctctg
    29521 ccctgttttt ttgtcccagg atgcaggaag ctggaaatcc tgacaaggtg actccactct
    29581 cagcctatac cagtatgaat gacaaaatcc agtttgtatg ctccctaaga gtaaacagtc
    29641 atgccatcta gattaccata aggtacatat tgccacatgg aaatgaatag attgccatat
    29701 gataatgcca gtacttacct ggacttcaca ctgttgccac tggagataga cttgtgagga
    29761 ggacagacca gtagctttaa tatgctttaa gagcaaccac ttatttagaa ctatccccaa
    29821 gtgaaatgct gcctcggtcc ttgcagcagg gcattctgtt tagtcactgc catttcaagc
    29881 aggctttctt tgattattat tgtttttttt aacaaagcag aactacaggt gagtggcttg
    29941 ccaagtgatg actctgccct tgggttctaa cataccaaat atacagcatc aataaaatgt
    30001 acacggtacc atgaaaaatt cgagaactca agctgctttt cattcagaaa ggaacatgtt
    30061 gtcctctact tgccctggac ctgcgtaagt acaaagatat ccccttccat ggtcttgatg
    30121 gatttctgga ggacctgtaa cgttatctcc atactcttga caaactgttc cagctcatct
    30181 gcggctgctt ctacgggcgt gtgggcattc tcaggactta gcacatcttg cagcttcctc
    30241 aaggtttcct ctgtagtggc tttgggacat tctggactct tgtttttctc agatgtggtg
    30301 gcatctgagg tggcatctga ctgctctttg gtctcctctc tatagaggtc acttaatcga
    30361 agacccatga tggggaactg catcaggagt gagagagaag tttctagatt cacaagcaca
    30421 tgactggtct tcaggaccaa ggcagcacct gatgtctgga tgtttctgag catatcttcc
    30481 gcggtgtggt gtggagcaat ggtggcgcac ttctccactg cagaggtcat agcagtcagc
    30541 accttagagc acaacggctc cttctgcatt tgtttgtgct ttccatccac catcagttgc
    30601 atctctttga aatttctgat catttgttca aagaaatctt taatgcagct ctcttcgttc
    30661 agattcatgg gaaggatctg agtcttcatc gtgaggttaa acagctcaac gaaccgattt
    30721 atgaaggaga ccaggtctcg tatgtggaag aagaatagtt tggcagcttg gatcagtctc
    30781 tctttatcct tttctgactc agaagacatt tctccaacaa acaactttca accctgttaa
    30841 gcaaagcaga atccaaatga aaactagaac tggccatgaa gagacgggaa ggatgctata
    30901 aacacgccaa gctaagtctt gacaagggtg acaaagtaca tatgactctg ggctttaatc
    30961 gaaacaggaa cagaaataaa gagaaggata ggatagtaaa cgctcctgac tgtctgccat
    31021 atacatgcta ggtagctggc tgggcattag cagtcttgga ggccactgaa aaccaatcct
    31081 ccctcccagt cagtggtgca tcccagtttt agtttccctg gtaacgcacc aattttacga
    31141 aaggaaaaat atcacagttg gaaatgccac agaagaggga ggaaacatcg aaactgcact
    31201 ttaagatccg aacccatgaa aggaggaggg ctgtgtagaa cggctttgct ggtgcctcat
    31261 aagagaaggc tatttcaagc tgggcatagt ggtgcatgcc tttaatccca gcagaggtgg
    31321 gtgggtctct gtgagttccg ggccagcctg gtctacatat tgagttccac gtcaaccagg
    31381 gctatctaga gataaccatg tctcacaaaa agaaacatgg gggagagggt aatttctttc
    31441 tggtatggta gtttatagac tttttttcta tttttcttga attagtttga tctactgtgc
    31501 tttaagactt cggggcaaaa gaacgaaatg tgagctctac
//
LOCUS       pR3R4AsiSI_synvect_D       2029 bp    DNA     circular     15-JAN-2007
Created: 28 April 2005 15:57
FEATURES             Location/Qualifiers
     misc_feature    1..20
                     /note="G PCR fwd"
     gateway         29..152
                     /note="Gateway R4"
     misc_feature    153..2029
                     /note="pBR322"
     gateway         29..49
                     /note="B4"
     primer_bind     complement(1..20)
                     /note="R4 primer"
     primer_bind     complement(357..376)
                     /note="R4R primer"
BASE COUNT      519 a    527 c    514 g    469 t
ORIGIN      
          1 CCactggccg tcgttttaca TTAATTAACA ACTTTGTATA GAAAAGTTGA ACGAGAAACG
         61 TAAAATGATA TAAATATCAA TATATTAAAT TAGATTTTGC ATAAAAAACA GACTACATAA
        121 TACTGTAAAA CACAACATAT CCAGTCACTA TGGCGGCCGC AATCGGGCAG CGTTGGGTCC
        181 TGGCCACGGG TGCGCATGAT CGTGCTCCTG TCGTTGAGGA CCCGGCTAGG CTGGCGGGGT
        241 TGCCTTACTG GTTAGCAGAA TGAATCACCG ATACGCGAGC GAACGTGAAG CGACTGCTGC
        301 TGCAAAACGT CTGCGACCTG AGCAACAACA TGAATGGTCT TCGGTTTCCG TGTTTCGTAA
        361 AGTCTGGAAA CGCGGAAGTC AGCGCCCTGC ACCATTATGT TCCGGATCTG CATCGCAGGA
        421 TGCTGCTGGC TACCCTGTGG AACACCTACA TCTGTATTAA CGAAGCGCTG GCATTGACCC
        481 TGAGTGATTT TTCTCTGGTC CCGCCGCATC CATACCGCCA GTTGTTTACC CTCACAACGT
        541 TCCAGTAACC GGGCATGTTC ATCATCAGTA ACCCGTATCG TGAGCATCCT CTCTCGTTTC
        601 ATCGGTATCA TTACCCCCAT GAACAGAAAT CCCCCTTACA CGGAGGCATC AGTGACCAAA
        661 CAGGAAAAAA CCGCCCTTAA CATGGCCCGC TTTATCAGAA GCCAGACATT AACGCTTCTG
        721 GAGAAACTCA ACGAGCTGGA CGCGGATGAA CAGGCAGACA TCTGTGAATC GCTTCACGAC
        781 CACGCTGATG AGCTTTACCG CAGCTGCCTC GCGCGTTTCG GTGATGACGG TGAAAACCTC
        841 TGACACATGC AGCTCCCGGA GACGGTCACA GCTTGTCTGT AAGCGGATGC CGGGAGCAGA
        901 CAAGCCCGTC AGGGCGCGTC AGCGGGTGTT GGCGGGTGTC GGGGCGCAGC CATGACCCAG
        961 TCACGTAGCG ATAGCGGAGT GTATACTGGC TTAACTATGC GGCATCAGAG CAGATTGTAC
       1021 TGAGAGTGCA CCATATGCGG TGTGAAATAC CGCACAGATG CGTAAGGAGA AAATACCGCA
       1081 TCAGGCGCTC TTCCGCTTCC TCGCTCACTG ACTCGCTGCG CTCGGTCGTT CGGCTGCGGC
       1141 GAGCGGTATC AGCTCACTCA AAGGCGGTAA TACGGTTATC CACAGAATCA GGGGATAACG
       1201 CAGGAAAGAA CATGTGAGCA AAAGGCCAGC AAAAGGCCAG GAACCGTAAA AAGGCCGCGT
       1261 TGCTGGCGTT TTTCCATAGG CTCCGCCCCC CTGACGAGCA TCACAAAAAT CGACGCTCAA
       1321 GTCAGAGGTG GCGAAACCCG ACAGGACTAT AAAGATACCA GGCGTTTCCC CCTGGAAGCT
       1381 CCCTCGTGCG CTCTCCTGTT CCGACCCTGC CGCTTACCGG ATACCTGTCC GCCTTTCTCC
       1441 CTTCGGGAAG CGTGGCGCTT TCTCATAGCT CACGCTGTAG GTATCTCAGT TCGGTGTAGG
       1501 TCGTTCGCTC CAAGCTGGGC TGTGTGCACG AACCCCCCGT TCAGCCCGAC CGCTGCGCCT
       1561 TATCCGGTAA CTATCGTCTT GAGTCCAACC CGGTAAGACA CGACTTATCG CCACTGGCAG
       1621 CAGCCACTGG TAACAGGATT AGCAGAGCGA GGTATGTAGG CGGTGCTACA GAGTTCTTGA
       1681 AGTGGTGGCC TAACTACGGC TACACTAGAA GGACAGTATT TGGTATCTGC GCTCTGCTGA
       1741 AGCCAGTTAC CTTCGGAAAA AGAGTTGGTA GCTCTTGATC CGGCAAACAA ACCACCGCTG
       1801 GTAGCGGTGG TTTTTTTGTT TGCAAGCAGC AGATTACGCG CAGAAAAAAA GGATCTCAAG
       1861 AAGATCCTTT GATCTTTTCT ACGGGGTCTG ACGCTCAGTG GAACGAAAAC TCACGTTAAG
       1921 GGATTTTGGT CATGAGATTA TCAAAAAGGA TCTTCACCTA GATCCTTTTA AATTAAAAAT
       1981 GAAGTTTTAA ATCAATCTAA AGTATATATG AGTAAACTTG GTCTGACAG
//
LOCUS       pR3R4AsiSI_synvect_U       1239 bp    DNA     circular     18-JAN-2007
Created: 28 April 2005 15:57
FEATURES             Location/Qualifiers
     misc_feature    862..1069
                     /note="pBR322"
     gene            complement(1..861)
                     /note="AMP resistance"
     gateway         complement(1078..1201)
                     /note="Gateway R3"
     misc_feature    complement(1217..1239)
                     /note="G PCR rev"
     gateway         complement(1181..1201)
                     /note="B3"
     misc_feature    1207..1214
                     /note="AsiSI"
     primer_bind     823..842
                     /note="R3F primer"
     primer_bind     1217..1239
                     /note="R3 primer"
BASE COUNT      328 a    290 c    267 g    354 t
ORIGIN      
          1 TTACCAATGC TTAATCAGTG AGGCACCTAT CTCAGCGATC TGTCTATTTC GTTCATCCAT
         61 AGTTGCCTGA CTCCCCGTCG TGTAGATAAC TACGATACGG GAGGGCTTAC CATCTGGCCC
        121 CAGTGCTGCA ATGATACCGC GAGACCCACG CTCACCGGCT CCAGATTTAT CAGCAATAAA
        181 CCAGCCAGCC GGAAGGGCCG AGCGCAGAAG TGGTCCTGCA ACTTTATCCG CCTCCATCCA
        241 GTCTATTAAT TGTTGCCGGG AAGCTAGAGT AAGTAGTTCG CCAGTTAATA GTTTGCGCAA
        301 CGTTGTTGCC ATTGCTGCAG GCATCGTGGT GTCACGCTCG TCGTTTGGTA TGGCTTCATT
        361 CAGCTCCGGT TCCCAACGAT CAAGGCGAGT TACATGATCC CCCATGTTGT GCAAAAAAGC
        421 GGTTAGCTCC TTCGGTCCTC CGATCGTTGT CAGAAGTAAG TTGGCCGCAG TGTTATCACT
        481 CATGGTTATG GCAGCACTGC ATAATTCTCT TACTGTCATG CCATCCGTAA GATGCTTTTC
        541 TGTGACTGGT GAGTACTCAA CCAAGTCATT CTGAGAATAG TGTATGCGGC GACCGAGTTG
        601 CTCTTGCCCG GCGTCAACAC GGGATAATAC CGCGCCACAT AGCAGAACTT TAAAAGTGCT
        661 CATCATTGGA AAACGTTCTT CGGGGCGAAA ACTCTCAAGG ATCTTACCGC TGTTGAGATC
        721 CAGTTCGATG TAACCCACTC GTGCACCCAA CTGATCTTCA GCATCTTTTA CTTTCACCAG
        781 CGTTTCTGGG TGAGCAAAAA CAGGAAGGCA AAATGCCGCA AAAAAGGGAA TAAGGGCGAC
        841 ACGGAAATGT TGAATACTCA TACTCTTCCT TTTTCAATAT TATTGAAGCA TTTATCAGGG
        901 TTATTGTCTC ATGAGCGGAT ACATATTTGA ATGTATTTAG AAAAATAAAC AAATAGGGGT
        961 TCCGCGCACA TTTCCCCGAA AAGTGCCACC TGACGTCTAA GAAACCATTA TTATCATGAC
       1021 ATTAACCTAT AAAAATAGGC GTATCACGAG GCCCTTTCGT CTTCAAGAAt tGTCGACCAT
       1081 AGTGACTGGA TATGTTGTGT TTTACAGTAT TATGTAGTCT GTTTTTTATG CAAAATCTAA
       1141 TTTAATATAT TGATATTTAT ATCATTTTAC GTTTCTCGTT CAACTTTATT ATACAAAGTT
       1201 GCGGACgcga tcgcCGgcgg ataacaattt cacacagga
//
LOCUS       pL3L4_(+)_DTA_Map2       5644 bp    DNA     circular     11-JAN-2008
Created: 09 July 2004 16:18 
orientation of backbone?
FEATURES             Location/Qualifiers
     gateway         complement(1112..1207)
                     /note="Gateway L3"
     gateway         2657..2752
                     /note="Gateway L4"
     promoter        2788..3301
                     /note="PGK promoter"
     misc_feature    3315..3971
                     /note="DTA"
     polyA_site      4096..4354
                     /note="bpA"
     misc_feature    complement(4850..5644)
                     /note="KanR"
     misc_feature    1214..2655
                     /note="ChlR_ccdB"
     gateway         2732..2752
                     /note="B4"
     misc_feature    1133..2730
                     /note="this bit going"
     gateway         complement(1112..1132)
                     /note="B3"
     primer_bind     962..981
                     /note="L3 primer"
     primer_bind     complement(2859..2878)
                     /note="L4 primer"
BASE COUNT     1354 a   1395 c   1478 g   1417 t
ORIGIN      
          1 GCGAAACGAT CCTCATCCTG TCTCTTGATC AGATCTTGAT CCCCTGCGCC ATCAGATCCT
         61 TGGCGGCGAG AAAGCCATCC AGTTTACTTT GCAGGGCTTC CCAACCTTAC CAGAGGGCGC
        121 CCCAGCTGGC AATTCCGGTT CGCTTGCTGT CCATAAAACC GCCCAGTCTA GCTATCGCCA
        181 TGTAAGCCCA CTGCAAGCTA CCTGCTTTCT CTTTGCGCTT GCGTTTTCCC TTGTCCAGAT
        241 AGCCCAGTAG CTGACATTCA TCCGGGGTCA GCACCGTTTC TGCGGACTGG CTTTCTACGT
        301 GAAAAGGATC TAGGTGAAGA TCCTTTTTGA TAATCTCATG ACCAAAATCC CTTAACGTGA
        361 GTTTTCGTTC CACTGAGCGT CAGACCCCGT AGAAAAGATC AAAGGATCTT CTTGAGATCC
        421 TTTTTTTCTG CGCGTAATCT GCTGCTTGCA AACAAAAAAA CCACCGCTAC CAGCGGTGGT
        481 TTGTTTGCCG GATCAAGAGC TACCAACTCT TTTTCCGAAG GTAACTGGCT TCAGCAGAGC
        541 GCAGATACCA AATACTGTTC TTCTAGTGTA GCCGTAGTTA GGCCACCACT TCAAGAACTC
        601 TGTAGCACCG CCTACATACC TCGCTCTGCT AATCCTGTTA CCAGTGGCTG CTGCCAGTGG
        661 CGATAAGTCG TGTCTTACCG GGTTGGACTC AAGACGATAG TTACCGGATA AGGCGCAGCG
        721 GTCGGGCTGA ACGGGGGGTT CGTGCACACA GCCCAGCTTG GAGCGAACGA CCTACACCGA
        781 ACTGAGATAC CTACAGCGTG AGCTATGAGA AAGCGCCACG CTTCCCGAAG GGAGAAAGGC
        841 GGACAGGTAT CCGGTAAGCG GCAGGGTCGG AACAGGAGAG CGCACGAGGG AGCTTCCAGG
        901 GGGAAACGCC TGGTATCTTT ATAGTCCTGT CGGGTTTCGC CACCTCTGAC TTGAGCGTCG
        961 ATTTTTGTGA TGCTCGTCAG GGGGGCGGAG CCTATGGAAA AACGCCAGCA ACGCGGCCTT
       1021 TTTACGGTTC CTGGGCTTTT GCTGGCCTTT TGCTCACATG TAATACGACT CACTATAGGG
       1081 CGAATTGGAG CTAGGCGGCC GTTTATCGTG CCAACTTTAT TATACAAAGT TGGCATTATA
       1141 AGAAAGCATT GCTTATCAAT TTGTTGCAAC GAACAGGTCA CTATCAGTCA AAATAAAATA
       1201 TTATTTGGCG GCCGCATTAG GCACCCCAGG CTTTACACTT TATGCTTCCG GCTCGTATAA
       1261 TGTGTGGATT TTGAGTTAGG ATCCGTCGAG ATTTTCAGGA GCTAAGGAAG CTAAAATGGA
       1321 GAAAAAAATC ACTGGATATA CCACCGTTGA TATATCCCAA TGGCATCGTA AAGAACATTT
       1381 TGAGGCATTT CAGTCAGTTG CTCAATGTAC CTATAACCAG ACCGTTCAGC TGGATATTAC
       1441 GGCCTTTTTA AAGACCGTAA AGAAAAATAA GCACAAGTTT TATCCGGCCT TTATTCACAT
       1501 TCTTGCCCGC CTGATGAATG CTCATCCGGA ATTCCGTATG GCAATGAAAG ACGGTGAGCT
       1561 GGTGATATGG GATAGTGTTC ACCCTTGTTA CACCGTTTTC CATGAGCAAA CTGAAACGTT
       1621 TTCATCGCTC TGGAGTGAAT ACCACGACGA TTTCCGGCAG TTTCTACACA TATATTCGCA
       1681 AGATGTGGCG TGTTACGGTG AAAACCTGGC CTATTTCCCT AAAGGGTTTA TTGAGAATAT
       1741 GTTTTTCGTC TCAGCCAATC CCTGGGTGAG TTTCACCAGT TTTGATTTAA ACGTGGCCAA
       1801 TATGGACAAC TTCTTCGCCC CCGTTTTCAC CATGGGCAAA TATTATACGC AAGGCGACAA
       1861 GGTGCTGATG CCGCTGGCGA TTCAGGTTCA TCATGCCGTT TGTGATGGCT TCCATGTCGG
       1921 CAGAATGCTT AATGAATTAC AACAGTACTG CGATGAGTGG CAGGGCGGGG CGTAAACGCG
       1981 TGGATCCGGC TTACTAAAAG CCAGATAACA GTATGCGTAT TTGCGCGCTG ATTTTTGCGG
       2041 TATAAGAATA TATACTGATA TGTATACCCG AAGTATGTCA AAAAGAGGTA TGCTATGAAG
       2101 CAGCGTATTA CAGTGACAGT TGACAGCGAC AGCTATCAGT TGCTCAAGGC ATATATGATG
       2161 TCAATATCTC CGGTCTGGTA AGCACAACCA TGCAGAATGA AGCCCGTCGT CTGCGTGCCG
       2221 AACGCTGGAA AGCGGAAAAT CAGGAAGGGA TGGCTGAGGT CGCCCGGTTT ATTGAAATGA
       2281 ACGGCTCTTT TGCTGACGAG AACAGGGGCT GGTGAAATGC AGTTTAAGGT TTACACCTAT
       2341 AAAAGAGAGA GCCGTTATCG TCTGTTTGTG GATGTACAGA GTGATATTAT TGACACGCCC
       2401 GGGCGACGGA TGGTGATCCC CCTGGCCAGT GCACGTCTGC TGTCAGATAA AGTCTCCCGT
       2461 GAACTTTACC CGGTGGTGCA TATCGGGGAT GAAAGCTGGC GCATGATGAC CACCGATATG
       2521 GCCAGTGTGC CGGTCTCCGT TATCGGGGAA GAAGTGGCTG ATCTCAGCCA CCGCGAAAAT
       2581 GACATCAAAA ACGCCATTAA CCTGATGTTC TGGGGAATAT AAATGTCAGG CTCCCTTATA
       2641 CACAGCCAGT CTGCAGCAAT AATGATTTTA TTTTGACTGA TAGTGACCTG TTCGTTGCAA
       2701 CAAATTGATG AGCAAGGCTT TTTTATAATG CCAACTTTGT ATAGAAAAGT TGACAGATAA
       2761 ACGGATCCCC TAGTTTGTGA TAGGATCGAA TTCTACCGGG TAGGGGAGGC GCTTTTCCCA
       2821 AGGCAGTCTG GAGCATGCGC TTTAGCAGCC CCGCTGGGCA CTTGGCGCTA CACAAGTGGC
       2881 CTCTGGCCTC GCACACATTC CACATCCACC GGTAGGCGCC AACCGGCTCC GTTCTTTGGT
       2941 GGCCCCTTCG CGCCACCTTC TACTCCTCCC CTAGTCAGGA AGTTCCCCCC CGCCCCGCAG
       3001 CTCGCGTCGT GCAGGACGTG ACAAATGGAA GTAGCACGTC TCACTAGTCT CGTGCAGATG
       3061 GACAGCACCG CTGAGCAATG GAAGCGGGTA GGCCTTTGGG GCAGCGGCCA ATAGCAGCTT
       3121 TGCTCCTTCG CTTTCTGGGC TCAGAGGCTG GGAAGGGGTG GGTCCGGGGG CGGGCTCAGG
       3181 GGCGGGCTCA GGGGCGGGGC GGGCGCCCGA AGGTCCTCCG GAGGCCCGGC ATTCTGCACG
       3241 CTTCAAAAGC GCACGTCTGC CGCGCTGTTC TCCTCTTCCT CATCTCCGGG CCTTTCGACC
       3301 TGCAGGTCCT CGCCATGGAT CCTGATGATG TTGTTGATTC TTCTAAATCT TTTGTGATGG
       3361 AAAACTTTTC TTCGTACCAC GGGACTAAAC CTGGTTATGT AGATTCCATT CAAAAAGGTA
       3421 TACAAAAGCC AAAATCTGGT ACACAAGGAA ATTATGACGA TGATTGGAAA GGGTTTTATA
       3481 GTACCGACAA TAAATACGAC GCTGCGGGAT ACTCTGTAGA TAATGAAAAC CCGCTCTCTG
       3541 GAAAAGCTGG AGGCGTGGTC AAAGTGACGT ATCCAGGACT GACGAAGGTT CTCGCACTAA
       3601 AAGTGGATAA TGCCGAAACT ATTAAGAAAG AGTTAGGTTT AAGTCTCACT GAACCGTTGA
       3661 TGGAGCAAGT CGGAACGGAA GAGTTTATCA AAAGGTTCGG TGATGGTGCT TCGCGTGTAG
       3721 TGCTCAGCCT TCCCTTCGCT GAGGGGAGTT CTAGCGTTGA ATATATTAAT AACTGGGAAC
       3781 AGGCGAAAGC GTTAAGCGTA GAACTTGAGA TTAATTTTGA AACCCGTGGA AAACGTGGCC
       3841 AAGATGCGAT GTATGAGTAT ATGGCTCAAG CCTGTGCAGG AAATCGTGTC AGGCGATCTC
       3901 TTTGTGAAGG AACCTTACTT CTGTGGTGTG ACATAATTGG ACAAACTACC TACAGAGATT
       3961 TAAAGCTCTA AGGTAAATAT AAAATTTTTA AGTGTATAAT GTGTTAAACT ACTGATTCTA
       4021 ATTGTTTGTG TATTTTAGAT TCCAACCTAT GGAACTGATG AATGGGAGCA GTGGTGGAAT
       4081 GCAGATCCTA GAGCTCGCTG ATCAGCCTCG ACTGTGCCTT CTAGTTGCCA GCCATCTGTT
       4141 GTTTGCCCCT CCCCCGTGCC TTCCTTGACC CTGGAAGGTG CCACTCCCAC TGTCCTTTCC
       4201 TAATAAAATG AGGAAATTGC ATCGCATTGT CTGAGTAGGT GTCATTCTAT TCTGGGGGGT
       4261 GGGGTGGGGC AGGACAGCAA GGGGGAGGAT TGGGAAGACA ATAGCAGGCA TGCTGGGGAT
       4321 GCGGTGGGCT CTATGGCTTC TGAGGCGGAA AGAACCAGCT GGGGCTCGAC GCGCCGTACC
       4381 CAGCTTTTGT TCCCTTTAGT GAGGGCCTGA ATGGCGAATG GACGCGCCCT GTAGCGGCGC
       4441 ATTAAGCGCG GCGGGTGTGG TGGTTACGCG CAGCGTGACC GCTACACTTG CCAGCGCCCT
       4501 AGCGCCCGCT CCTTTCGCTT TCTTCCCTTC CTTTCTCGCC ACGTTCGCCG GCTTTCCCCG
       4561 TCAAGCTCTA AATCGGGGGC TCCCTTTAGG GTTCCGATTT AGTGCTTTAC GGCACCTCGA
       4621 CCCCAAAAAA CTTGATTAGG GTGATGGTTC ACGTAGTGGG CCATCGCCCT GATAGACGGT
       4681 TTTTCGCCCT TTGACGTTGG AGTCCACGTT CTTTAATAGT GGACTCTTGT TCCAAACTGG
       4741 AACAACACTC AACCCTATCT CGGTCTATTC TTTTGATTTA TAAGGGATTT TGCCGATTTC
       4801 GGCCTATTGG TTAAAAAATG AGCTGATTTA ACAAAAATTT TAACAAAATT CAGAAGAACT
       4861 CGTCAAGAAG GCGATAGAAG GCGATGCGCT GCGAATCGGG AGCGGCGATA CCGTAAAGCA
       4921 CGAGGAAGCG GTCAGCCCAT TCGCCGCCAA GCTCTTCAGC AATATCACGG GTAGCCAACG
       4981 CTATGTCCTG ATAGCGGTCC GCCACACCCA GCCGGCCACA GTCGATGAAT CCAGAAAAGC
       5041 GGCCATTTTC CACCATGATA TTCGGCAAGC AGGCATCGCC ATGGGTCACG ACGAGATCCT
       5101 CGCCGTCGGG CATGCTCGCC TTGAGCCTGG CGAACAGTTC GGCTGGCGCG AGCCCCTGAT
       5161 GCTCTTCGTC CAGATCATCC TGATCGACAA GACCGGCTTC CATCCGAGTA CGTGCTCGCT
       5221 CGATGCGATG TTTCGCTTGG TGGTCGAATG GGCAGGTAGC CGGATCAAGC GTATGCAGCC
       5281 GCCGCATTGC ATCAGCCATG ATGGATACTT TCTCGGCAGG AGCAAGGTGA GATGACAGGA
       5341 GATCCTGCCC CGGCACTTCG CCCAATAGCA GCCAGTCCCT TCCCGCTTCA GTGACAACGT
       5401 CGAGCACAGC TGCGCAAGGA ACGCCCGTCG TGGCCAGCCA CGATAGCCGC GCTGCCTCGT
       5461 CTTGCAGTTC ATTCAGGGCA CCGGACAGGT CGGTCTTGAC AAAAAGAACC GGGCGCCCCT
       5521 GCGCTGACAG CCGGAACACG GCGGCATCAG AGCAGCCGAT TGTCTGTTGT GCCCAGTCAT
       5581 AGCCGAATAG CCTCTCCACC CAAGCGGCCG GAGAACCTGC GTGCAATCCA TCTTGTTCAA
       5641 TCAT
//
LOCUS       pL4L3_DONR223_DTAminusMap       5807 bp    DNA     circular       24-JUN-2008
Created: 13 March 2007 16:51
FEATURES             Location/Qualifiers
     misc_feature    1..593
                     /note="pUC ori"
     misc_feature    864..891
                     /note="rrnB T2"
     misc_feature    1023..1066
                     /note="rrnB T1"
     misc_feature    1133..1148
                     /note="m13 forward"
     misc_feature    2827..2864
                     /note="Transcription Terminator"
     promoter        4499..4649
                     /note="Spectinomycin Promoter"
     polyA_site      complement(2938..3191)
                     /note="bghpA"
     promoter        complement(3986..4498)
                     /note="PGK promoter"
     misc_feature    complement(3316..3972)
                     /note="DTA ORF"
     misc_feature    4869..5660
                     /note=" spectinomycin R short (aadA1) ORF"
     CDS             4650..5660
                     /note="spectinomycinR long ORF"
                     /translation="MRSRNWSRTLTERSGGNGAVAVFMACYDCFFGVQSMPRASKQQA
                     RYAVGRCLMLWSSNDVTQQGSRPKTKLNIMREAVIAEVSTQLSEVVGVIERHLEPTLL
                     AVHLYGSAVDGGLKPHSDIDLLVTVTVRLDETTRRALINDLLETSASPGESEILRAVE
                     VTIVVHDDIIPWRYPAKRELQFGEWQRNDILAGIFEPATIDIDLAILLTKAREHSVAL
                     VGPAAEELFDPVPEQDLFEALNETLTLWNSPPDWAGDERNVVLTLSRIWYSAVTGKIA
                     PKDVAADWAMERLPAQYQPVILEARQAYLGQEEDRLASRADQLEEFVHYVKGEITKVV
                     GK"
     gateway         2781..2801
                     /note="B3"
     gateway         2706..2801
                     /note="Gateway L3"
     gateway         complement(1161..1181)
                     /note="B4"
     gateway         complement(1161..1256)
                     /note="Gateway L4"
     misc_feature    complement(1938..2597)
                     /note="chloramphenicol ORF"
     misc_feature    complement(1291..1596)
                     /note="ccdB ORF"
     primer_bind     complement(2809..2826)
                     /note="SP6 primer"
BASE COUNT     1459 a   1525 c   1409 g   1414 t
ORIGIN      
          1 ctaccagcgg tggtttgttt gccggatcaa gagctaccaa ctctttttcc gaaggtaact
         61 ggcttcagca gagcgcagat accaaatact gttcttctag tgtagccgta gttaggccac
        121 cacttcaaga actctgtagc accgcctaca tacctcgctc tgctaatcct gttaccagtg
        181 gctgctgcca gtggcgataa gtcgtgtctt accgggttgg actcaagacg atagttaccg
        241 gataaggcgc agcggtcggg ctgaacgggg ggttcgtgca cacagcccag cttggagcga
        301 acgacctaca ccgaactgag atacctacag cgtgagctat gagaaagcgc cacgcttccc
        361 gaagggagaa aggcggacag gtatccggta agcggcaggg tcggaacagg agagcgcacg
        421 agggagcttc cagggggaaa cgcctggtat ctttatagtc ctgtcgggtt tcgccacctc
        481 tgacttgagc gtcgattttt gtgatgctcg tcaggggggc ggagcctatg gaaaaacgcc
        541 agcaacgcgg cctttttacg gttcctggcc ttttgctggc cttttgctca catgttcttt
        601 cctgcgttat cccctgattc tgtggataac cgtattaccg cctttgagtg agctgatacc
        661 gctcgccgca gccgaacgac cgagcgcagc gagtcagtga gcgaggaagc ggaagagcgc
        721 ccaatacgca aaccgcctct ccccgcgcgt tggccgattc attaatgcag ctggcacgac
        781 aggtttcccg actggaaagc gggcagtgag cgcaacgcaa ttaatacgcg taccgctagc
        841 caggaagagt ttgtagaaac gcaaaaaggc catccgtcag gatggccttc tgcttagttt
        901 gatgcctggc agtttatggc gggcgtcctg cccgccaccc tccgggccgt tgcttcacaa
        961 cgttcaaatc cgctcccggc ggatttgtcc tactcaggag agcgttcacc gacaaacaac
       1021 agataaaacg aaaggcccag tcttccgact gagcctttcg ttttatttga tgcctggcag
       1081 ttccctactc tcgcgttaac gctagcatgg atgttttccc agtcacgacg ttgtaaaacg
       1141 acggccagtc ttaaATCTGT CAACTTTTCT ATACAAAGTT GGCATTATAA AAAAGCCTTG
       1201 CTCATCAATT TGTTGCAACG AACAGGTCAC TATCAGTCAA AATAAAATCA TTATTGCTGC
       1261 AGACTGGCTG TGTATAAGGG AGCCTGACAT TTATATTCCC CAGAACATCA GGTTAATGGC
       1321 GTTTTTGATG TCATTTTCGC GGTGGCTGAG ATCAGCCACT TCTTCCCCGA TAACGGAGAC
       1381 CGGCACACTG GCCATATCGG TGGTCATCAT GCGCCAGCTT TCATCCCCGA TATGCACCAC
       1441 CGGGTAAAGT TCACGGGAGA CTTTATCTGA CAGCAGACGT GCACTGGCCA GGGGGATCAC
       1501 CATCCGTCGC CCGGGCGTGT CAATAATATC ACTCTGTACA TCCACAAACA GACGATAACG
       1561 GCTCTCTCTT TTATAGGTGT AAACCTTAAA CTGCATTTCA CCAGCCCCTG TTCTCGTCAG
       1621 CAAAAGAGCC GTTCATTTCA ATAAACCGGG CGACCTCAGC CATCCCTTCC TGATTTTCCG
       1681 CTTTCCAGCG TTCGGCACGC AGACGACGGG CTTCATTCTG CATGGTTGTG CTTACCAGAC
       1741 CGGAGATATT GACATCATAT ATGCCTTGAG CAACTGATAG CTGTCGCTGT CAACTGTCAC
       1801 TGTAATACGC TGCTTCATAG CATACCTCTT TTTGACATAC TTCGGGTATA CATATCAGTA
       1861 TATATTCTTA TACCGCAAAA ATCAGCGCGC AAATACGCAT ACTGTTATCT GGCTTTTAGT
       1921 AAGCCGGATC CACGCGTTTA CGCCCCGCCC TGCCACTCAT CGCAGTACTG TTGTAATTCA
       1981 TTAAGCATTC TGCCGACATG GAAGCCATCA CAAACGGCAT GATGAACCTG AATCGCCAGC
       2041 GGCATCAGCA CCTTGTCGCC TTGCGTATAA TATTTGCCCA TGGTGAAAAC GGGGGCGAAG
       2101 AAGTTGTCCA TATTGGCCAC GTTTAAATCA AAACTGGTGA AACTCACCCA GGGATTGGCT
       2161 GAGACGAAAA ACATATTCTC AATAAACCCT TTAGGGAAAT AGGCCAGGTT TTCACCGTAA
       2221 CACGCCACAT CTTGCGAATA TATGTGTAGA AACTGCCGGA AATCGTCGTG GTATTCACTC
       2281 CAGAGCGATG AAAACGTTTC AGTTTGCTCA TGGAAAACGG TGTAACAAGG GTGAACACTA
       2341 TCCCATATCA CCAGCTCACC GTCTTTCATT GCCATACGGA ATTCCGGATG AGCATTCATC
       2401 AGGCGGGCAA GAATGTGAAT AAAGGCCGGA TAAAACTTGT GCTTATTTTT CTTTACGGTC
       2461 TTTAAAAAGG CCGTAATATC CAGCTGAACG GTCTGGTTAT AGGTACATTG AGCAACTGAC
       2521 TGAAATGCCT CAAAATGTTC TTTACGATGC CATTGGGATA TATCAACGGT GGTATATCCA
       2581 GTGATTTTTT TCTCCATTTT AGCTTCCTTA GCTCCTGAAA ATCTCGACGG ATCCTAACTC
       2641 AAAATCCACA CATTATACGA GCCGGAAGCA TAAAGTGTAA AGCCTGGGGT GCCTAATGCG
       2701 GCCGCCAAAT AATATTTTAT TTTGACTGAT AGTGACCTGT TCGTTGCAAC AAATTGATAA
       2761 GCAATGCTTT CTTATAATGC CAACTTTGTA TAATAAAGTT GGCACGATCT ATAGTGTCAC
       2821 CTAAATCCAA AAAAACCGGG CCAACATTGG CCCGGTTTTT TTCCGTTTAT CTGTTTAAAC
       2881 TCGGCCGCTC TAGCCTCGAG GCTAGAACTA GTGGATCTCG AGCCCCAGCT GGTTCTTTCC
       2941 GCCTCAGAAG CCATAGAGCC CACCGCATCC CCAGCATGCC TGCTATTGTC TTCCCAATCC
       3001 TCCCCCTTGC TGTCCTGCCC CACCCCACCC CCCAGAATAG AATGACACCT ACTCAGACAA
       3061 TGCGATGCAA TTTCCTCATT TTATTAGGAA AGGACAGTGG GAGTGGCACC TTCCAGGGTC
       3121 AAGGAAGGCA CGGGGGAGGG GCAAACAACA GATGGCTGGC AACTAGAAGG CACAGTCGAG
       3181 GCTGATCAGC GAGCTCTAGG ATCTGCATTC CACCACTGCT CCCATTCATC AGTTCCATAG
       3241 GTTGGAATCT AAAATACACA AACAATTAGA ATCAGTAGTT TAACACATTA TACACTTAAA
       3301 AATTTTATAT TTACCTTAGA GCTTTAAATC TCTGTAGGTA GTTTGTCCAA TTATGTCACA
       3361 CCACAGAAGT AAGGTTCCTT CACAAAGAGA TCGCCTGACA CGATTTCCTG CACAGGCTTG
       3421 AGCCATATAC TCATACATCG CATCTTGGCC ACGTTTTCCA CGGGTTTCAA AATTAATCTC
       3481 AAGTTCTACG CTTAACGCTT TCGCCTGTTC CCAGTTATTA ATATATTCAA CGCTAGAACT
       3541 CCCCTCAGCG AAGGGAAGGC TGAGCACTAC ACGCGAAGCA CCATCACCGA ACCTTTTGAT
       3601 AAACTCTTCC GTTCCGACTT GCTCCATCAA CGGTTCAGTG AGACTTAAAC CTAACTCTTT
       3661 CTTAATAGTT TCGGCATTAT CCACTTTTAG TGCGAGAACC TTCGTCAGTC CTGGATACGT
       3721 CACTTTGACC ACGCCTCCAG CTTTTCCAGA GAGCGGGTTT TCATTATCTA CAGAGTATCC
       3781 CGCAGCGTCG TATTTATTGT CGGTACTATA AAACCCTTTC CAATCATCGT CATAATTTCC
       3841 TTGTGTACCA GATTTTGGCT TTTGTATACC TTTTTGAATG GAATCTACAT AACCAGGTTT
       3901 AGTCCCGTGG TACGAAGAAA AGTTTTCCAT CACAAAAGAT TTAGAAGAAT CAACAACATC
       3961 ATCAGGATCC ATGGCGAGGA CCTGCAGGTC GAAAGGCCCG GAGATGAGGA AGAGGAGAAC
       4021 AGCGCGGCAG ACGTGCGCTT TTGAAGCGTG CAGAATGCCG GGCCTCCGGA GGACCTTCGG
       4081 GCGCCCGCCC CGCCCCTGAG CCCGCCCCTG AGCCCGCCCC CGGACCCACC CCTTCCCAGC
       4141 CTCTGAGCCC AGAAAGCGAA GGAGCAAAGC TGCTATTGGC CGCTGCCCCA AAGGCCTACC
       4201 CGCTTCCATT GCTCAGCGGT GCTGTCCATC TGCACGAGAC TAGTGAGACG TGCTACTTCC
       4261 ATTTGTCACG TCCTGCACGA CGCGAGCTGC GGGGCGGGGG GGAACTTCCT GACTAGGGGA
       4321 GGAGTAGAAG GTGGCGCGAA GGGGCCACCA AAGAACGGAG CCGGTTGGCG CCTACCGGTG
       4381 GATGTGGAAT GTGTGCGAGG CCAGAGGCCA CTTGTGTAGC GCCAAGTGCC CAGCGGGGCT
       4441 GCTAAAGCGC ATGCTCCAGA CTGCCTTGGG AAAAGCGCCT CCCCTACCCG GTAGAATTCG
       4501 ATAAACAGCT ctagaccagc caggacagaa atgcctcgac ttcgctgcta cccaaggttg
       4561 ccgggtgacg cacaccgtgg aaacggatga aggcacgaac ccagtggaca taagcctgtt
       4621 cggttcgtaa gctgtaatgc aagtagcgta tgcgctcacg caactggtcc agaaccttga
       4681 ccgaacgcag cggtggtaac ggcgcagtgg cggttttcat ggcttgttat gactgttttt
       4741 ttggggtaca gtctatgcct cgggcatcca agcagcaagc gcgttacgcc gtgggtcgat
       4801 gtttgatgtt atggagcagc aacgatgtta cgcagcaggg cagtcgccct aaaacaaagt
       4861 taaacattat gagggaagcg gtgatcgccg aagtatcgac tcaactatca gaggtagttg
       4921 gcgtcatcga gcgccatctc gaaccgacgt tgctggccgt acatttgtac ggctccgcag
       4981 tggatggcgg cctgaagcca cacagtgata ttgatttgct ggttacggtg accgtaaggc
       5041 ttgatgaaac aacgcggcga gctttgatca acgacctttt ggaaacttcg gcttcccctg
       5101 gagagagcga gattctccgc gctgtagaag tcaccattgt tgtgcacgac gacatcattc
       5161 cgtggcgtta tccagctaag cgcgaactgc aatttggaga atggcagcgc aatgacattc
       5221 ttgcaggtat cttcgagcca gccacgatcg acattgatct ggctatcttg ctgacaaaag
       5281 caagagaaca tagcgttgcc ttggtaggtc cagcggcgga ggaactcttt gatccggttc
       5341 ctgaacagga tctatttgag gcgctaaatg aaaccttaac gctatggaac tcgccgcccg
       5401 actgggctgg cgatgagcga aatgtagtgc ttacgttgtc ccgcatttgg tacagcgcag
       5461 taaccggcaa aatcgcgccg aaggatgtcg ctgccgactg ggcaatggag cgcctgccgg
       5521 cccagtatca gcccgtcata cttgaagcta gacaggctta tcttggacaa gaagaagatc
       5581 gcttggcctc gcgcgcagat cagttggaag aatttgtcca ctacgtgaaa ggcgagatca
       5641 ccaaggtagt cggcaaataa ccctcgagcc acccatgacc aaaatccctt aacgtgagtt
       5701 acgcgtcgtt ccactgagcg tcagaccccg tagaaaagat caaaggatct tcttgagatc
       5761 ctttttttct gcgcgtaatc tgctgcttgc aaacaaaaaa accaccg
//

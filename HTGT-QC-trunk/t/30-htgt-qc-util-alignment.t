#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use File::Temp;
use Bio::Seq;
use Bio::SeqIO;
use IO::Handle;
use FindBin;
use Const::Fast;
use Log::Log4perl ':levels';

use_ok 'HTGT::QC::Util::CigarParser';
use_ok 'HTGT::QC::Util::Alignment',
    qw( target_alignment_string query_alignment_string alignment_match format_alignment );

Log::Log4perl->easy_init( $ERROR );

sub bio_seq_from_str {
    my ( $id, $str ) = @_;

    $str =~ s/\s+//g;
    
    Bio::Seq->new( -alphabet => 'dna', -seq => $str, -display_id => $id );
}

sub write_seq {
    my ( $filename, $bio_seq ) = @_;

    my $seq_io = Bio::SeqIO->new( -file => '>'.$filename, -format => 'fasta' );
    $seq_io->write_seq( $bio_seq );
}

sub get_cigar {
    my ( $query_seq, $target_seq ) = @_;

    my $query = File::Temp->new( SUFFIX => '.fasta' );
    write_seq( $query->filename, $query_seq );
    $query->close;

    my $target = File::Temp->new( SUFFIX => '.fasta' );
    write_seq( $target->filename, $target_seq );
    $target->close;

    open( my $fh, '-|',
          '/software/team87/brave_new_world/app/exonerate-2.2.0-x86_64/bin/exonerate',
          '--model', 'affine:local',
          '--bestn', 1,
          '--query', $query->filename,
          '--target', $target->filename,
          '--showcigar', 'yes',
          '--showvulgar', 'no',
          '--showalignment', 'no'
      );

    my $parser = HTGT::QC::Util::CigarParser->new( strict_mode => 0 );
    return $parser->file_iterator( $fh )->next;
}

sub test_alignment {
    my ( $query, $target, $e_query_str, $e_target_str, $e_match_str, $start, $end ) = @_;

    ok my $cigar = get_cigar( $query, $target );

    ok my $alignment = alignment_match( $query, $target, $cigar, $start, $end );

    my ( $query_str, $match_str, $target_str ) = @{$alignment}{ qw( query_str match_str target_str ) };

    is $query_str, $e_query_str, 'Got expected query string';

    is $target_str, $e_target_str, 'Got expected target string';

    is $match_str, $e_match_str, 'Got expected match string';

    print format_alignment( query_str => $query_str, match_str => $match_str, target_str => $target_str );
}

sub location_of {
    my ( $str, $bio_seq ) = @_;

    my $pos = index( $bio_seq->seq, $str );

    if ( $pos >= 0 ) {
        return ( $pos + 1, $pos + length( $str ) );
    }

    $pos = index( $bio_seq->revcom->seq, $str );

    if ( $pos >= 0 ) {
        return ( $bio_seq->length - $pos - length( $str ) + 1, $bio_seq->length - $pos );
    }

    die "$str not found in bio_seq";    
}

const my $TARGET_BIO_SEQ => bio_seq_from_str( 'target', <<'EOT' );
CTGGGGCCAGACTTTCCCCACCCCTTCACCCTTTAGACTGGGGCCCTAATCTGTGTGGAAAGTGAGGTATGC
AGCGAATGCTGGAGCTTACTGTATAGTTTGTGTTTGTGTGTGTGTGAAAAGAGGGGAGGGTTTCCCGGCTGG
AGGGAGTGAGACAGTGGGCAGGGAGCAGTTGGGGAAATGGAGCCAGAGCACCTGGCTCTCAGCTGGCCAGCT
CCAGGGCTCCTTACATCTAATTTCCTTCAGAGCTGCTGGTATTTCGGAGACAGCTTTTGCAAATTCCACGCG
AGCTTCGACATGATGCTAAGCCTGACGTCCATATTCCACCTGTGCTCCATCGCGATCGACCGGTTTTATGCA
GTGTGTGACCCTTTGCACTACACCACCACCATGACGGTATCCATGATCAAGAGACTGCTGGCTTTTTGCTGG
GCAGCCCCAGCTCTCTTTTCGTTTGGTTTAGTTCTGTCAGAGGCCAATGTTTCTGGTATGCAGAGCTACGAG
ATTCTTGTTGCTTAGCTTCAATTTCTGTGCGCTTACGTTCAACAAGTTTTCGGGGGACCATACTGTTCACTA
CCTGCTTCTTCACTCC
EOT

{
    
    note "Perfect match to entire target";

    const my $QUERY_BIO_SEQ_0 => bio_seq_from_str( 'query', <<'EOT' );
CTGGGGCCAGACTTTCCCCACCCCTTCACCCTTTAGACTGGGGCCCTAATCTGTGTGGAAAGTGAGGTATGC
AGCGAATGCTGGAGCTTACTGTATAGTTTGTGTTTGTGTGTGTGTGAAAAGAGGGGAGGGTTTCCCGGCTGG
AGGGAGTGAGACAGTGGGCAGGGAGCAGTTGGGGAAATGGAGCCAGAGCACCTGGCTCTCAGCTGGCCAGCT
CCAGGGCTCCTTACATCTAATTTCCTTCAGAGCTGCTGGTATTTCGGAGACAGCTTTTGCAAATTCCACGCG
AGCTTCGACATGATGCTAAGCCTGACGTCCATATTCCACCTGTGCTCCATCGCGATCGACCGGTTTTATGCA
GTGTGTGACCCTTTGCACTACACCACCACCATGACGGTATCCATGATCAAGAGACTGCTGGCTTTTTGCTGG
GCAGCCCCAGCTCTCTTTTCGTTTGGTTTAGTTCTGTCAGAGGCCAATGTTTCTGGTATGCAGAGCTACGAG
ATTCTTGTTGCTTAGCTTCAATTTCTGTGCGCTTACGTTCAACAAGTTTTCGGGGGACCATACTGTTCACTA
CCTGCTTCTTCACTCC
EOT

    test_alignment(
        $QUERY_BIO_SEQ_0,
        $TARGET_BIO_SEQ,
        $QUERY_BIO_SEQ_0->seq,
        $TARGET_BIO_SEQ->seq,
        join( '', '|' x $TARGET_BIO_SEQ->length )
    );

    test_alignment(
        $QUERY_BIO_SEQ_0,
        $TARGET_BIO_SEQ,
        'AGGGAGTGAGACAGTGGGCAGGGAGCAGTTGGGGAAATGGAGCCAGAGCACCTGGCTCTCAGCTGGCCAGCT',
        'AGGGAGTGAGACAGTGGGCAGGGAGCAGTTGGGGAAATGGAGCCAGAGCACCTGGCTCTCAGCTGGCCAGCT',
        join( '', '|' x 72 ),
        145, 216
    );
}

{
    
    note "Perfect match to subseq of target";

    const my $QUERY_BIO_SEQ_1 => bio_seq_from_str( 'query', <<'EOT' );
AGCGAATGCTGGAGCTTACTGTATAGTTTGTGTTTGTGTGTGTGTGAAAAGAGGGGAGGGTTTCCCGGCTGG
AGGGAGTGAGACAGTGGGCAGGGAGCAGTTGGGGAAATGGAGCCAGAGCACCTGGCTCTCAGCTGGCCAGCT
CCAGGGCTCCTTACATCTAATTTCCTTCAGAGCTGCTGGTATTTCGGAGACAGCTTTTGCAAATTCCACGCG
AGCTTCGACATGATGCTAAGCCTGACGTCCATATTCCACCTGTGCTCCATCGCGATCGACCGGTTTTATGCA
GTGTGTGACCCTTTGCACTACACCACCACCATGACGGTATCCATGATCAAGAGACTGCTGGCTTTTTGCTGG
EOT

    const my $E_QUERY_STR => join( '', ('-'x72), $QUERY_BIO_SEQ_1->seq, ('-'x160) ); 

    const my $E_MATCH_STR => join( '', (' 'x72), ('|'x360), (' 'x160) );
    
    test_alignment(
        $QUERY_BIO_SEQ_1,
        $TARGET_BIO_SEQ,
        $E_QUERY_STR,
        $TARGET_BIO_SEQ->seq,
        $E_MATCH_STR
    );

    test_alignment(
        $QUERY_BIO_SEQ_1,
        $TARGET_BIO_SEQ,
        '----------AGCGAATGCTGGAGCTTACTGTATAGTTTGTGTTTGTGTGTGTGTGAAAAGAGGGGAGGGTTTCCCGGCTGG',
        'TGAGGTATGCAGCGAATGCTGGAGCTTACTGTATAGTTTGTGTTTGTGTGTGTGTGAAAAGAGGGGAGGGTTTCCCGGCTGG',
        '          ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||',
        63,
        144
    );

    const my $TARGET_SUBSTR => 'GTGTGTGACCCTTTGCACTACACCACCACCATGACGGTATCCATGATCAAGAGACTGCTGGCTTTTTGCTGGGCAGCCCCAG';
        
    test_alignment(
        $QUERY_BIO_SEQ_1,
        $TARGET_BIO_SEQ,
        'GTGTGTGACCCTTTGCACTACACCACCACCATGACGGTATCCATGATCAAGAGACTGCTGGCTTTTTGCTGG----------',
        $TARGET_SUBSTR,
        '||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||          ',
        location_of( $TARGET_SUBSTR, $TARGET_BIO_SEQ )
    );
    
    my ( $s, $e ) = location_of( 'GTGTGTGACCCTTTGCACTACACCACCACCATGACGGTATCCATGATCAAGAGACTGCTGGCTTTTTGCTGGGCAGCCCCAG', $TARGET_BIO_SEQ );
    is $s, 361;
    is $e, 442;
        
}

{
    
    note "Perfect match to subseq of target (reverse strand)";

    const my $QUERY_BIO_SEQ_2 => bio_seq_from_str( 'query', <<'EOT' )->revcom;
AGCGAATGCTGGAGCTTACTGTATAGTTTGTGTTTGTGTGTGTGTGAAAAGAGGGGAGGGTTTCCCGGCTGG
AGGGAGTGAGACAGTGGGCAGGGAGCAGTTGGGGAAATGGAGCCAGAGCACCTGGCTCTCAGCTGGCCAGCT
CCAGGGCTCCTTACATCTAATTTCCTTCAGAGCTGCTGGTATTTCGGAGACAGCTTTTGCAAATTCCACGCG
AGCTTCGACATGATGCTAAGCCTGACGTCCATATTCCACCTGTGCTCCATCGCGATCGACCGGTTTTATGCA
GTGTGTGACCCTTTGCACTACACCACCACCATGACGGTATCCATGATCAAGAGACTGCTGGCTTTTTGCTGG
EOT

    const my $E_QUERY_STR => join( '', ('-' x 160), $QUERY_BIO_SEQ_2->seq, ( '-' x 72 ) );

    const my $E_MATCH_STR => join( '', (' ' x 160), ('|' x 360), (' ' x 72 ) );
    
    test_alignment( $QUERY_BIO_SEQ_2, $TARGET_BIO_SEQ, $E_QUERY_STR, $TARGET_BIO_SEQ->revcom->seq, $E_MATCH_STR );

    const my $TARGET_SUBSTR => 'AGAGAGCTGGGGCTGCCCAGCAAAAAGCCAGCAGTCTCTTGATCATGGATACCGTCATGGTGGTGGTGTAGT';
    
    
    test_alignment(
        $QUERY_BIO_SEQ_2,
        $TARGET_BIO_SEQ,
        '----------------CCAGCAAAAAGCCAGCAGTCTCTTGATCATGGATACCGTCATGGTGGTGGTGTAGT',
        $TARGET_SUBSTR,
        '                ||||||||||||||||||||||||||||||||||||||||||||||||||||||||',
        377,
        448
    );

    my ( $s, $e ) = location_of( $TARGET_SUBSTR, $TARGET_BIO_SEQ );
    is $s, 377;
    is $e, 448;        
}

{

    note "Match of subseq with insertion";

    const my $QUERY_BIO_SEQ_3 => bio_seq_from_str( 'query', <<'EOT' );
AGCGAATGCTGGAGCTTACTGTATAGTTTGTGTTTGTGTGTGTGTGAAAAGAGGGGAGGGTTTCCCGGCTGG
AGGGAGTGAGACAGTGGGCAGGGAGCAGTTGGGGAAATGGAGCCAGAGCACCTGGCTCTCAGCTGGCCAGCT
AGTCTGT
CCAGGGCTCCTTACATCTAATTTCCTTCAGAGCTGCTGGTATTTCGGAGACAGCTTTTGCAAATTCCACGCG
AGCTTCGACATGATGCTAAGCCTGACGTCCATATTCCACCTGTGCTCCATCGCGATCGACCGGTTTTATGCA
GTGTGTGACCCTTTGCACTACACCACCACCATGACGGTATCCATGATCAAGAGACTGCTGGCTTTTTGCTGG
EOT

    const my $E_QUERY_STR => join( '', ('-'x72), $QUERY_BIO_SEQ_3->seq, ('-'x160) );

    const my $E_TARGET_STR => join( '',
                                    $TARGET_BIO_SEQ->subseq(1,216),
                                    ('-'x7),
                                    $TARGET_BIO_SEQ->subseq(217, $TARGET_BIO_SEQ->length) );

    const my $E_MATCH_STR => join( '',
                                   (' 'x72),
                                   ('|' x 144),
                                   (' 'x7),
                                   ('|'x216),
                                   (' 'x160) );
                             
    
    test_alignment( $QUERY_BIO_SEQ_3, $TARGET_BIO_SEQ, $E_QUERY_STR, $E_TARGET_STR, $E_MATCH_STR );

    test_alignment(
        $QUERY_BIO_SEQ_3,
        $TARGET_BIO_SEQ,
        'CTGGCCAGCTAGTCTGTCCAGGGCTCCTTACATCTAATTTCCTTCAGAGCTGCTGGTATTTCGGAGACAGCTTTTGCAAATT',
        'CTGGCCAGCT-------CCAGGGCTCCTTACATCTAATTTCCTTCAGAGCTGCTGGTATTTCGGAGACAGCTTTTGCAAATT',
        '||||||||||       |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||',
        (location_of( 'CTGGCCAGCT', $TARGET_BIO_SEQ ))[0],
        (location_of( 'AGCTTTTGCAAATT' , $TARGET_BIO_SEQ))[1]
    );
}

{
    note "Match of subseq with insertion (reverse strand)";

    const my $QUERY_BIO_SEQ_4 => bio_seq_from_str( 'query', <<'EOT' )->revcom;
AGCGAATGCTGGAGCTTACTGTATAGTTTGTGTTTGTGTGTGTGTGAAAAGAGGGGAGGGTTTCCCGGCTGG
AGGGAGTGAGACAGTGGGCAGGGAGCAGTTGGGGAAATGGAGCCAGAGCACCTGGCTCTCAGCTGGCCAGCT
GGTCTGG
CCAGGGCTCCTTACATCTAATTTCCTTCAGAGCTGCTGGTATTTCGGAGACAGCTTTTGCAAATTCCACGCG
AGCTTCGACATGATGCTAAGCCTGACGTCCATATTCCACCTGTGCTCCATCGCGATCGACCGGTTTTATGCA
GTGTGTGACCCTTTGCACTACACCACCACCATGACGGTATCCATGATCAAGAGACTGCTGGCTTTTTGCTGG
EOT

    const my $E_QUERY_STR => join( '', ('-'x160), $QUERY_BIO_SEQ_4->seq, ('-'x72) );

    const my $E_TARGET_STR => join( '',
                                    $TARGET_BIO_SEQ->revcom->subseq(1, 376),
                                    ('-'x7),
                                    $TARGET_BIO_SEQ->revcom->subseq(377, $TARGET_BIO_SEQ->length) );

    const my $E_MATCH_STR => join( '',
                                   (' 'x160),
                                   ('|'x216),
                                   (' 'x7),
                                   ('|'x144),
                                   (' 'x72) );

    test_alignment( $QUERY_BIO_SEQ_4, $TARGET_BIO_SEQ, $E_QUERY_STR, $E_TARGET_STR, $E_MATCH_STR );

    test_alignment(
        $QUERY_BIO_SEQ_4,
        $TARGET_BIO_SEQ,
        'ATGTAAGGAGCCCTGGCCAGACCAGCTGGCCAGCTGAGAGCCAGGTGCTCTGGCTCCATTTCCCCAACTGCT',
        'ATGTAAGGAGCCCTGG-------AGCTGGCCAGCTGAGAGCCAGGTGCTCTGGCTCCATTTCCCCAACTGCT',
        '||||||||||||||||       |||||||||||||||||||||||||||||||||||||||||||||||||',
        (location_of( 'ATGTAAGGAGCCCTGG', $TARGET_BIO_SEQ ))[1],
        (location_of( 'AGCTGGCCAGCTGAGAGCCAGGTGCTCTGGCTCCATTTCCCCAACTGCT', $TARGET_BIO_SEQ))[0]
    );
}

{
    note "Match of subseq with deletion";

    const my $QUERY_BIO_SEQ_5 => bio_seq_from_str( 'query', <<'EOT' );
AGCGAATGCTGGAGCTTACTGTATAGTTTGTGTTTGTGTGTGTGTGAAAAGAGGGGAGGGTTTCCCGGCTGG
AGGGAGTGAGACAGTGGGCAGGGAGCAGTTGGGGAAATGGAGCCAGAGCACCTGGCTCTCAGCTGGCCAGCT
TCCTTACATCTAATTTCCTTCAGAGCTGCTGGTATTTCGGAGACAGCTTTTGCAAATTCCACGCG
AGCTTCGACATGATGCTAAGCCTGACGTCCATATTCCACCTGTGCTCCATCGCGATCGACCGGTTTTATGCA
GTGTGTGACCCTTTGCACTACACCACCACCATGACGGTATCCATGATCAAGAGACTGCTGGCTTTTTGCTGG   
EOT

    const my $E_QUERY_STR => join( '',
                                   ('-'x72),
                                   $QUERY_BIO_SEQ_5->subseq(1, 144),
                                   ('-'x7),
                                   $QUERY_BIO_SEQ_5->subseq(145, $QUERY_BIO_SEQ_5->length ),
                                   ('-'x160) );

    const my $E_TARGET_STR => $TARGET_BIO_SEQ->seq;

    const my $E_MATCH_STR => join( '',
                                   (' 'x72),
                                   ('|'x144),
                                   (' 'x7),
                                   ('|'x209),
                                   (' 'x160) );

    test_alignment( $QUERY_BIO_SEQ_5, $TARGET_BIO_SEQ, $E_QUERY_STR, $E_TARGET_STR, $E_MATCH_STR );

    const my $TARGET_SUBSTR => 'CCAGGGCTCCTTACATCTAATTTCCTTCAGAGCTGCTGGTATTTCGGAGACAGCTTTTGCAAATTCCACGCG';    
    
    test_alignment(
        $QUERY_BIO_SEQ_5,
        $TARGET_BIO_SEQ,
        '-------TCCTTACATCTAATTTCCTTCAGAGCTGCTGGTATTTCGGAGACAGCTTTTGCAAATTCCACGCG',
        $TARGET_SUBSTR,
        '       |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||',
        location_of( $TARGET_SUBSTR, $TARGET_BIO_SEQ )
    );
    
}

{
    note "Match of subseq with deletion (revcom)";

    const my $QUERY_BIO_SEQ_6 => bio_seq_from_str( 'query', <<'EOT' )->revcom;
AGCGAATGCTGGAGCTTACTGTATAGTTTGTGTTTGTGTGTGTGTGAAAAGAGGGGAGGGTTTCCCGGCTGG
AGGGAGTGAGACAGTGGGCAGGGAGCAGTTGGGGAAATGGAGCCAGAGCACCTGGCTCTCAGCTGGCCAGCT
TCCTTACATCTAATTTCCTTCAGAGCTGCTGGTATTTCGGAGACAGCTTTTGCAAATTCCACGCG
AGCTTCGACATGATGCTAAGCCTGACGTCCATATTCCACCTGTGCTCCATCGCGATCGACCGGTTTTATGCA
GTGTGTGACCCTTTGCACTACACCACCACCATGACGGTATCCATGATCAAGAGACTGCTGGCTTTTTGCTGG   
EOT
    
    const my $E_QUERY_STR => join( '',
                                   ('-'x160),
                                   $QUERY_BIO_SEQ_6->subseq(1, 209),
                                   ('-'x7),
                                   $QUERY_BIO_SEQ_6->subseq(210, $QUERY_BIO_SEQ_6->length),
                                   ('-'x72 ) );

    const my $E_TARGET_STR => $TARGET_BIO_SEQ->revcom->seq;

    const my $E_MATCH_STR => join( '',
                                   (' 'x160),
                                   ('|'x209),
                                   (' 'x7),
                                   ('|'x144),
                                   (' 'x72) );

    test_alignment( $QUERY_BIO_SEQ_6, $TARGET_BIO_SEQ, $E_QUERY_STR, $E_TARGET_STR, $E_MATCH_STR );

    const my $TARGET_SUBSTR => 'ATGTAAGGAGCCCTGGAGCTGGCCAGCTGAGAGCCAGGTGCTCTGGCTCCATTTCCCCAACTGCTCCCTGCC';

    test_alignment(
        $QUERY_BIO_SEQ_6,
        $TARGET_BIO_SEQ,
        'ATGTAAGGA-------AGCTGGCCAGCTGAGAGCCAGGTGCTCTGGCTCCATTTCCCCAACTGCTCCCTGCC',
        $TARGET_SUBSTR,
        '|||||||||       ||||||||||||||||||||||||||||||||||||||||||||||||||||||||',
        location_of( $TARGET_SUBSTR, $TARGET_BIO_SEQ )
    );
}

{
    note "Bugfix problematic alignment";
    
    const my $QUERY_BIO_SEQ_7 => bio_seq_from_str( 'query', <<'EOT' );
CATTAATTGCGTTGCGCCATCTCAGTACAGGTAGTGTACCACAGGCTATCCGCCCTATCT
CCTGAGTTAGATTAGGGGCATAGAAGCAGAGAGGGGACCAGAGCAGAAGAGTCTAGGGAA
GAAGCAGGGTTCTGGGCTTGAGATGAACATTCTCACTGAGGTCAGTGTGGTGGCATACAC
CTAGAACCCCAGCCCTTGGGAGACAGAAGTACCAAGACATTCGGTTCAAAACCAGCCTGG
TCACACAATCAGTTCCAGGCCAGTCTAATAGAGTAAGGGCCTGCTAGATAGAAAGACAGG
AAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGG
AAGGAAGGAAAAGATCAGACAAAAAGTAAGAGCACTACTCACAGTGACACCGGTGGTGGC
AGGATCTTTGCCTTCCATGAGTTTAAAAACACCTTGCAAAGCCTCATCTGGGTTCTTCCC
CTTGAAGCGCTTTTGGCCCAGCTCCTTCATTGCCTCTTGAAACTGTTGAAAGTTGATGGT
TCTGGCATTCTTGGCCCTGGCCAGTCAGACAGATATCCAGTAACTGTGGAGTGTGAAGTC
ATCACCTCCCAACATCTACCTTTTTTCTTAGTCGGGAATGGCCTATTTTATCCTGCCAAT
GAATGTTGAGAATAGGGACTGGGACAGTTCCCAGCACCTGCCAGATGCTCCTTATAAATC
TCCCATCTTTAGACTATGCCAGGCGTGCAG
EOT

    const my $TARGET_BIO_SEQ => bio_seq_from_str( 'target', <<'EOT' )->revcom;
AACTCCAAGGGCTCTAAAGTTGAACTGATGGCGAGCTCAGACCATAACTTCGTATAATGT
ATGCTATACGAAGTTATCATTAATTGCGTTGCGCCATCTCAGTACAGGTAGTGTACCACA
GGCTATCCGCCCTATCTCCTGAGTTAGATTAGGGGCATAGAAGCAGAGAGGGGACCAGAG
CAGAAGAGTCTAGGGAAGAAGCAGGGTTCTGGGCTTGAGATGAACATTCTCACTGAGGTC
AGTGTGGTGGCATACACCTAGAACCCCAGCCCTTGGGAGACAGAAGTACCAAGACATTCG
GTTCAAAACCAGCCTGGTCACACAATCAGTTCCAGGCCAGTCTAATAGAGTAAGGGCCTG
CTAGATAGAAAGACAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAG
GAAGGAAGGAAGGAAGGAAGGAAGGAAAAGATCAGACAAAAAGTAAGAGCACTACTCACA
GTGACACCGGTGGTGGCAGGATCTTTGCCTTCCATGAGTTTAAAAACACCTTGCAAAGCC
TCATCTGGGTTCTTCCCCTTGAAGCGCTTTTGGCCCAGCTCCTTCATTGCCTCTTGAAAC
TGTTGAAAGTTGATGGTTCTGGCATTCTTGGCCCTGGCCAGTCAGACAGAAATCCAGTAA
CTGTGGAGTGTGAAGTCATCACCTCCCAACATCTACCTTTTTTCTTAGTCGGGAATGGCC
TATTTTATCCTGCCAATGAATGTTGAGAATAGGGACTGGGACAGTTCCCAGCACCTGCCA
GATGCTCCTTATAAATCTCCCATCTTTAGAACTATGCCAGGCGGTGCCAGGCTGGTGGTG
CACGCCTTTAGTGCCTGTACTCAGGAGACAGGCTGGTGGGTCTCGGTGAGTTCTAGGTCA
GCCTGGTCCCGCCTACTGCGACTATAGAGATATCAACCACTTTGTACAAGAAAGCTGGGT
CTAGATATCTCGACATAACTTCGTATAATGTATGCTATACGAAGTTAT
EOT

    const my $E_QUERY_STR => '-----------------------------------------------------------------------------CATTAATTGCGTTGCGCCATCTCAGTACAGGTAGTGTACCACAGGCTATCCGCCCTATCTCCTGAGTTAGATTAGGGGCATAGAAGCAGAGAGGGGACCAGAGCAGAAGAGTCTAGGGAAGAAGCAGGGTTCTGGGCTTGAGATGAACATTCTCACTGAGGTCAGTGTGGTGGCATACACCTAGAACCCCAGCCCTTGGGAGACAGAAGTACCAAGACATTCGGTTCAAAACCAGCCTGGTCACACAATCAGTTCCAGGCCAGTCTAATAGAGTAAGGGCCTGCTAGATAGAAAGACAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAAAGATCAGACAAAAAGTAAGAGCACTACTCACAGTGACACCGGTGGTGGCAGGATCTTTGCCTTCCATGAGTTTAAAAACACCTTGCAAAGCCTCATCTGGGTTCTTCCCCTTGAAGCGCTTTTGGCCCAGCTCCTTCATTGCCTCTTGAAACTGTTGAAAGTTGATGGTTCTGGCATTCTTGGCCCTGGCCAGTCAGACAGATATCCAGTAACTGTGGAGTGTGAAGTCATCACCTCCCAACATCTACCTTTTTTCTTAGTCGGGAATGGCCTATTTTATCCTGCCAATGAATGTTGAGAATAGGGACTGGGACAGTTCCCAGCACCTGCCAGATGCTCCTTATAAATCTCCCATCTTTAG-ACTATGCCAGGC-GTGCAG-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------';

    const my $E_TARGET_STR => 'AACTCCAAGGGCTCTAAAGTTGAACTGATGGCGAGCTCAGACCATAACTTCGTATAATGTATGCTATACGAAGTTATCATTAATTGCGTTGCGCCATCTCAGTACAGGTAGTGTACCACAGGCTATCCGCCCTATCTCCTGAGTTAGATTAGGGGCATAGAAGCAGAGAGGGGACCAGAGCAGAAGAGTCTAGGGAAGAAGCAGGGTTCTGGGCTTGAGATGAACATTCTCACTGAGGTCAGTGTGGTGGCATACACCTAGAACCCCAGCCCTTGGGAGACAGAAGTACCAAGACATTCGGTTCAAAACCAGCCTGGTCACACAATCAGTTCCAGGCCAGTCTAATAGAGTAAGGGCCTGCTAGATAGAAAGACAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAGGAAAAGATCAGACAAAAAGTAAGAGCACTACTCACAGTGACACCGGTGGTGGCAGGATCTTTGCCTTCCATGAGTTTAAAAACACCTTGCAAAGCCTCATCTGGGTTCTTCCCCTTGAAGCGCTTTTGGCCCAGCTCCTTCATTGCCTCTTGAAACTGTTGAAAGTTGATGGTTCTGGCATTCTTGGCCCTGGCCAGTCAGACAGAAATCCAGTAACTGTGGAGTGTGAAGTCATCACCTCCCAACATCTACCTTTTTTCTTAGTCGGGAATGGCCTATTTTATCCTGCCAATGAATGTTGAGAATAGGGACTGGGACAGTTCCCAGCACCTGCCAGATGCTCCTTATAAATCTCCCATCTTTAGAACTATGCCAGGCGGTGCCAGGCTGGTGGTGCACGCCTTTAGTGCCTGTACTCAGGAGACAGGCTGGTGGGTCTCGGTGAGTTCTAGGTCAGCCTGGTCCCGCCTACTGCGACTATAGAGATATCAACCACTTTGTACAAGAAAGCTGGGTCTAGATATCTCGACATAACTTCGTATAATGTATGCTATACGAAGTTAT';

    const my $E_MATCH_STR => '                                                                             ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| |||||||||||| ||||                                                                                                                                                                                     ';
    
    test_alignment(
        $QUERY_BIO_SEQ_7,
        $TARGET_BIO_SEQ,
        $E_QUERY_STR,
        $E_TARGET_STR,
        $E_MATCH_STR
    );
}

done_testing;

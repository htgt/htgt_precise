#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use Bio::SeqIO;
use FindBin;
use File::Temp;
use HTGT::QC::Util::CigarParser;
use HTGT::QC::Util::AnalyzeAlignment;
use HTGT::QC::Config::Profile;
use Log::Log4perl ':easy';

Log::Log4perl->easy_init( $DEBUG );

sub read_seq {
    my ( $filename, $format ) = @_;

    if ( $filename !~ m{^/} ) {
        $filename = "$FindBin::Bin/data/$filename";
    }    

    my $seq_io = Bio::SeqIO->new( -file => $filename, -format => $format );

    my $seq = $seq_io->next_seq
        or die "Failed to read sequence from $filename";

    return $seq;
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

    return HTGT::QC::Util::CigarParser->new( strict_mode => 0 )->file_iterator( $fh )->next;
}


use_ok 'HTGT::QC::Util::Analysis';

my $profile = HTGT::QC::Config::Profile->new(
    profile_name => 'test',
    vector_stage => 'final',
    alignment_regions => {
        target_region_45_50 => {
            expected_strand => '-',
            start            => {
                primary_tag  => 'misc_feature',
                note         => 'Target Region',
                start        => 0,
            },
            end              => {
                primary_tag  => 'misc_feature',
                note         => 'Target Region',
                end          => 0,
            },
            min_match_length => '45/50',
        }
    },
    primers => {
        L1 => 'target_region_45_50',
    },
    pass_condition => 'L1',
    pre_filter_min_score => 1000,
    post_filter_min_primers => 1
);

ok my $target = read_seq( '381324#Ifitm2_intron_L1L2_GT0_LF2A_LacZ_BetactP_neo#L3L4_pD223_DTA_spec.gbk', 'genbank' ), 'read target seq';

ok my $query  = read_seq( 'PG00254_Z_1b08.p1kbL1.fasta' ), 'read query seq';

ok my $cigar = get_cigar( $query, $target ), 'get cigar';

{
    note "Bugfix alignment string mismatch";

    lives_ok {
        analyze_alignment( $target, $query, $cigar, $profile );
    } 'analyze_alignment';
}

{
    note "Strand check tests";

    my $passing_query = Bio::Seq->new(
        -alphabet => 'dna',
        -seq      => substr($target->{primary_seq}->seq, 18425, 300),
        -id       => $query->id,
    )->revcom;

    ok my $passing_cigar = get_cigar( $passing_query, $target ), 'get passing cigar';

    ok analyze_alignment( $target, $passing_query, $passing_cigar, $profile )->{pass}, 'strands match';

    $profile->{alignment_regions}{target_region_45_50}{expected_strand} = '+';

    ok !analyze_alignment( $target, $passing_query, $passing_cigar, $profile )->{pass}, 'strands do not match';
}

done_testing;

#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
use Test::Most;

BEGIN { use_ok 'TargetedTrap::IVSA::ConstructClone' }
BEGIN { use_ok 'TargetedTrap::IVSA::SeqRead' }

sub test_project {
    my %params = @_;
    my $seqreads
        = TargetedTrap::IVSA::SeqRead->new_from_fasta( $params{fasta} );

    diag "Testing project [$params{project}]";

    ok $seqreads, 'got the seqreads';

    $seqreads
        = [ sort { $a->well cmp $b->well || $a->clone_num <=> $b->clone_num }
            @{$seqreads} ];
    my $seqread = $seqreads->[0];
    my $clone
        = TargetedTrap::IVSA::ConstructClone->new_from_seqread( $seqread,
        $params{allele} );

    ok $clone, 'created a clone from the first seqread';
    ok $clone->clone_tag, '... and it has a clone_tag';
    is $clone->clone_tag, $params{clone_tag},   # should be a regexp me thinks
        '... and it has the expected clone_tag';
    is $clone->clone_tag, $seqread->clone_tag,
        '... and $clone->clone_tag eq $seqread->clone_tag';
}

my @projects = (
    {                                           # an allele project
        fasta     => '/nfs/repository/d0028/HEPD0638_2_A/HEPD0638_2_A.fa',
        project   => 'HEPD0638_2_A',
        clone_tag => 'HEPD0638_2_A_A02',
        allele    => 1,
    },
    {                                           # a 2nd allele project
        fasta     => '/nfs/repository/d0028/EPD00585_5_R/EPD00585_5_R.fa',
        project   => 'EPD00585_5_R',
        clone_tag => 'EPD00585_5_R_A01',
        allele    => 1,
    },
    {                                           # a 3rd allele project ...
        fasta     => '/nfs/repository/d0014/DEPD00522_1_B/DEPD00522_1_B.fa',
        project   => 'DEPD00522_1_B',
        clone_tag => 'DEPD00522_1_B_A01',
        allele    => 1,
    },
    {                                           # a 4th allele project ...
        fasta     => '/nfs/repository/d0014/DEPD0002_4_R/DEPD0002_4_R.fa',
        project   => 'DEPD0002_4_R',
        clone_tag => 'DEPD0002_4_R_A01',
        allele    => 1,
    },
    {                                           # a vector project ...
        fasta     => '/nfs/repository/d0002/PCS03007_A/PCS03007_A.fa',
        project   => 'PCS03007_A',
        clone_tag => 'PCS03007_A_A01_1',
        allele    => 0,
    },
    {                                           # a 2nd vector project ...
        fasta     => '/nfs/repository/d0028/HTGR03011_Y/HTGR03011_Y.fa',
        project   => 'HTGR03011_Y',
        clone_tag => 'HTGR03011_Y_A01_1',
        allele    => 0,
    },
    {                                           # a 3rd vector project ...
        fasta     => '/nfs/repository/d0002/PG00204_Z/PG00204_Z.fa',
        project   => 'PG00204_Z',
        clone_tag => 'PG00204_Z_A01_1',
        allele    => 0,
    },
    {                                           # a 4th vector project ...
        fasta     => '/nfs/repository/d0014/GRD0041_Z/GRD0041_Z.fa',
        project   => 'GRD0041_Z',
        clone_tag => 'GRD0041_Z_A02_1',
        allele    => 0,
    },
    {                                           # a wierd vector project ...
        fasta     => '/nfs/repository/d0002/MOHSA0001_B/MOHSA0001_B.fa',
        project   => 'MOHSA0001_B',
        clone_tag => 'MOHSA0001_B_A01_1',
        allele    => 0,
    },
);

test_project( %{$_} ) for @projects;

done_testing();

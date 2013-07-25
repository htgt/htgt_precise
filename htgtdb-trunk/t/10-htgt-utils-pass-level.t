#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use Const::Fast;
use List::MoreUtils qw(before after);
use Log::Log4perl;

Log::Log4perl->easy_init;

const my @LEVELS => qw( fail warn pass_lox pass5.3b pass3b passb pass3a pass1a passa pass2.2 pass2.1 pass1 pass );

die_on_fail;

use_ok 'HTGT::Utils::PassLevel', qw( cmp_pass_level qc_update_needed );

for my $this_level ( @LEVELS ) {
    for my $that_level ( before { $_ eq $this_level } @LEVELS ) {
        is cmp_pass_level( $this_level, $that_level ), 1, "$this_level is better than $that_level";
        ok !qc_update_needed( $this_level, $that_level ), "$this_level => $that_level QC update not needed";
    }
    for my $that_level ( $this_level ) {
        is cmp_pass_level( $this_level, $that_level ), 0, "$this_level is equivalent to $that_level";
        ok !qc_update_needed( $this_level, $that_level ), "$this_level => $that_level QC update not needed";
    }
    for my $that_level ( after { $_ eq $this_level } @LEVELS ) {
        is cmp_pass_level( $this_level, $that_level ), -1, "$this_level is worse than $that_level";
        ok qc_update_needed( $this_level, $that_level ), "$this_level => $that_level QC update needed";
    }
}

ok !qc_update_needed( 'bogusbogusbogus', 'pass' ), "No QC update needed for invalid pass_level";

done_testing;


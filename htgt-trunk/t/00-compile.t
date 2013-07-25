#!/usr/bin/env perl

use Test::More;
use Test::Strict;
use FindBin '$Bin';
use File::Find::Rule;

my $perlmod = File::Find::Rule->new;
$perlmod->name( '*.pm' );
$perlmod->file();
$perlmod->relative();

for ( $perlmod->in( "$Bin/../lib" ) ) {
    s{/}{::}g;
    s{\.pm$}{};
    use_ok( $_ );
}

my $perlscript = File::Find::Rule->new;
$perlscript->name( '*.pl' );
$perlscript->file();

for ( $perlscript->in( "$Bin/../script" ) ) {
    syntax_ok( $_ );
}

done_testing();


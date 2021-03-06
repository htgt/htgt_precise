#!perl

use strict;
use warnings;

use Test::More;
use File::Find;
use IPC::System::Simple qw( capturex );

my @modules;
find(
  sub {
    return if $File::Find::name !~ /\.pm\z/;
    my $found = $File::Find::name;
    $found =~ s{^lib/}{};
    $found =~ s{[/\\]}{::}g;
    $found =~ s/\.pm$//;
    push @modules, $found;
  },
  'lib',
);

my @scripts = grep { capturex( 'file', $_ ) =~ m/perl script text/ } glob "bin/*";

plan tests => scalar(@modules) + scalar(@scripts);
    
is( qx{ $^X -Ilib -M$_ -e "print '$_ ok'" }, "$_ ok", "$_ loaded ok" )
    for sort @modules;
    
SKIP: {
    eval "use Test::Script; 1;";
    skip "Test::Script needed to test script compilation", scalar(@scripts) if $@;
    foreach my $file ( @scripts ) {
        my $script = $file;
        $script =~ s!.*/!!;
        script_compiles_ok( $file, "$script script compiles" );
    }
}

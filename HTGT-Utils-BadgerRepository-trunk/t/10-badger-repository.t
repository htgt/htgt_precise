#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;

require_ok( 'HTGT::Utils::BadgerRepository' );

ok my $br = HTGT::Utils::BadgerRepository->new, 'new';
isa_ok $br, 'HTGT::Utils::BadgerRepository';
can_ok $br, 'dbh', 'search', 'exists', 'path';

ok not( $br->exists( 'garbagegarbagegarbage' ) ), 'garbage project does not exist';
ok not( $br->path( 'garbagegarbagegarbage' ) ), 'garbage project does not have a path';
ok not( @{ $br->search( 'garbagegarbagegarbage' ) } ), 'search for non-existent project returns empty list';

ok my $projects = $br->search( 'PCS001' ), 'search';
isa_ok $projects, 'ARRAY';
ok @{ $projects } > 0, 'search for PCS001 returns results';
my $p = pop @{ $projects };
ok $br->exists( $p ), "$p exists";
ok !$br->path( $p ), "$p has no path";

done_testing();



#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'HTGT' }

my $r = request('/welcome');
ok( $r->is_success, 'Request should succeed' )
    or diag( $r->status_line );

done_testing();

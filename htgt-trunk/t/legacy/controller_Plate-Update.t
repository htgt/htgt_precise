use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'HTGT' }
BEGIN { use_ok 'HTGT::Controller::Plate::Update' }

ok( request('/plate/update')->is_success, 'Request should succeed' );



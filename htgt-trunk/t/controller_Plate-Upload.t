use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'HTGT' }
BEGIN { use_ok 'HTGT::Controller::Plate::Upload' }

ok( request('/plate/upload')->is_success, 'Request should succeed' );
done_testing();

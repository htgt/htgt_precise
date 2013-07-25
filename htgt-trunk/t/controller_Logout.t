use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'HTGT' }
BEGIN { use_ok 'HTGT::Controller::Logout' }

ok( request('/logout')->is_redirect, 'Request should redirect' );
done_testing();

use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'HTGT' }
BEGIN { use_ok 'HTGT::Controller::Tools::FPData' }

ok( request('/tools/fpdata/MGI:1234')->is_success, 'Request should succeed' );
done_testing();

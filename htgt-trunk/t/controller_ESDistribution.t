use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'HTGT' }
BEGIN { use_ok 'HTGT::Controller::ESDistribution' }

ok( request('/esdistribution')->is_success, 'Request should succeed' );
done_testing();

use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'HTGT' }
BEGIN { use_ok 'HTGT::Controller::BespokeAllele' }

ok( request('/bespokeallele')->is_success, 'Request should succeed' );
done_testing();

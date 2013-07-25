use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'HTGT' }
BEGIN { use_ok 'HTGT::Controller::MutagenesisPredictions' }

ok( request('/mutagenesispredictions')->is_success, 'Request should succeed' );
done_testing();

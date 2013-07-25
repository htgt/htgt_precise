use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'HTGT' }
BEGIN { use_ok 'HTGT::Controller::Report::Curation' }

ok( request('/report/curation')->is_success, 'Request should succeed' );



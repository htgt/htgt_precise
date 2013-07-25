use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'HTGT' }
BEGIN { use_ok 'HTGT::Controller::Tools::GenotypingPrimers' }

ok( request('/tools/genotypingprimers/39216')->is_success, 'Request should succeed' );
ok( request('/tools/genotypingprimers/mirko_primers/210062')->is_success, 'mirko_prinmer request should success' );
my $error = request('/tools/genotypingprimers/mirko_primers/test')->content;
like( $error, qr/Invalid design_id: 'test'/, 'Request should return error' );
done_testing();

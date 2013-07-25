use strict;
use warnings;
use Test::More;
use FindBin;
use URI;

use lib "$FindBin::Bin/lib";

BEGIN {
    $ENV{HTGT_CONFIG} = "$FindBin::Bin/config/preauth.yml";
    $ENV{HTGT_DB} = 'eucomm_vector_esmt';
    use_ok 'Catalyst::Test', 'HTGT';
    use_ok 'HTGT::Controller::Plate';
}

redirects_to( "/plate", "/plate/list" );

ok( request('/plate/create')->is_success, 'Request should succeed' );

done_testing();

sub redirects_to {
    my ( $url, $dest ) = @_;

    my $response = request $url;

    ok $response->is_redirect, "$url should return redirect";

    my $uri = URI->new( $response->header( 'location' ) );
    is $uri->path, $dest, "$url should redirect to $dest";
}


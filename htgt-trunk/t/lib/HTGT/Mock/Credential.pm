package HTGT::Mock::Credential;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Authentication::Credential::Password';

sub check_password { 1 }

1;

__END__

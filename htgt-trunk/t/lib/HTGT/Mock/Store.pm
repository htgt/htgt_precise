package HTGT::Mock::Store;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Authentication::Store::Minimal';

use Catalyst::Authentication::User::Hash;

our $USER_ID    = 'mock_user';
our @USER_ROLES = qw( design edit eucomm eucomm_edit );

sub find_user {
    return Catalyst::Authentication::User::Hash->new( id => $USER_ID, roles => \@USER_ROLES );
}

1;

__END__

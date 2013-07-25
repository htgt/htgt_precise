#!/usr/bin/perl

use warnings;
use strict;

use WWW::Mechanize;
use HTTP::WebTest;
use LWP::UserAgent;
use Test::More;

use Data::Dumper;

my ($plate_id, $get_designs, $get_children, $recurse) = @ARGV;

if ( ! defined $plate_id ) {
    die "\n./$0:
    \t1. A plate id: e.g. 63 (give me something or you will see this again)
    \t2. 1 | 0: 1 = get designs,  0 = don't (default = 0)
    \t3. 1 | 0: 1 = get children, 0 = don't (default = 0)
    \t4. 1 | 0: 1 = recurse,      0 = don't (default = 0)
    
    Basically, if you don't tell me to do something, I will only check to see if the plate exists.
    
    \n";
}

my $plate_link = 'http://gtrap1a.internal.sanger.ac.uk:3001/plate/view?plate_id=' . $plate_id;

# Check to see if we can get a link
my $ua = LWP::UserAgent->new; $ua->env_proxy;
my $response = $ua->get($plate_link);

# Some one-liners
print "Plate_fetch_failed $plate_link => " . $response->status_line() . "\n" and exit, if $response->status_line() !~ /200/;

print "The plate exists - I am done now.\n" and exit, if ! $get_designs & ! $get_children;

my $link_objects = get_links( $get_designs, $get_children, $plate_link );

# If recurse is on then the system is going to get flogged.

if ( $recurse ) {
    die "This code needs to be written\n";
} else {
   test_links($link_objects);
}

 ########################
###### SUB ROUTINES ######
 ########################


sub test_links {
    my ( $objects ) = @_;
    my $number_of_tests = scalar @$objects;
    
    # We don't want to visit a link more than once
    my %explored_links = ();
   
    plan tests => $number_of_tests;
    
    my $correct = 0;
    
    for my $link ( @$objects ) {
        next if exists $explored_links{ $link->url() };
        $explored_links{ $link->url() } = 1;
        my $ua = LWP::UserAgent->new();
        my $response = $ua->get( $link->url() );
        my $bool = ok($response->status_line() =~ /200/, "200 Response for "  . $link->text() . " " . $link->url . "\n" );
        $correct += $bool;
    }
    
    print "---Summary:\n---Tests passed $correct/$number_of_tests Tests failed " . ( $number_of_tests - $correct ) . "/$number_of_tests\n\n";
}


sub get_links {
    # fortran-like variable names!
    my ( $d, $c, $l ) = @_;
    
    # The link is safe to fetch.  Startup the mechanize machinery
    my $m = new_mech();

    $m->get($l);
    
    my @links = ();
    
    for my $l ( $m->find_all_links() ) {
        if ( $d and $l->url =~ /.*\?.*design_id/ ) {
            push @links, $l;
        }
        if ( $c and $l->url =~ /view\?.*plate_id/ ) {
            push @links, $l;
        }
    }

    return( \@links );
    
}

sub new_mech {
     my $mech = WWW::Mechanize->new(
                               autocheck => 1,
                               agent=>"Evil Dan Bot",    # so we know what's going on
                               cookie_jar => undef
                               );                               
     $mech->agent_alias('Linux Konqueror'); # just to confuse issues!
     return($mech);
}
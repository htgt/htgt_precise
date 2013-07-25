#!/usr/bin/perl

use warnings;
use strict;

use WWW::Mechanize;
use HTTP::WebTest;
use LWP::Simple;
use Test::More;


plan tests => 1; # Tell Test::More that I'm planning 3 tests - this isn't true :)

my $danbot = new_mech(); # Can perl override methods - I am not sure.

# Need to change this to point at the release site on real test
my $plate_list_page   = 'http://gtrap1a.internal.sanger.ac.uk:3001/plate/show_list'; # The page will all the plates

my $list_of_plates    = get_links( $danbot, $plate_list_page, 0 ); 

my %tested_links = (); # I want to avoid nasty loops

for my $url ( @$list_of_plates ) {
    next if exists $tested_links{$url};

    #print "Plate $url\n";
    
    $tested_links{$url} = 1; # I don't want to test it again.

    my $page = get($url);

    my $status = ok(defined($page), "PLATE FETCH -> $url\n");

    next if $status != 1; 
    
    $danbot->get($url);
    
    print "\tURL: $url => ", $danbot->status, "\n";
    
    my $design_links = get_links( $danbot, $url, 1);
    
    for ( @$design_links ) {
        #print "\tDesign $_\n";
        my $design_head = head($_);
        
        ok(defined($design_head), "DESIGN FETCH -> $_");
        
        next unless $design_head;
        
        check_404_500( $_ );
        
        $danbot->get($_);
        my $ensembl_link = $danbot->find_link( text_regex => qr/View.*gene.*and.*design.*in.*Ensembl/i);
        
        if ( defined $ensembl_link ) {
            #print "ENS LINK: ", $ensembl_link->url(), "\n";
            #Need another test to check the ensembl link
        } 
        else {
            #warn "There was no ensembl link for $url -> $_\n";
        }   
    }
}

##########################
#####  SUB ROUTINES  #####
##########################

sub check_404_500 {
    my ( $url ) = @_;
    
    #modify these to get a report
    my $params = {
        on_response => 'YESNO',
    };
    
    my $tests = [
        {
            text_forbid => ["not found", "error", "request denied", "you have"],
            test_name => 'error_check',
            url       =>  $url,
        }
    ];

    my $test = new HTTP::WebTest;
    my $output = $test->run_tests( $tests, $params );
    return ( $output );
}


# Takes the mech and a URL.  Strips ALL the links out
sub get_links {
    my ( $mech, $url, $bool ) = @_;
    
    $mech->get( $url );
    
    if ( $danbot->status != 200 ) {
        my $fail;
        ok(defined($fail), "Get request\n");
    }
 
    my @links  = $mech->find_all_links();
    my @return = ();
    
    for ( @links ) {
        
        if ( $bool ) {
            next if $_->url !~ /design_id/ig;
            next unless $_->url =~ /\?/g;
            push @return, $_->url;
        } else {
            next if $_->url !~ /design|plate|report|$url/ig;
            next unless $_->url =~ /\?/g;
            push @return, $_->url;
            #unshift @return, "http://gtrap1a.internal.sanger.ac.uk:3001/plate/view?plate_id=fibble"; #a 500
            #unshift @return, "http://gtrap1a.internal.sanger.ac.uk:3001/plate/viewfibble";
        }
    }
    @links = (); #sadly perl won't free this up. meh!
    
    return( \@return );
}

# I don't know about perl overides - this method creates a new mech object
# with the desired specs i.e. danBot and Linux Konqueror.
sub new_mech {
     
     my $mech = WWW::Mechanize->new(
                               autocheck => 1,
                               agent=>"danBot",    # so we know what's going on
                               cookie_jar => undef
                               );                               
     $mech->agent_alias('Linux Konqueror'); # just to confuse issues!
     return($mech);
}

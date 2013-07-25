#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use Getopt::Long;

GetOptions( commit => \my $commit )
    or die "Usage: $0 [--commit]\n";

my $dbh = HTGT::DBFactory->dbi_connect( 'eucomm_vector' );

$dbh->begin_work;

my $sth = $dbh->prepare( 'insert into gr_valid_state (state, description) values (?, ?)' );

for ( <DATA> ) {
    chomp;
    my ( $state, $description ) = split " ", $_, 2;
    warn "Insert $state => $description\n";
    $sth->execute( $state, $description );
}

if ( $commit ) {
    $dbh->commit;
}
else {
    $dbh->rollback;
}

__DATA__
initial      Initial (unknown) state
no-pcs-qc    Active projects have no PCS QC    
rdr-c        Candidate for redesign/resynthesis recovery
rdr          In redesign/resynthesis recovery
gwr-c        Candidate for gateway recovery
gwr          In gateway recovery
acr-c        Candidate for alternate clone recovery (with alternates)
acr-c-no-alt Candidate for alternate clone recovery (no alternates)
acr          In alternate clone recovery
reseq-c      Candidate for resequencing recovery
reseq        In resequencing recovery
none         No recovery applicable

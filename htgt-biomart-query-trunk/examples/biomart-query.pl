#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::BioMart::QueryFactory;
use Data::Dumper;

my $qf = HTGT::BioMart::QueryFactory->new();

print "Available datasets:\n";
print Dumper $qf->datasets;

my $q = $qf->query( {
    dataset => 'dcc',
    filter  => { marker_symbol => 'art4' }
} );

print "Searching for art4:\n";
print Dumper $q->results;

print "Seraching for art4 or cbx1:\n";
$q->dataset(0)->filter( { marker_symbol => [ 'art4', 'cbx1' ] } );
print Dumper $q->results;

print "Constraining returned attributes:\n";
$q->dataset(0)->attributes( ['marker_symbol', 'mgi_accession_id' ] );
print Dumper $q->results;

# Reset to default
$q->dataset(0)->attributes( $q->dataset(0)->default_attributes );

# ...or retrieve them all
$q->dataset(0)->attributes( $q->dataset(0)->available_attributes );

#!/usr/bin/env perl -d
use strict;
use warnings FATAL => 'all';

use FindBin;
use lib "$FindBin::Bin/lib";
use Log::Log4perl qw( :levels );
use MyTest::HTGT::Utils::TaqMan::Design::Coordinates;

Log::Log4perl->easy_init( $DEBUG );

HTGT::Test::Class->runtests;

#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use FindBin;
use Log::Log4perl ':levels';

use lib "$FindBin::Bin/lib";

use MyTest::HTGT::Utils::DesignFinder::Transcript;

Log::Log4perl->easy_init( $FATAL );

Test::Class->runtests;


#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyTest::HTGT::Utils::Restriction::Analysis;
use Log::Log4perl ':levels';

Log::Log4perl->easy_init( $ERROR );

Test::Class->runtests;

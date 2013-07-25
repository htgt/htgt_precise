#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN { $ENV{TARMITS_CLIENT_CONF} = '/software/team87/brave_new_world/conf/tarmits-client-live.yml' }

use FindBin;
use lib "$FindBin::Bin/lib";
use MyTest::HTGT::Utils::SouthernBlot;
use Log::Log4perl ':easy';

Log::Log4perl->easy_init( $ERROR );

Test::Class->runtests;

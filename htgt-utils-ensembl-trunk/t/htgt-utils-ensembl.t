#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyTest::HTGT::Utils::EnsEMBL;

Test::Class->runtests;

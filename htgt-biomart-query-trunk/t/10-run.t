
use strict;
use warnings FATAL => 'all';

use lib qw( t/lib t/tests );

use MyTest::HTGT::BioMart::QueryFactory;
use MyTest::HTGT::BioMart::Query;

Test::Class->runtests();

use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'HTGT' }
BEGIN { use_ok 'HTGT::Controller::Tools::MutagenesisPrediction' }

action_ok '/tools/mutagenesis_prediction/project/35505/summary',    'Request for 35505 summary should succeed';
action_ok '/tools/mutagenesis_prediction/project/35505/detail',     'Request for 35505 detail should succeed';
action_ok '/tools/mutagenesis_prediction/project/35505/transcript', 'Request for 35505 transcript should succeed';


done_testing();

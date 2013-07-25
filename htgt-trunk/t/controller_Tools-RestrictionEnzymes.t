use strict;
use warnings;
use Test::More;
use HTML::TreeBuilder;
use Const::Fast;
use HTTP::Request::Common;
use Data::Dumper;

const my $PATH => '/tools/restrictionenzymes';

BEGIN { $ENV{TARMITS_CLIENT_CONF} = '/software/team87/brave_new_world/conf/tarmits-client-live.yml' }
BEGIN { use_ok 'Catalyst::Test', 'HTGT' }
BEGIN { use_ok 'HTGT::Controller::Tools::RestrictionEnzymes' }

# GET request, expect empty form and no errors
{
    my $res = request $PATH;
    ok $res->is_success, 'Request should succeed';

    my $html = HTML::TreeBuilder->new_from_content( $res->content );

    ok my $form = $html->look_down( '_tag', 'form', name => 'find_restriction_enzymes' ),
        'HTML has a form find_restriction_enzymes';

    ok $form->look_down( '_tag', 'input', 'name' => 'es_clone_name', value => '' ),
        'es_clone_name is empty';

    ok !$html->look_down( '_tag', 'div', class => 'error' ),
        'no errors';

    ok !$html->look_down( '_tag', 'table', id => 'fivep_enzymes' ),
        'no fivep enzymes table';

    ok !$html->look_down( '_tag', 'table', id => 'threep_enzymes' ),
        'no therep enzymes table';
}

# POST request, no ES clone name, expect empty form and error message
{
    my $res = request POST $PATH, [ find_restriction_enzymes => 1 ];
    ok $res->is_success, 'Request should succeed';

    my $html = HTML::TreeBuilder->new_from_content( $res->content );

    ok my $form = $html->look_down( '_tag', 'form', name => 'find_restriction_enzymes' ),
        'HTML has a form find_restriction_enzymes';

    ok $form->look_down( '_tag', 'input', name => 'es_clone_name', value => '' ),
        'es_clone_name is empty';

    ok my $errors = $html->look_down( '_tag', 'div', class => 'error' ),
        'got some errors';

    like $errors->as_text, qr/Invalid ES clone name: ''/, 'error message as expected';
    
    ok !$html->look_down( '_tag', 'table', id => 'fivep_enzymes' ),
        'no fivep enzymes table';

    ok !$html->look_down( '_tag', 'table', id => 'threep_enzymes' ),
        'no therep enzymes table';        
}

# POST request, ES clone name, invalid max_fragment_size, expect re-populated form and error message
{
    my $res = request POST $PATH, [ find_restriction_enzymes => 1, es_clone_name => 'foobarweewar', max_fragment_size => 'whizzbang' ];
    ok $res->is_success, 'Request should succeed';
    
    my $html = HTML::TreeBuilder->new_from_content( $res->content );

    ok my $form = $html->look_down( '_tag', 'form', name => 'find_restriction_enzymes' ),
        'HTML has a form find_restriction_enzymes';

    ok $form->look_down( '_tag', 'input', name => 'es_clone_name', value => 'foobarweewar' ),
        'es_clone_name is re-populated';

    # This is currently suppressed from the form as we don't allow users to override the default
    #ok $form->look_down( '_tag', 'input', name => 'max_fragment_size', value => 'whizzbang' ),
    #    'max_fragment_size is re-populated';
    
    ok my $errors = $html->look_down( '_tag', 'div', class => 'error' ),
        'got some errors';

    like $errors->as_text, qr/Invalid max fragment size: 'whizzbang'/, 'error message as expected';
    
    ok !$html->look_down( '_tag', 'table', id => 'fivep_enzymes' ),
        'no fivep enzymes table';

    ok !$html->look_down( '_tag', 'table', id => 'threep_enzymes' ),
        'no therep enzymes table';        
}

# POST request, ES clone does not exist, expect re-populated form and error message
{
    my $res = request POST $PATH, [ find_restriction_enzymes => 1, es_clone_name => 'foobarweewar' ];
    ok $res->is_success, 'Request should succeed';
    
    my $html = HTML::TreeBuilder->new_from_content( $res->content );

    ok my $form = $html->look_down( '_tag', 'form', name => 'find_restriction_enzymes' ),
        'HTML has a form find_restriction_enzymes';

    ok $form->look_down( '_tag', 'input', name => 'es_clone_name', value => 'foobarweewar' ),
        'es_clone_name is re-populated';

    ok my $errors = $html->look_down( '_tag', 'div', class => 'error' ),
        'got some errors';

    like $errors->as_text, qr/failed to retrieve allele sequence for foobarweewar/, 'error message as expected';
    
    ok !$html->look_down( '_tag', 'table', id => 'fivep_enzymes' ),
        'no fivep enzymes table';

    ok !$html->look_down( '_tag', 'table', id => 'threep_enzymes' ),
        'no therep enzymes table';        
}

# POST request, valid ES clone name, expect re-populated form, 3' and 5' enzyme tables, and no errors
{
    my $res = request POST $PATH, [ find_restriction_enzymes => 1, es_clone_name => 'EPD0385_1_C06' ];
    ok $res->is_success, 'Request should succeed';
    
    my $html = HTML::TreeBuilder->new_from_content( $res->content );

    ok my $form = $html->look_down( '_tag', 'form', name => 'find_restriction_enzymes' ),
        'HTML has a form find_restriction_enzymes';

    ok $form->look_down( '_tag', 'input', name => 'es_clone_name', value => 'EPD0385_1_C06' ),
        'es_clone_name is re-populated';

    ok !$html->look_down( '_tag', 'div', class => 'error' ),
        'got no errors';

    ok $html->look_down( '_tag', 'table', id => 'fivep_enzymes' ),
        'got a fivep enzymes table';

    ok $html->look_down( '_tag', 'table', id => 'threep_enzymes' ),
        'got a threep enzymes table';        
}

done_testing();

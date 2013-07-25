
package MyTest::HTGT::Utils::DesignChecker::Oligos;

use strict;
use warnings FATAL => 'all';

use base qw( HTGT::Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::UpdateDesign::ProjectGene' );
}

use Test::Most;
use HTGT::Utils::UpdateDesign::ProjectGene;
use Const::Fast;

sub startup : Tests(startup => 4) {
    my $test = shift;
    use_ok $test->class;
    
    my $schema = $test->eucomm_vector_schema;
    ok my $design = $schema->resultset('Design')->find( { design_id => 41064 } )
        , 'can get design';

    $test->{design} = $design;
    ok $test->{project} = $schema->resultset('Project')->find( { project_id => 27306 } )
        , 'can get project';
    ok $test->{o} = $test->class->new(
        schema               => $schema,
        design               => $design,
        new_mgi_accession_id => 'MGI:97487',
    ), '..create test object';
}

sub after : Tests(teardown => 1) {
    my $test = shift;
    ok ( !$test->{o}->clear_notes, '..clear design annotation notes');
}

sub constructor :Tests(2) {
    my $test = shift;
    
    can_ok $test->class, 'new';
    isa_ok $test->{o}, $test->class;
}

sub new_mgi_accession_id : Tests(2) {
    my $test = shift;

    throws_ok{
        $test->class->new(
            schema               => $test->eucomm_vector_schema,
            design               => $test->{design},
            new_mgi_accession_id => 'blah',
        )
    } qr/Invalid MGI accession id: blah/
        ,'dies when invalid mgi accession id value used';

    is $test->{o}->new_mgi_accession_id, 'MGI:97487', 'valid mgi accession id is okay';
}

sub new_mgi_gene_id : Tests(3) {
    my $test = shift;

    ok my $project_updater = $test->class->new(
        schema               => $test->eucomm_vector_schema,
        design               => $test->{design},
        new_mgi_accession_id => 'MGI:234234',
    ), 'create new project updater';

    throws_ok{
        $project_updater->new_mgi_gene_id
    } qr/We can not find mgi accession id: MGI:234234/
        ,'throws error when we can not find specified MGI accession id';

    is $test->{o}->new_mgi_gene_id, 9197, 'can get new mgi gene id from mgi accession id';
}

sub projects : Tests(6) {
    my $test = shift;

    is scalar( @{ $test->{o}->projects } ), 1, 'have one project for design';

    ok my $design = $test->eucomm_vector_schema->resultset('Design')->find( { design_id => 33642 } )
        , 'can get design with 3 projects';

    ok my $project_updater = $test->class->new(
        schema               => $test->eucomm_vector_schema,
        design               => $design,
        new_mgi_accession_id => 'MGI:234234',
    ), 'create new project updater';

    is scalar( @{ $project_updater->projects } ), 2, 'have three projects for this design';

    ok my $design2 = $test->eucomm_vector_schema->resultset('Design')->find( { design_id => 453788 } )
        , 'can get design with no projects';

    throws_ok{
        $test->class->new(
            schema               => $test->eucomm_vector_schema,
            design               => $design2,
            new_mgi_accession_id => 'MGI:234234',
        )->projects
    } qr/No projects linked to design/
        ,'dies when no projects linked to the design';
}

sub update : Tests(no_plan) {
    my $test = shift;
    my $current_mgi_gene = 'MGI:96915';
    my $new_mgi_gene = 'MGI:97487';


    ok my $project_updater = $test->class->new(
        schema               => $test->eucomm_vector_schema,
        design               => $test->{design},
        new_mgi_accession_id => $current_mgi_gene,
    ), 'create new project updater';

    is $test->{project}->mgi_gene->mgi_accession_id, $current_mgi_gene
        , 'correct mgi gene id for project at start';

    throws_ok{
        $project_updater->update
    } qr/Project already linked to this mgi gene/
        ,'dies if project already linked to the specified mgi gene';
    
    lives_ok{ $test->{o}->update } 'can call update on project updater object';

    ok $test->{project}->discard_changes, 'refresh project row';
    is $test->{project}->mgi_gene->mgi_accession_id, $new_mgi_gene
        ,'project has been updated to new mgi gene';

    my $note = $test->{o}->note('');
    is $note, "Project 27306 mgi accession id has been changed from $current_mgi_gene to $new_mgi_gene"
        , 'correct update note';

}
    
1;

__END__

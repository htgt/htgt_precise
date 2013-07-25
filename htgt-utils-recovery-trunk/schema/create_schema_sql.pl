#!/usr/bin/env perl
#
# $HeadURL$
# $LastChangedRevision$
# $LastChangedDate$
# $LastChangedBy$
#

use strict;
use warnings FATAL => 'all';

use YAML;

my @specs = YAML::LoadFile(shift);

my ( @drop, @sequences, @tables, @triggers, @indexes );

for my $tspec ( grep defined $_->{table}, @specs ) {

    my @cols;
    
    for my $c ( @{ $tspec->{columns} } ) {
        if ( $c->{pkauto} ) {
            push @drop, drop_pk_sequence( $c->{name} );
            push @sequences, create_pk_sequence( $c->{name} );
            push @triggers, create_pk_trigger( $tspec->{table}, $c->{name} );
        }
        push @cols, join( q{ }, '"' . uc($c->{name}) . '"', grep length, col_type( $c ), col_constraint( $c ) );
    }

    push @drop, sprintf( q{DROP TABLE "EUCOMM_VECTOR"."%s";}, uc $tspec->{table} );
    push @tables, sprintf( q{CREATE TABLE "EUCOMM_VECTOR"."%s" (%s);}, uc $tspec->{table}, join( q{, }, @cols ) );

    for my $ix ( @{ $tspec->{indexes} } ) {
        push @indexes, create_index( $tspec->{table}, $ix );
    }
}

for my $tspec ( grep defined $_->{trigger}, @specs ) {
    push @triggers, create_trigger( $tspec );
}

print map {chomp; "$_\n\n" } reverse( @drop ), @sequences, @tables, @triggers, @indexes;

sub col_constraint {
    my $col_spec = shift;

    my @constraint;

    unless ( $col_spec->{null} ) {
        push @constraint, 'NOT NULL';
    }
    
    if ( $col_spec->{pk} || $col_spec->{pkauto} ) {
        push @constraint, "PRIMARY KEY";
    }
    elsif ( $col_spec->{uniq} ) {
        push @constraint, 'UNIQUE';
    }

    if ( $col_spec->{fk} ) {
        push @constraint, 'REFERENCES ' . uc $col_spec->{fk};
    }

    join q{ }, @constraint;
}

sub col_type {
    my $col_spec = shift;

    $col_spec->{type} ||= 'num';

    my $type_spec;
    
    if ( $col_spec->{type} eq 'char' ) {
        $type_spec = sprintf( 'VARCHAR2(%d CHAR)', $col_spec->{size} );
    }
    elsif ( $col_spec->{type} eq 'timestamp' ) {
        $type_spec = 'TIMESTAMP';
    }
    elsif ( $col_spec->{type} eq 'num' ) {
        $type_spec = 'NUMBER';
    }
    else {
        die "invalid type: $col_spec->{type}";
    }

    return $type_spec;
}

sub sequence_name {
    my $col = uc shift;
    sprintf( q{S_%s}, uc( $col ) );
}

sub trigger_name {
    my $col = uc shift;
    sprintf( q{TR_%s}, uc( $col ) );
}

sub drop_pk_sequence {
    my $pk_name = uc shift;
    sprintf( q{DROP SEQUENCE "EUCOMM_VECTOR"."%s";}, sequence_name( $pk_name ) );
}

sub create_pk_sequence {
    my $pk_name = uc shift;
    sprintf( q{CREATE SEQUENCE "EUCOMM_VECTOR"."%s";}, sequence_name( $pk_name ) );
}

sub create_pk_trigger {
    my ( $table_name, $pk_name ) = map uc, @_;

    sprintf( <<'EOT', trigger_name( $pk_name ), $table_name, $pk_name, sequence_name( $pk_name ), $pk_name, trigger_name( $pk_name ) );  
CREATE OR REPLACE TRIGGER "EUCOMM_VECTOR"."%s"
    before insert on "%s"
        for each row begin
            if inserting then
                if :NEW."%s" is null then
                    select %s.nextval into :NEW."%s" from dual;
                end if;
            end if;
        end;
/
ALTER TRIGGER "EUCOMM_VECTOR"."%s" ENABLE;
EOT
}

sub create_trigger {
    my $tspec = shift;

    my $name = trigger_name( $tspec->{trigger} );

    <<"EOT";
CREATE OR REPLACE TRIGGER "EUCOMM_VECTOR"."$name"
    $tspec->{plsql}
/
ALTER TRIGGER "EUCOMM_VECTOR"."$name" ENABLE;
EOT
}

sub create_index {
    my ( $table_name, $ix_spec ) = @_;

    sprintf( 'CREATE %sINDEX %s ON %s ( %s );', map uc,
             ( $ix_spec->{uniq} ? 'UNIQUE ' : '' ),
             $ix_spec->{name},
             $table_name,
             join( q{,}, @{ $ix_spec->{columns} } ) );
}

__END__

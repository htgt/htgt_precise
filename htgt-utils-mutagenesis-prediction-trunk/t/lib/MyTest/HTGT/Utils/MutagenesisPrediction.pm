package MyTest::HTGT::Utils::MutagenesisPrediction;

use strict;
use warnings FATAL => 'all';

use base qw( Test::Class Class::Data::Inheritable );

use Test::Most;
use HTGT::Utils::MutagenesisPrediction;
use HTGT::Utils::EnsEMBL;
use Const::Fast;

use Data::Dump 'dd';

BEGIN {
    __PACKAGE__->mk_classdata( class => 'HTGT::Utils::MutagenesisPrediction' );
    __PACKAGE__->mk_classdata( 'genes' => {} );
    __PACKAGE__->mk_classdata( 'gene_name' );
    __PACKAGE__->mk_classdata( 'gene' );
    __PACKAGE__->mk_classdata( 'value' );
}

const my %TEST_DATA => (
    cbx1 => {
        transcript_id         => 'ENSMUST00000093943',
        target_chromosome     => 11,
        target_strand         => 1,
        target_region_start   => 96662422,
        target_region_end     => 96663068,
        upstream_exons        => [ qw(ENSMUSE00000761328 ENSMUSE00000858269) ],
        upstream_coding_exons => [ qw(ENSMUSE00000858269) ],
        floxed_exons          => [ qw(ENSMUSE00000110990) ],
        downstream_exons      => [ qw(ENSMUSE00000110987 ENSMUSE00000585970 ENSMUSE00000585969) ],
        is_frameshift         => 1,
        translation           => 'MGKKQNKKKVEEVLEEEEEEYVVEKVLDRRVVKGKVEYLLKWKGFS',
        ko_first_desc         => '46/185 amino acids (Chromodomain [25/50 aa])',
        deletes_first_coding_exon => 0,
        deletion_translation  => 'MGKKQNKKKVEEVLEEEEEEYVVEKVLDRRVVKGKVEYLLKWKGFSDQKSHEALPGVWSQSGLLELLTPVESSCS*',
        exon_3p_utr           => {
            ENSMUSE00000761328 => 195,
            ENSMUSE00000858269 => 0,
            ENSMUSE00000110990 => 0,
            ENSMUSE00000110987 => 0, 
            ENSMUSE00000585970 => 4,
            ENSMUSE00000585969 => 457,
        },
        exon_5p_utr           => {
            ENSMUSE00000761328 => 195,
            ENSMUSE00000858269 => 37,
            ENSMUSE00000110990 => 0,
            ENSMUSE00000110987 => 0, 
            ENSMUSE00000585970 => 0,
            ENSMUSE00000585969 => 457,
        },
        exon_domains          => {
            ENSMUSE00000761328 => [],
            ENSMUSE00000858269 => [ ['Chromodomain',  26, 50 ] ],
            ENSMUSE00000110990 => [ ['Chromodomain',  25, 50 ] ],
            ENSMUSE00000110987 => [ ['Chromo_shadow', 23, 58 ] ],
            ENSMUSE00000585970 => [ ['Chromo_shadow', 36, 58 ] ],
            ENSMUSE00000585969 => [],
        },
    },
    art4 => {
        transcript_id         => 'ENSMUST00000032341',
        target_chromosome     => 6,
        target_strand         => -1,
        target_region_start   => 136802729,
        target_region_end     => 136803939,
        upstream_exons        => [ qw(ENSMUSE00000196464) ],
        floxed_exons          => [ qw(ENSMUSE00000196466) ],
        downstream_exons      => [ qw(ENSMUSE00000313469) ],
        upstream_coding_exons => [ qw(ENSMUSE00000196464) ],
        is_frameshift         => 1,
        translation           => 'MALWLPGGQLTLLLLLWVQQTPAGSTE',
        ko_first_desc         => '27/300 amino acids (no protein domains)',
        deletes_first_coding_exon => 0,
        deletion_translation  => 'MALWLPGGQLTLLLLLWVQQTPAGSTELAARSAPLLQWLSAASFWSLLLSRPKAERKGIYWLLFKGAA*',
        exon_3p_utr           => {
            ENSMUSE00000196464 => 0,
            ENSMUSE00000196466 => 0,
            ENSMUSE00000313469 => 1124,
        },
        exon_5p_utr           => {
            ENSMUSE00000196464 => 357,
            ENSMUSE00000196466 => 0,
            ENSMUSE00000313469 => 0,
        },
        exon_domains          => {
            ENSMUSE00000196464 => [],
            ENSMUSE00000196466 => [ [ 'ART', 223, 223 ] ],
            ENSMUSE00000313469 => [],
        },
        peptide_domains       => {
            'APLKVDVDLTPDSFDDQYQGCSEQMVEELNQGDYFIKEVDTHKYYSRAWQKAHLTWLNQAKALPESMTPVHAVAIVVFTLNLNVSSDLAKAMARAAGSPGQYSQSFHFKYLHYYLTSAIQLLRKDSSTKNGSLCYKVYHGMKDVSIGANVGSTIRFGQFLSASLLKEETRVSGNQTLFTIFTCLGASVQDFSLRKEVLIPPYELFEVVSKSGSPKGDLINLRSAGNMSTYNCQLLK' => [ [ 'ART', 223, 223 ] ],
            'CSEQMVEELNQGDYFIKEVDTHKYYSRAWQKAHLTWLNQAKALPESMTPV' => [ [ 'ART', 50, 223 ] ]
        },
    },
    '2310003L06Rik-201' => {
        transcript_id         => 'ENSMUST00000007601',
        target_chromosome     => 5,
        target_region_start   => 88399664,
        target_region_end     => 88401895,
        target_strand         => 1,
        upstream_exons        => [ qw(ENSMUSE00000187658) ],
        floxed_exons          => [ qw(ENSMUSE00000187657 ENSMUSE00000223424) ],
        downstream_exons      => [],
        upstream_coding_exons => [],
        deletes_first_coding_exon => 1
    }
);

sub test_genes {
    my ( $test, $f, @required ) = @_;

    while ( my ( $gene_name, $gene_data ) = each %TEST_DATA ) {
        for my $r ( @required ) {
            return unless exists $gene_data->{$r};
        }
        $test->gene_name( $gene_name );
        $test->gene( $test->genes->{$gene_name} );
        $test->value( $gene_data );
        $f->();
    }
}

sub constructor :Tests(startup => 10) {
    my $test = shift;

    can_ok $test->class, 'new';
    
    my %CBX1 = %{ $TEST_DATA{cbx1} };
    
    my %args = (
        transcript => HTGT::Utils::EnsEMBL->transcript_adaptor->fetch_by_stable_id( $CBX1{transcript_id} ),
        target_chromosome   => $CBX1{target_chromosome},
        target_strand       => $CBX1{target_strand},
        target_region_start => $CBX1{target_region_start},
        target_region_end   => $CBX1{target_region_end}
    );
    
    for my $attr ( qw( transcript target_chromosome target_strand target_region_start target_region_end ) ) {
        my %this_args = %args;
        delete $this_args{ $attr };
        throws_ok { $test->class->new( \%this_args ) } qr/\QAttribute ($attr) is required\E/;
    }

    $test->test_genes(
        sub {
            ok my $g = $test->class->new(
                transcript => HTGT::Utils::EnsEMBL->transcript_adaptor->fetch_by_stable_id( $test->value->{transcript_id} ),
                target_chromosome   => $test->value->{target_chromosome},
                target_strand       => $test->value->{target_strand},
                target_region_start => $test->value->{target_region_start},
                target_region_end   => $test->value->{target_region_end}
            ), "constructor for " . $test->gene_name . " should succeed";            
            isa_ok $g, $test->class, '...the object it returns';
            $test->genes->{ $test->gene_name } = $g;
        }
    );
}

sub transcript :Tests {
    my $test = shift;

    can_ok $test->class, 'transcript';
    $test->test_genes(
        sub {
            ok my $t = $test->gene->transcript, 'transcript() should succeed';
            isa_ok $t, 'Bio::EnsEMBL::Transcript', '...the object it returns';
            is $t->stable_id, $test->value->{transcript_id};
        },
        'transcript_id'
    );
}

sub target_region_start :Tests {
    my $test = shift;

    can_ok $test->class, 'target_region_start';
    $test->test_genes(
        sub {
            is $test->gene->target_region_start, $test->value->{target_region_start};
        },
        'target_region_start'
    );
}

sub target_region_end :Tests {
    my $test = shift;

    can_ok $test->class, 'target_region_end';
    $test->test_genes(
        sub {
            is $test->gene->target_region_end, $test->value->{target_region_end};
        },
        'target_region_end'
    );    
}

sub target_chromosome :Tests {
    my $test = shift;

    can_ok $test->class, 'target_chromosome';
    $test->test_genes(
        sub {
            is $test->gene->target_chromosome, $test->value->{target_chromosome};
        },
        'target_chromosome'
    );    
}

sub target_strand :Tests {
    my $test = shift;

    can_ok $test->class, 'target_strand';
    $test->test_genes(
        sub {
            is $test->gene->target_strand, $test->value->{target_strand};
        },
        'target_strand'
    );    
}

sub upstream_exons :Tests {
    my $test = shift;

    can_ok $test->class, 'upstream_exons';
    $test->test_genes(
        sub {
            ok my @e = $test->gene->upstream_exons, 'the method should succeed';
            is_deeply [ map $_->stable_id, @e ], $test->value->{upstream_exons};
        },
        'upstream_exons'
    );    
}

sub floxed_exons :Tests {
    my $test = shift;

    can_ok $test->class, 'floxed_exons';
    $test->test_genes(
        sub {
            ok my @e = $test->gene->floxed_exons, 'the method should succeed for ' . $test->gene_name;
            is_deeply [ map $_->stable_id, @e ], $test->value->{floxed_exons};
        },
        'floxed_exons'
    );    
}

sub downstream_exons :Tests {
    my $test = shift;

    can_ok $test->class, 'downstream_exons';
    $test->test_genes(
        sub {
            is_deeply [ map $_->stable_id, $test->gene->downstream_exons ], $test->value->{downstream_exons},
                'downstream_exons for ' . $test->gene_name;
        },
        'downstream_exons'
    );
}

sub upstream_coding_exons :Tests {
    my $test = shift;

    can_ok $test->class, 'upstream_coding_exons';
    $test->test_genes(
        sub {
            is_deeply [ map $_->stable_id, $test->gene->upstream_coding_exons ], $test->value->{upstream_coding_exons},
                "upstream coding exons for " . $test->gene_name;
        },
        'upstream_coding_exons'
    );
}

sub deletes_first_coding_exon :Tests {
    my $test = shift;

    can_ok $test->class, 'deletes_first_coding_exon';
    $test->test_genes(
        sub {
            ok not( $test->gene->deletes_first_coding_exon xor $test->value->{deletes_first_coding_exon} ),
                "deletes_first_coding_exon for " . $test->gene_name;
        },
        'deletes_first_coding_exon'
    );
}

sub is_frameshift :Tests {    
    my $test = shift;

    $test->test_genes(
        sub {
             ok not( $test->gene->floxed_transcript->is_frameshift xor $test->value->{is_frameshift} );
         },
         'is_frameshift'
     );
}

sub domains_for_peptide :Tests {
    my $test = shift;

    can_ok $test->class, 'domains_for_peptide';

    $test->test_genes(
        sub {
            defined( my $domains_for = $test->value->{peptide_domains} ) or return;
            for my $peptide ( keys %{$domains_for} ) {
                my @domains = map [ $_->{domain}->idesc, @{$_->{amino_acids}} ], @{ $test->gene->domains_for_peptide( $peptide ) };
                is_deeply \@domains, $domains_for->{$peptide}, 'domains for peptide';                
            }
        }
    );
}
    
sub domains_for_exon :Tests {
    my $test = shift;    

    can_ok $test->class, 'domains_for_exon';

    $test->test_genes(
        sub {
            my $domains_for = $test->value->{exon_domains};            
            for my $exon ( keys %{$domains_for} ) {
                my @domains = map [ $_->{domain}->idesc, @{$_->{amino_acids}} ], @{ $test->gene->domains_for_exon( $exon ) };
                is_deeply \@domains, $domains_for->{$exon}, "domains for $exon";
            }
        },
        'exon_domains'
    );    
}
  
sub exon_3p_utr :Tests {
    my $test = shift;

    can_ok $test->class, 'exon_3p_utr';
    
    $test->test_genes(
        sub {
            my $utr_for = $test->value->{exon_3p_utr};                     
            for my $exon ( @{ $test->gene->transcript->get_all_Exons } ) {
                is $test->gene->exon_3p_utr( $exon ), $utr_for->{ $exon->stable_id }, $exon->stable_id . " 3' UTR";
            }
        },
        'exon_3p_utr'
    );    
}

sub exon_5p_utr :Tests {
    my $test = shift;

    can_ok $test->class, 'exon_5p_utr';

    $test->test_genes(
        sub {
            my $utr_for = $test->value->{exon_5p_utr};
            for my $exon ( @{ $test->gene->transcript->get_all_Exons } ) {
                is $test->gene->exon_5p_utr( $exon ), $utr_for->{ $exon->stable_id }, $exon->stable_id . " 5' UTR";
            }                
        },
        'exon_5p_utr'
    );    
}

1;

__END__

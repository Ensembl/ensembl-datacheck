=head1 LICENSE

Copyright [2018-2019] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the 'License');
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an 'AS IS' BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::EnsEMBL::DataCheck::Checks::GeneBiotypes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'GeneBiotypes',
  DESCRIPTION => 'Genes and transcripts have valid biotypes',
  GROUPS      => ['core', 'corelike', 'geneset'],
  DB_TYPES    => ['core', 'otherfeatures'],
  TABLES      => ['biotype', 'coord_system', 'gene', 'seq_region', 'transcript']
};

sub tests {
  my ($self) = @_;

  # Check that biotypes in gene and transcript tables are valid.
  $self->biotypes('gene');
  $self->biotypes('transcript');

  # Check that biotypes are consistent between genes and transcripts.
  $self->biotype_groups();
}

sub biotypes {
  my ($self, $feature) = @_;
  # Use SQL rather than the API, because the latter does not have
  # an easy way to check for db_type; even if it did, it might not
  # work if it's not correct in the db anyway, so SQL is the way to go.

  my $species_id = $self->dba->species_id;
  my $db_type = $self->dba->group;

  my $desc = ucfirst($feature)."s have valid biotypes";
  my $diag = "Invalid biotype for $db_type $feature";
  my $sql = qq/
    SELECT t1.stable_id FROM
      $feature t1 INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id) LEFT OUTER JOIN
      biotype t2 ON (
        t1.biotype = t2.name AND
        t2.object_type = '$feature' AND
        FIND_IN_SET('$db_type', db_type)
      )
    WHERE
      t1.biotype IS NOT NULL AND
      t2.name IS NULL AND
      coord_system.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

sub biotype_groups {
  my ($self, $feature) = @_;
  # Use API rather than SQL, because the queries would be fiendish: joins
  # across 6+ tables, 5+ constraints. The API is easily an order of
  # magnitude slower, maybe two. But we're talking a few minutes here,
  # compared to a few seconds, and I think it's worth taking the hit on
  # runtime for the sake of readability and maintainability.

  my $ba = $self->dba->get_adaptor('Biotype');
  my $biotype_objs = $ba->fetch_all();
  my %groups = map { $_->name => $_->biotype_group } @$biotype_objs;

  # It's too verbose to report all the OKs, we'd be spewing out
  # millions of lines of text. So accumulate errors in arrays
  # and then test whether they are empty at the end.
  my @polymorphic_mismatch;
  my @group_mismatch;
  my @pseudogene_mismatch;

  my $ga = $self->dba->get_adaptor("Gene");
  foreach my $gene ( @{ $ga->fetch_all } ) {
    my $gene_group = $groups{$gene->biotype};

    # Can't do anything sensible if a group isn't defined
    next if $gene_group eq 'undefined';

    my @transcripts         = @{ $gene->get_all_Transcripts };
    my %transcript_biotypes = map { $_->biotype => 1 } @transcripts;
    my %transcript_groups   = map { $groups{$_->biotype} => 1 } @transcripts;
    # We don't need any further transcript-related information,
    # so flush to prevent excessive memory use.
    $gene->flush_Transcripts();

    # Test 1: genes have at least one transcript with a matching biotype group
    if (!exists $transcript_groups{$gene_group}) {
      push @group_mismatch, $gene->stable_id;
    }

    # Test 2: "pseudogene" genes do not have coding transcripts
    if ($gene_group eq 'pseudogene') {
      foreach (keys %transcript_groups) {
        if ($_ eq 'coding') {
          push @pseudogene_mismatch, $gene->stable_id;
          last;
        }
      }
    }

    # Test 3: "polymorphic_pseudogene" genes have at least one polymorphic_pseudogene transcript
    if ($gene->biotype eq 'polymorphic_pseudogene') {
      if (!exists $transcript_biotypes{'polymorphic_pseudogene'}) {
        push @polymorphic_mismatch, $gene->stable_id;
      }
    }
  }

  my $desc_1 = 'genes have at least one transcript with a matching biotype group';
  is(scalar(@group_mismatch), 0, $desc_1);

  my $desc_2 = '"pseudogene" genes do not have coding transcripts';
  is(scalar(@pseudogene_mismatch), 0, $desc_2);

  my $desc_3 = '"polymorphic_pseudogene" genes have at least one polymorphic_pseudogene transcript';
  is(scalar(@polymorphic_mismatch), 0, $desc_3);
}

1;

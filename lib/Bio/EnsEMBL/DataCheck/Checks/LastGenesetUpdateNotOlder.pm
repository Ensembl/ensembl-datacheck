=head1 LICENSE

Copyright [2018-2026] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::LastGenesetUpdateNotOlder;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::Utils::URI qw/parse_uri/;
use DBI;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'LastGenesetUpdateNotOlder',
  DESCRIPTION    => 'genebuild.last_geneset_update is not older than one already on the target server',
  GROUPS         => ['core', 'meta'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['meta'],
  FORCE          => 1
};

sub skip_tests {
  my ($self) = @_;

  if ($self->dba->dbc->dbname =~ /collection/) {
    return (1, "Collection databases are not checked");
  }

  unless (defined $self->server_uri && scalar(@{$self->server_uri})) {
    return (1, "No target server given with 'server_uri'");
  }
}

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");
  my $production_name = $mca->single_value_by_key('organism.production_name') //
                        $mca->single_value_by_key('species.production_name');
  my $update = $mca->single_value_by_key('genebuild.last_geneset_update');

  my $desc_1 = "Production name and genebuild.last_geneset_update exist";
  ok(defined $production_name && defined $update, $desc_1);
  return unless defined $production_name && defined $update;

  my $submitted = normalise($update);
  my $desc_2 = "genebuild.last_geneset_update '$update' is in YYYY_MM format";
  ok(defined $submitted, $desc_2);
  return unless defined $submitted;

  my $targets = $self->target_updates($production_name);

  # Re-submitting the same gene build date is allowed; only older ones fail.
  my @newer = grep { $$targets{$_} > $submitted } sort keys %$targets;

  my $desc_3 = "genebuild.last_geneset_update '$update' for $production_name ".
               "is not older than any already on the target server";
  ok(scalar(@newer) == 0, $desc_3) or
    diag(join("\n", map { "Newer gene build date on target: $_ ($$targets{$_})" } @newer));
}

sub target_updates {
  my ($self, $production_name) = @_;

  my $own_dbname = $self->dba->dbc->dbname;
  my $own_host   = $self->dba->dbc->host;
  my $own_port   = $self->dba->dbc->port;

  # Database name => normalised genebuild.last_geneset_update
  my %updates;

  foreach my $server_uri (@{ $self->server_uri }) {
    my $uri = parse_uri($server_uri);
    my $dsn = "DBI:mysql:host=".$uri->host.";port=".$uri->port;
    my $dbh = DBI->connect($dsn, $uri->user, $uri->pass, { PrintError => 0, RaiseError => 1 });

    my $dbnames = $dbh->selectcol_arrayref("SHOW DATABASES LIKE '%\\_core\\_%'");

    foreach my $dbname (@$dbnames) {
      # Don't compare the submitted database with itself.
      next if $dbname eq $own_dbname && $uri->host eq $own_host && $uri->port == $own_port;

      # Older databases only have species.production_name.
      my $sql = qq/
        SELECT u.meta_value FROM
          `$dbname`.meta p INNER JOIN
          `$dbname`.meta u USING (species_id)
        WHERE
          p.meta_key IN ('organism.production_name', 'species.production_name') AND
          p.meta_value = ? AND
          u.meta_key = 'genebuild.last_geneset_update'
      /;

      # Databases without a meta table, or with an unexpected
      # schema, cannot hold an earlier submission, so ignore them.
      my $values = eval { $dbh->selectcol_arrayref($sql, undef, $production_name) };
      next unless defined $values && scalar(@$values);

      # Malformed dates on the target are its own datachecks' concern.
      my $key = $uri->host.":".$uri->port."/$dbname";
      foreach my $normalised (grep { defined } map { normalise($_) } @$values) {
        $updates{$key} = $normalised
          if !exists $updates{$key} || $normalised > $updates{$key};
      }
    }

    $dbh->disconnect;
  }

  return \%updates;
}

# Accept YYYY_MM, YYYY-MM or YYYYMM, e.g. 2026_04 => 202604
sub normalise {
  my ($value) = @_;

  return unless defined $value;
  (my $normalised = $value) =~ s/\D//g;

  return $normalised =~ /^\d{4}(0[1-9]|1[0-2])$/ ? $normalised : undef;
}

1;

#!/usr/bin/env perl

use Data::Dumper;
use File::Temp qw();
use Test::More;
use above 'Genome';

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

my $tmpdir = File::Temp->newdir();
my $output_file = "$tmpdir/clin.tsv";
my $expected_file = __FILE__ . ".clean.expected";
my $expected_md5sum = '124f9d890b69762e4a7402810b60566f';

my $pkg = 'Genome::Model::PhenotypeCorrelation::ClinicalData';
use_ok($pkg);

my $nomenclature = Genome::Nomenclature->create(
    name => "TestNomenclature",
    empty_equivalent => "NA",
);
my @samples = setup_samples($nomenclature);

my $obj = $pkg->from_database($nomenclature, @samples);

my @sample_names = sort $obj->sample_names;
is_deeply(\@sample_names, [sort(map({$_->name} @samples))], "sample names match");

my @expected_attrs = map {"attr$_"} 1..10;
my %expected_attr_types = map {("attr$_" => {categorical => 1})} 1..10;
is($obj->sample_count, 10, "correct number of samples");
is_deeply([$obj->attributes], \@expected_attrs, "correct attribute names")
    or diag("Expected:\n". Dumper(\@expected_attrs) . "Actual:\n" . Dumper([$obj->attributes]));
is_deeply($obj->attribute_types, \%expected_attr_types, "correct attribute types")
    or diag("Expected:\n". Dumper(\%expected_attr_types) . "Actual:\n" . Dumper($obj->attribute_types));

# test getting attributes for a given sample
for my $i (0..$#samples) {
    my $sample_name = $samples[$i]->name;
    my @actual = map { $obj->attribute_values_for_samples("attr$_", $sample_name) || "NA" } 1..10;
    my @expected = ("NA") x 10;
    $expected[$i] = "value" . ($i+1);
    is_deeply(\@actual, \@expected, "correct values for $sample_name");
}

for my $i (1..10) {
    my @actual = map {$_ || "NA" } @{$obj->attribute_values("attr$i")};
    my @expected = ("NA") x 10;
    $expected[$i-1] = "value" . ($i);
    is_deeply(\@actual, \@expected, "correct values for attribute $i");
}


my $md5sum = $obj->to_file($output_file, missing_string => '.');
is($md5sum, $expected_md5sum, "md5sum is as expected");

my $diff = Genome::Sys->diff_file_vs_file($output_file, $expected_file);
ok(!$diff, 'output matched expected result')
    or diag("diff results:\n" . $diff);

$obj = undef;
# now load the file, and save it again to make sure we get the same result
my $obj2 = $pkg->from_file($output_file, missing_string => ".");
is($obj2->sample_count, 10, "correct number of samples");
is_deeply([$obj2->attributes], \@expected_attrs, "correct attribute names")
    or diag("Expected:\n". Dumper(\@expected_attrs) . "Actual:\n" . Dumper([$obj->attributes]));
is_deeply($obj2->attribute_types, \%expected_attr_types, "correct attribute types")
    or diag("Expected:\n". Dumper(\%expected_attr_types) . "Actual:\n" . Dumper($obj->attribute_types));

my $output_file2 = "$output_file.again";
my $md5sum2 = $obj2->to_file($output_file2, missing_string => '.');
is($md5sum2, $expected_md5sum, "md5sum is as expected");

$diff = Genome::Sys->diff_file_vs_file($output_file2, $expected_file);
ok(!$diff, 'output matched expected result')
    or diag("diff results:\n" . $diff);



done_testing();

sub setup_samples {
    my $nomenclature = shift;

    my $taxon = Genome::Taxon->get(name => 'human');
    my @samples;

    # Create 10 samples, each with 1 unique attribute
    for my $i (1..10) {
        my $field = Genome::Nomenclature::Field->create(
            name => "attr$i",
            type => "string",
            nomenclature => $nomenclature,
        );

        my $individual = Genome::Individual->create(name => "test-patient$i", common_name => 'testpat$i', taxon => $taxon);
        my $sample = Genome::Sample->create(name => "test-patient$i", common_name => 'tumor$i', source => $individual);
        my $attr = Genome::SubjectAttribute->create(
            subject_id => $individual->id,
            attribute_label => "attr$i",
            attribute_value => "value$i",
            nomenclature_field => $field,
            nomenclature => $nomenclature->name,
        );

        push(@samples, $sample);
    }

    return @samples;
}

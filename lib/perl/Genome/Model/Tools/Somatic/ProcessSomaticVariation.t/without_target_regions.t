#!/usr/bin/env genome-perl

use strict;
use warnings;

use above 'Genome';
use Genome::Model::Tools::Somatic::TestHelpers qw( create_test_objects run_test );

my $TEST_DATA_VERSION = 9;

my $pkg = 'Genome::Model::Tools::Somatic::ProcessSomaticVariation';
use_ok($pkg);
my $main_dir = Genome::Utility::Test->data_dir_ok($pkg, $TEST_DATA_VERSION);

my $input_dir = File::Spec->join($main_dir, "input");

my $somatic_variation_build = create_test_objects($main_dir);

my $feature_list = Genome::FeatureList->create(
    name              => 'ProcessSomaticVariation test',
    format            => 'true-BED',
    content_type      => 'targeted',
    description       => 'test target region set name feature list for ProcessSomaticVariation',
    file_path         => "$input_dir/target_regions.bed",
    file_content_hash => Genome::Sys->md5sum( "$input_dir/target_regions.bed" ),
);

Genome::Model::Build::Input->create(
    build_id         => $somatic_variation_build->tumor_build->id,
    value_class_name => 'UR::Value',
    value_id         => $feature_list->name,
    name             => 'target_region_set_name',
);

run_test(
    $pkg,
    $main_dir,
    somatic_variation_build => $somatic_variation_build,
    igv_reference_name      => 'b37',
);

done_testing();

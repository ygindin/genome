#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{NO_LSF} = 1;
};

use above "Genome";
use Genome::Utility::Vcf 'diff_vcf_file_vs_file';

use Test::More;

my $cmd_class = 'Genome::Model::Tools::Joinx::SafeVcfMerge';
use_ok($cmd_class) or die;


# setup
my @input_files = map {sprintf("%s.d/input%s.clean.vcf", __FILE__,  $_)} (1..5);
my $expected_output = sprintf("%s.d/expected.clean.vcf", __FILE__);
my $temp_dir = Genome::Sys->create_temp_directory();
my $output_file = join("/", $temp_dir, "output.vcf");


# test with leaving intermediate files
my $cmd = $cmd_class->create(
    input_files => \@input_files,
    merge_samples => 1,
    working_directory => $temp_dir,
    max_files_per_merge => 2,
    remove_intermediate_files => 0,
    output_file => $output_file,
);
my $result = $cmd->execute();
ok($result, 'command executed');
ok(-f join("/", $temp_dir, 'output_0.vcf'), 'group_1 merge exists');
ok(-f join("/", $temp_dir, 'output_1.vcf'), 'group_2 merge exists');
ok(-f $output_file, 'output file exists');
my $diff = diff_vcf_file_vs_file($output_file, $expected_output);
ok(!$diff, 'got expected output') or diag($diff);


# test with removing intermediate files
$temp_dir = Genome::Sys->create_temp_directory();
$output_file = join("/", $temp_dir, "output.vcf");
$cmd = $cmd_class->create(
    input_files => \@input_files,
    merge_samples => 1,
    working_directory => $temp_dir,
    max_files_per_merge => 2,
    remove_intermediate_files => 1,
    output_file => $output_file,
);
$result = $cmd->execute();
ok($result, 'command executed');
ok(!-f join("/", $temp_dir, 'output_0.vcf'), 'group_1 merge file removed');
ok(!-f join("/", $temp_dir, 'output_1.vcf'), 'group_2 merge file removed');
ok(-f $output_file, 'output file exists');
$diff = diff_vcf_file_vs_file($output_file, $expected_output);
ok(!$diff, 'got expected output') or diag($diff);

done_testing();

1;

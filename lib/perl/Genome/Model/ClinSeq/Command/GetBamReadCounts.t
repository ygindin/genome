#!/usr/bin/env genome-perl

#Written by Malachi Griffith

use strict;
use warnings;
use File::Basename;
use Cwd 'abs_path';

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{NO_LSF} = 1;
};

use above "Genome";
use Test::More;
use Genome::Model::ClinSeq::Command::GetBamReadCounts;
use Data::Dumper;

if ($] < 5.010) {
  plan skip_all => "this test is only runnable on perl 5.10+"
}
plan tests => 12;

#Create a temp dir for results
my $temp_dir = Genome::Sys->create_temp_directory();
ok($temp_dir, "created temp directory: $temp_dir");

#Define an output file where read counts will be stored
my $output_file = $temp_dir . "/GetBamReadCount.t.output";

#Determine the current code path
my $code_dir = abs_path(File::Basename::dirname(__FILE__));
ok(-e $code_dir, "Found current code dir: $code_dir");

#Define the path to test input and expected results files
my $expected_data_directory = $ENV{"GENOME_TEST_INPUTS"} . '/Genome-Model-ClinSeq-Command-GetBamReadCounts/2013-01-31';
ok(-e $expected_data_directory, "Found expected data directory: $expected_data_directory");

#Check for input positions file
my $input_positions_file = $expected_data_directory . "/" . "GetBamReadCounts.t.input";
ok(-e $input_positions_file, "Found expected input positions file: GetBamReadCounts.t.input");

#Check for expected results file
my $expected_result_file = $expected_data_directory . "/" . "GetBamReadCounts.t.expected";
ok(-e $expected_result_file, "Found expected results file: GetBamReadCounts.t.expected");

#Create a test case based on an existing clinseq build: 126680687 of 2887519760 (AML103)
#Use the input Somatic Variation and RNA-seq builds from that ClinSeq build for testing here

#WGS somatic variation build
my $wgs_som_var_build_id = '129396794';
my $wgs_som_var_build = Genome::Model::Build->get($wgs_som_var_build_id);
ok($wgs_som_var_build, "Obtained a wgs somatic variation build from id: $wgs_som_var_build_id");

#Exome somatic variation build
my $exome_som_var_build_id = '129396799';
my $exome_som_var_build = Genome::Model::Build->get($exome_som_var_build_id);
ok($exome_som_var_build, "Obtained an exome somatic variation build from id: $exome_som_var_build_id");

#RNA-seq tumor build
my $rna_seq_tumor_build_id = '129396808';
my $rna_seq_tumor_build = Genome::Model::Build->get($rna_seq_tumor_build_id);
ok($rna_seq_tumor_build, "Obtained an rna seq tumor build from id: $rna_seq_tumor_build_id");

#Running a test of get-bam-read-counts at the command line looks something like this:
#/usr/bin/perl -S genome model clin-seq get-bam-read-counts --positions-file=/tmp/bam-read-counts-test/snvs.hq.tier1.v1.annotated.compact.tsv --ensembl-version=58 --output-file=/tmp/bam-read-counts-test/snvs.hq.tier1.v1.annotated.compact.readcounts.tsv --wgs-som-var-build=119390903  --exome-som-var-build='119391641' --rna-seq-tumor-build='115909698'

#Running a test of get-bam-read-counts by calling the code method looks something like this:
my $verbose = 0;
my @params = ('positions_file' => $input_positions_file);
push (@params, ('wgs_som_var_build' => $wgs_som_var_build));
push (@params, ('exome_som_var_build' => $exome_som_var_build));
push (@params, ('rna_seq_tumor_build' => $rna_seq_tumor_build));
push (@params, ('output_file' => $output_file));
push (@params, ('verbose' => $verbose));
my $bam_rc_cmd = Genome::Model::ClinSeq::Command::GetBamReadCounts->create(@params);
ok($bam_rc_cmd, "Created get-bam-read-counts command");
my $r = $bam_rc_cmd->execute();
ok($r, "Executed get-bam-read-counts successfully");

#Look for result file
ok(-e $expected_result_file, "Found a result file in the temp dir: $expected_result_file");

#Diff the new result against the old
my @diff = `diff $expected_result_file $output_file`;
is(@diff, 0, "no differences from expected results and actual")
  or do { 
      diag("differences are:");
      diag(@diff);
      if (-e "/tmp/last-get-bam-read-counts-test-result"){
        Genome::Sys->shellcmd(cmd => "rm -fr /tmp/last-get-bam-read-counts-test-result");
      }
      Genome::Sys->shellcmd(cmd => "mv $temp_dir /tmp/last-get-bam-read-counts-test-result");
  };

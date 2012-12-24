#!/gsc/bin/perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;

use_ok("Genome::Model::Tools::Validation::LongIndelsParseRemapped");

my $version = 1;
my $base_dir = $ENV{GENOME_TEST_INPUTS}."/Genome-Model-Tools-Validation-LongIndelsParseRemapped/v$version";
my $temp_dir = Genome::Sys->create_temp_directory;

my $cmd = Genome::Model::Tools::Validation::LongIndelsParseRemapped->create(
    contigs_file => $base_dir."/contigs.fa",
    tumor_bam => $base_dir."/tumor.bam",
    normal_bam => $base_dir."/normal.bam",
    output_dir => $temp_dir,
    tier_file_location => "/gscmnt/gc12001/info/model_data/2772828715/build124434505/annotation_data/tiering_bed_files_v3",
);

ok($cmd, "Command created successfully");
ok($cmd->execute, "Command executed successfully");

done_testing;

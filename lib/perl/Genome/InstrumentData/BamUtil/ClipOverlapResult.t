#!/usr/bin/env genome-perl

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above 'Genome';

require Genome::Utility::Test;
use Genome::Test::Factory::Model::ImportedReferenceSequence;
use Genome::Test::Factory::Build;
use Test::More;

my $class = 'Genome::InstrumentData::BamUtil::ClipOverlapResult';
my $tool_class = 'Genome::Model::Tools::BamUtil::ClipOverlap';
my $input_result_class = 'Genome::InstrumentData::AlignmentResult::Merged';
use_ok($class) or die;
use_ok($tool_class) or die;
use_ok($input_result_class) or die;

# make a file with some content
my $bam_path = Genome::Sys->create_temp_file_path;
my $bfh = Genome::Sys->open_file_for_writing($bam_path);
$bfh->print('Some data\n');
$bfh->close;

# We are not testing the tool, so make the execute just create an output file
Sub::Install::reinstall_sub({
    into => $tool_class,
    as => 'execute',
    code => sub { my $self = shift; Genome::Sys->copy_file($self->input_file, $self->output_file); },
});

my $bam_source = $input_result_class->__define__();

# Since we are mocking up an input result, point to a make sure we point to a file
Sub::Install::reinstall_sub({
    into => $input_result_class,
    as => 'bam_path',
    code => sub { return $bam_path; },
});

my $test_dir = Genome::Sys->create_temp_directory;

my $reference_model = Genome::Test::Factory::Model::ImportedReferenceSequence->setup_object();
my $reference_build = Genome::Test::Factory::Build->setup_object(
    model_id => $reference_model->id,
    data_directory => $test_dir,
);

my $result = $class->create(
    reference_build => $reference_build,
    bam_source => $bam_source,
    version => "1.0.11",
);

ok($result, "Software result was created");

my $get_result = $class->get($result->id);

ok($get_result, "Able to get the result that we created");

is($get_result->id, $result->id, "Ids match");

done_testing();

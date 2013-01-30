#!/usr/bin/env genome-perl

BEGIN {
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_COMMAND_DUMP_STATUS_MESSAGES} = 1;
}

use strict;
use warnings;

use above "Genome";

use Test::More;

use_ok('Genome::InstrumentData::Command::Import::Basic') or die;

my $sample = Genome::Sample->create(name => '__TEST_SAMPLE__');
ok($sample, 'Create sample');

my @source_files = (
    $ENV{GENOME_TEST_INPUTS} . '/Genome-InstrumentData-Command-Import-Basic/fastq-1.txt.gz', 
    $ENV{GENOME_TEST_INPUTS} . '/Genome-InstrumentData-Command-Import-Basic/fastq-2.fastq',
);

# Fails
my $fail = Genome::InstrumentData::Command::Import::Basic->create(
    sample => $sample,
    source_files => [ 'blah.fastq' ],
    import_source_name => 'broad',
    sequencing_platform => 'solexa',
    instrument_data_properties => [qw/ lane=2 flow_cell_id=XXXXXX /],
);
ok(!$fail->execute, 'Fails w/ invalid files');
my $error = $fail->error_message;
is($error, 'Source file does not exist! blah.fastq', 'Correct error meassage');

$fail = Genome::InstrumentData::Command::Import::Basic->create(
    sample => $sample,
    source_files => [ 'blah' ],
    import_source_name => 'broad',
    sequencing_platform => 'solexa',
    instrument_data_properties => [qw/ lane=2 flow_cell_id=XXXXXX /],
);
ok(!$fail->execute, 'Fails w/ no suffix');
$error = $fail->error_message;
is($error, 'Failed to get suffix from source file! blah', 'Correct error meassage');

$fail = Genome::InstrumentData::Command::Import::Basic->create(
    sample => $sample,
    source_files => \@source_files,
    import_source_name => 'broad',
    sequencing_platform => 'solexa',
    instrument_data_properties => [qw/ lane= /],
);
ok(!$fail->execute, 'Fails w/ invalid instrument_data_properties');
$error = $fail->error_message;
is($error, 'Failed to parse with instrument data property name/value! lane=', 'Correct error meassage');

$fail = Genome::InstrumentData::Command::Import::Basic->create(
    sample => $sample,
    source_files => \@source_files,
    import_source_name => 'broad',
    sequencing_platform => 'solexa',
    instrument_data_properties => [qw/ lane=2 lane=3 /],
);
ok(!$fail->execute, 'Fails w/ invalid instrument_data_properties');
$error = $fail->error_message;
is($error, 'Multiple values for instrument data property! lane => 2, 3', 'Correct error meassage');

# Success - fastq
my $cmd = Genome::InstrumentData::Command::Import::Basic->create(
    sample => $sample,
    source_files => \@source_files,
    import_source_name => 'broad',
    sequencing_platform => 'solexa',
    instrument_data_properties => [qw/ lane=2 flow_cell_id=XXXXXX /],
);
ok($cmd, "create import command");
ok($cmd->execute, "excute import command");

my $instrument_data = $cmd->instrument_data;
ok($instrument_data, 'got instrument data');
is($instrument_data->original_data_path, join(',', @source_files), 'original_data_path correctly set');
is($instrument_data->import_format, 'sanger fastq', 'import_format correctly set');
is($instrument_data->sequencing_platform, 'solexa', 'sequencing_platform correctly set');
is($instrument_data->is_paired_end, 1, 'is_paired_end correctly set');
is($instrument_data->read_count, 2000, 'read_count correctly set');
is(eval{ $instrument_data->attributes(attribute_label => 'lane')->attribute_value }, 2, 'lane correctly set');
is(eval{ $instrument_data->attributes(attribute_label => 'flow_cell_id')->attribute_value }, 'XXXXXX', 'flow_cell_id correctly set');
my $allocation = $instrument_data->allocations;
ok($allocation, 'got allocation');
ok($allocation->kilobytes_requested > 0, 'allocation kb was set');

my $archive_path_via_attrs = eval{ $instrument_data->attributes(attribute_label => 'archive_path')->attribute_value; };
ok($archive_path_via_attrs, 'got archive path via attrs');
ok(-s $archive_path_via_attrs, 'archive path via attrs exists');
is($archive_path_via_attrs, $allocation->absolute_path.'/archive.tgz', 'archive path named correctly');

my $archive_path = $instrument_data->archive_path;
ok($archive_path, 'got archive path');
ok(-s $archive_path, 'archive path exists');
is($archive_path, $allocation->absolute_path.'/archive.tgz', 'archive path named correctly');
#print $cmd->instrument_data->allocations->absolute_path."\n"; <STDIN>;

# Reimport fails
$fail = Genome::InstrumentData::Command::Import::Basic->create(
    sample => $sample,
    source_files => \@source_files,
    import_source_name => 'broad',
    sequencing_platform => 'solexa',
    instrument_data_properties => [qw/ lane=2 flow_cell_id=XXXXXX /],
);
ok(!$fail->execute, "Failed to reimport");
$error = $fail->error_message;
like($error, qr/^Found existing instrument data for library and source files. Were these previously imported\? Exiting instrument data id:/, 'Correct error meassage');

# Success - bam
my $source_bam = $ENV{GENOME_TEST_INPUTS}.'/Genome-InstrumentData-Command-Import-Basic/test.bam';
my $cmd2 = Genome::InstrumentData::Command::Import::Basic->create(
    sample => $sample,
    source_files => [$source_bam],
    import_source_name => 'broad',
    sequencing_platform => 'solexa',
    instrument_data_properties => [qw/ lane=2 flow_cell_id=XXXXXX /],
);
ok($cmd2, "create import command");
ok($cmd2->execute, "excute import command");

my $instrument_data2 = $cmd2->instrument_data;
ok($instrument_data2, 'got instrument data 2');
is($instrument_data2->original_data_path, $source_bam, 'original_data_path correctly set');
is($instrument_data2->import_format, 'bam', 'import_format correctly set');
is($instrument_data2->sequencing_platform, 'solexa', 'sequencing_platform correctly set');
is($instrument_data2->is_paired_end, 1, 'is_paired_end correctly set');
is($instrument_data2->read_count, 600, 'read_count correctly set');
my $allocation2 = $instrument_data2->allocations;
ok($allocation2, 'got allocation');
ok($allocation2->kilobytes_requested > 0, 'allocation kb was set');

my $bam_via_bam_path = $instrument_data2->bam_path;
ok($bam_via_bam_path, 'got bam via bam path');
ok(-s $bam_via_bam_path, 'bam via bam path exists');
is($bam_via_bam_path, $allocation2->absolute_path.'/all_sequences.bam', 'bam via bam path named correctly');

my $bam_via_attrs = eval{ $instrument_data2->attributes(attribute_label => 'bam_path')->attribute_value; };
ok($bam_via_attrs, 'got bam via attrs');
ok(-s $bam_via_attrs, 'bam via attrs exists');
is($bam_via_attrs, $allocation2->absolute_path.'/all_sequences.bam', 'bam via attrs named correctly');

my $bam_via_archive_path = $instrument_data2->archive_path;
ok($bam_via_archive_path, 'got bam via archive path');
ok(-s $bam_via_archive_path, 'bam via archive path exists');
is($bam_via_archive_path, $allocation2->absolute_path.'/all_sequences.bam', 'bam via archive path named correctly');
#print $cmd2->instrument_data->allocations->absolute_path."\n"; <STDIN>;

done_testing();

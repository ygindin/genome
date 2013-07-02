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

use_ok('Genome::InstrumentData::Command::Import::New') or die;

my $sample = Genome::Sample->create(name => '__TEST_SAMPLE__');
ok($sample, 'Create sample');

my @source_files = (
    $ENV{GENOME_TEST_INPUTS} . '/Genome-InstrumentData-Command-Import-Basic/fastq-1.txt.gz', 
    $ENV{GENOME_TEST_INPUTS} . '/Genome-InstrumentData-Command-Import-Basic/fastq-2.fastq',
);

# Success - fastq
my $cmd = Genome::InstrumentData::Command::Import::New->create(
    sample => $sample,
    source_files => \@source_files,
    import_source_name => 'broad',
    instrument_data_properties => [qw/ lane=2 flow_cell_id=XXXXXX /],
);
ok($cmd, "create import command");
ok($cmd->execute, "excute import command");


my $instrument_data = Genome::InstrumentData::Imported->get(original_data_path => join(',', @source_files));
ok($instrument_data, 'got instrument data');
is($instrument_data->original_data_path, join(',', @source_files), 'original_data_path correctly set');
is($instrument_data->import_format, 'bam', 'import_format is bam');
is($instrument_data->sequencing_platform, 'solexa', 'sequencing_platform correctly set');
is($instrument_data->is_paired_end, 1, 'is_paired_end correctly set');
is($instrument_data->read_count, 2000, 'read_count correctly set');
is(eval{ $instrument_data->attributes(attribute_label => 'lane')->attribute_value }, 2, 'lane correctly set');
is(eval{ $instrument_data->attributes(attribute_label => 'flow_cell_id')->attribute_value }, 'XXXXXX', 'flow_cell_id correctly set');

my $bam_path = $instrument_data->bam_path;
ok(-s $bam_path, 'bam path exists');
is($bam_path, $instrument_data->data_directory.'/all_sequences.bam', 'bam path correctly named');
is(eval{$instrument_data->attributes(attribute_label => 'bam_path')->attribute_value}, $bam_path, 'set attributes bam path');

my $allocation = $instrument_data->allocations;
ok($allocation, 'got allocation');
ok($allocation->kilobytes_requested > 0, 'allocation kb was set');

print $instrument_data->data_directory."\n";<STDIN>;
done_testing();

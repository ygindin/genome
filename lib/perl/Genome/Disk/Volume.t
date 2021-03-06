#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;

use_ok('Genome::Disk::Volume') or die;

my $volume = Genome::Disk::Volume->create(
    hostname => 'test',
    physical_path => 'test',
    total_kb => 100,
    can_allocate => 1,
    disk_status => 'active',
    mount_path => '/gscmnt/foo',
);
ok($volume, 'created test volume');

is($volume->is_archive, 0, 'volume is correctly labelled as not being an archive volume');
is($volume->archive_mount_path, '/gscarchive/foo', 'got expected archive mount path back');

{
    my $original_unallocated_kb = $volume->unallocated_kb;
    eval { $volume->unallocated_kb($original_unallocated_kb + 100) };
    is($volume->unallocated_kb, $original_unallocated_kb, 'make sure unallocated_kb is immutable');
}

ok(!$volume->archive_volume, 'got no archive volume back, as expected');

my $archive = Genome::Disk::Volume->create(
    hostname => 'test',
    physical_path => 'test',
    total_kb => 100,
    can_allocate => 1,
    disk_status => 'active',
    mount_path => $volume->archive_mount_path,
);
ok($archive, 'created archive volume');

ok($volume->archive_volume, 'now we get an archive volume back!');
is($volume->archive_volume->id, $archive->id, 'get expected archive volume');

done_testing();

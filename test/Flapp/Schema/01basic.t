use Test::More;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use lib Cwd::abs_path("$FindBin::Bin/tlib");
use strict;
use warnings;

use MyProject;
use MyTest;
my $proj = 'MyProject';
my($DBH, $DBN) = MyTest->setup($proj);
ok $DBN;

$proj->begin;
eval{
    MyTest->migrate($proj);
    
    is my $sch = $proj->schema->ExampleEntry, 'MyProject::Schema::Default::ExampleEntry';
    {
        local $Flapp::NOW = '2011-07-04T23:20:00+09:00';
        my $r = $sch->new;
        is_deeply $r, {-txn => {
            created_at => $proj->now,
            lock_version => 1,
            updated_at => $proj->now,
        }};
        $r->insert;
        is_deeply $r, {
            -org => {
                id           => 1,
                category_id  => undef,
                created_at   => '2011-07-04 23:20:00',
                updated_at   => '2011-07-04 23:20:00',
                lock_version => 1,
                title        => undef,
            },
            -txn => {
                created_at   => $proj->now,
                updated_at   => $proj->now,
            },
        };
        
        $Flapp::NOW = '2011-07-04T23:21:00+09:00';
        $r->title('')->update;
        is_deeply $r, {
            -org => {
                id           => 1,
                category_id  => undef,
                created_at   => '2011-07-04 23:20:00',
                updated_at   => '2011-07-04 23:21:00',
                lock_version => 1,
                title        => '',
            },
            -txn => {
                created_at   => $proj->now->min(-1),
                updated_at   => $proj->now,
            },
        };
        
        $r->title('?')->lock_version(1)->update;
        is_deeply $r, {
            -org => {
                id           => 1,
                category_id  => undef,
                created_at   => '2011-07-04 23:20:00',
                updated_at   => '2011-07-04 23:21:00',
                lock_version => 2,
                title        => '?',
            },
            -txn => {
                created_at   => $proj->now->min(-1),
                updated_at   => $proj->now,
            },
        };
    }
    
    {
        local $::ENV{FLAPP_DEBUG} = 1;
        tie *STDERR, 'Capture';
        $sch->find(1)->title('test')->lock_version(2)->update;
        like ${tied *STDERR}, qr/"UPDATE example_entries SET updated_at = '\d{4}-\d\d-\d\d \d\d:\d\d:\d\d', lock_version = '3', title = 'test' WHERE id = '1' AND lock_version = '2'"/;
        untie *STDERR;
    }
};
$proj->end;

my $msg = $@;
$DBH->prepare("drop database $DBN;")->execute;
die $msg if $msg;

package Capture;
sub TIEHANDLE { bless \(my $buf = ''), shift }
sub PRINT { ${+shift} .= shift }

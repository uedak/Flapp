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

is my $se = $proj->schema->ExampleEntry,
    'MyProject::Schema::Default::ExampleEntry';
is my $sem = $proj->schema->ExampleEntryMember,
    'MyProject::Schema::Default::ExampleEntryMember';
is my $sm = $proj->schema->ExampleMember,
    'MyProject::Schema::Default::ExampleMember';

$proj->begin;
eval{
    MyTest->migrate($proj);
    {
        $se->new->insert for 1 .. 3;
        
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        is $se->delete_by_sql(['id IN (?)' => [1, 2, 3]]), 3;
        is Capture->end, q{$(Default:0)->execute("DELETE FROM example_entries WHERE id IN ('1','2','3')")}."\n";
    }
    
    {
        $se->new->insert for 1 .. 3;
        
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        is $se->delete_by_sql({id => 1}), 0;
        is Capture->end, q{$(Default:0)->execute("DELETE FROM example_entries WHERE id = '1'")}."\n";    }
    
    {
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        is $se->delete_by_sql([], {rows => 2}), 2;
        is Capture->end, '$(Default:0)->execute("DELETE FROM example_entries LIMIT 2")'."\n";
    }
    
    {
        eval{ $se->new->delete_by_sql };
        like $@, qr/^Can't call class method "delete_by_sql" via/;
    }
    
    
    
    {
        $sm->new->insert for 1 .. 3;
        
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        is $sm->update_by_sql(
            ['id IN (?)' => [1, 2, 3]],
            {set => {name => "'", money => undef}, rows => 2},
        ), 2;
        is Capture->end, q{$(Default:0)->execute("UPDATE example_members SET}.
            q{ money = NULL, name = '\'' WHERE id IN ('1','2','3') LIMIT 2")}."\n";
    }
    
    {
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        is $sm->update_by_sql([], {set => ['name = id']}), 3;
        is Capture->end, '$(Default:0)->execute("UPDATE example_members SET name = id")'."\n";
    }
    
    {
        eval{ $se->new->update_by_sql };
        like $@, qr/^Can't call class method "update_by_sql" via/;
    }
    
    {
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        $sem->truncate;
        is Capture->end, '$(Default:0)->execute("TRUNCATE TABLE example_entry_members")'."\n";
    }
};
$proj->end;

my $msg = $@;
$DBH->prepare("drop database $DBN;")->execute;
die $msg if $msg;

package Capture;
sub TIEHANDLE { bless \(my $buf = ''), shift }
sub PRINT { ${+shift} .= shift }
sub end {
    (my $s = ${tied *STDERR}) =~ s/^-+\n//mg;
    untie *STDERR;
    $s;
}

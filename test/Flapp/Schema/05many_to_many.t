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
    $se->new->insert;
    foreach(1 .. 3){
        $sm->new->insert;
        $sem->new({entry_id => 1, member_id => $_})->insert;
    }
    
    {
        ok my $e = $se->find(1);
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        is join('#', map{ $_->id } @{$e->members}), '1#2#3';
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT me.*, '|', member.*
FROM example_entry_members me
LEFT JOIN example_members member ON member.id = me.member_id
WHERE me.entry_id = '1'
ORDER BY me.member_id")
_END_
    }
    
    {
        ok my $e = $se->find(1);
        is join('#', map{ $_->member_id } @{$e->entry_members}), '1#2#3';
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        is join('#', map{ $_->id } @{$e->members}), '1#2#3';
        like Capture->end, qr/^\$\(Default:0\)->execute\("SELECT \* FROM example_members WHERE id IN \('[1-3]','[1-3]','[1-3]'\)"\)\n\z/;
    }
    
    {
        my $e = $se->new->entry_members([
            {member_id => 1},
            {member_id => 4},
            {member_id => 3},
        ]);
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        is join('#', map{ $_->id } @{$e->members}), '1#3';
        like Capture->end, qr/^\$\(Default:0\)->execute\("SELECT \* FROM example_members WHERE id IN \('[134]','[134]','[134]'\)"\)\n\z/;
        
        
        tie *STDERR, 'Capture';
        is join('#', map{ $_->id } @{$e->members}), '1#3';
        is Capture->end, '';
    }
    
    { #Broken fk
        is @{$se->find(1)->members}, 3;
        $proj->dbh->do('SET foreign_key_checks=0');
        $sem->new({entry_id => 1, member_id => 10, priv_cd => 1})->insert;
        $proj->dbh->do('SET foreign_key_checks=1');
        is @{$se->find(1)->entry_members}, 4;
        is @{$se->find(1)->members}, 3;
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

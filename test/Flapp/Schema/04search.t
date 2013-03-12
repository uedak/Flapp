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
    
    is my $se = $proj->schema->ExampleEntry, 'MyProject::Schema::Default::ExampleEntry';
    is my $sem = $proj->schema->ExampleEntryMember,
        'MyProject::Schema::Default::ExampleEntryMember';
    is my $sm = $proj->schema->ExampleMember, 'MyProject::Schema::Default::ExampleMember';
    
    my($r, @r);
    for(1 .. 3){
        ($r = $se->new)->insert;
        is $r->id, $_;
        ($r = $sm->new({name => "member$_"}))->insert;
        is $r->id, $_;
    }
    $sem->new({entry_id => 1, member_id => 1})->insert;
    $sem->new({entry_id => 3, member_id => 1})->insert;
    $sem->new({entry_id => 3, member_id => 2})->insert;
    $sem->new({entry_id => 3, member_id => 3})->insert;
    
    $r = $se->search(['id = ?' => 1])->[0];
    is $r->id, 1;
    is $r->lock_version, 1;
    
    $r = $se->search(['id = ?' => 1], {
        group_by => [qw/id/],
        having   => ['id = ?' => 1],
        order_by => [qw/id/],
        for      => 'update',
    })->[0];
    is $r->id, 1;
    is $r->lock_version, 1;
    
    $r = $se->search(['id = ?' => 1], {select => [qw/id/]})->[0];
    is_deeply $r->{-org}, {id => 1};
    
    foreach my $id (1, 2, 3){
        my $rs = $se->search(['me.id = ?' => $id], {
            join => {ems => [ExampleEntryMember => {-on => ['ems.entry_id = me.id'], -m => '*'}]},
        });
        is @$rs, 1;
        is $rs->[0]->id, $id;
    }
    
    foreach my $id (1, 2, 3){
        my $rs = $se->search([], {
            join => {ems => [ExampleEntryMember => {-on => ['ems.entry_id = me.id'], -m => '*'}]},
            order_by => ['me.id'],
            rows     => 1,
            page     => $id,
        });
        is @$rs, 1;
        is $rs->[0]->id, $id;
    }
    
    {
        my $rs = $se->search(['me.id = ?', 3], {
            select => [qw/me.* ems.*/, '(select count(*) from example_members) cnt'],
            join => {ems => [ExampleEntryMember => {-on => ['ems.entry_id = me.id'], -m => '*'}]},
        });
        is @$rs, 1;
        is $rs->[0]->get_column('cnt'), 3;
        my $ems = $rs->[0]->get_related('ems');
        is join('#', map{ $_->entry_id.'/'.$_->member_id }@$ems), '3/1#3/2#3/3';
        is keys %{$ems->[0]{-org}}, @{$sem->columns};
    }
    
    eval{
        $se->search([], {
            join  => {content => [
                ExampleEntryMember => {-on => ['content.entry_id = me.id'], -m => '*'}
            ]},
        });
    };
    like $@, qr/^Can't join ExampleEntryMember as existing relationship "content"/;
    
    
    
    foreach my $id (1, 2, 3){
        my $rs = $se->search(['me.id = ?' => $id], {
            select => [qw/entry_members.* member.*/],
            join   => {entry_members => {member => {}}},
        });
        is @$rs, 1;
        is $rs->[0]->id, $id;
        is @{$rs->[0]->entry_members}, ($id == 2 ? 0 : $id);
        
        next if $id == 2;
        my $em0 = $rs->[0]->entry_members->[0];
        is $em0->entry, $rs->[0];
        #print $em0->member->_dump_;
    }
    
    {
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        my $rs = $se->search([['id = ?' => 1], -or => ['id = ?' => 2]]);
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entries WHERE id = '1' OR id = '2'")
_END_
        is @$rs, 2;
    }
    
    {
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        my $rs = $se->search(
            ['exists(select 1 from example_categories where id = me.category_id)'],
            {-as => 'me'},
        );
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT me.* FROM example_entries me WHERE exists(select 1 from example_categories where id = me.category_id)")
_END_
    }
    
    {
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        $se->find(1, {select => '*.*'});
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entries WHERE id = '1'")
_END_
    }
    
    {
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        $se->search(['e.id = ?' => 1], {
            -as    => 'e',
            select => '*.*',
            join   => {entry_members => {-as => 'em', member => {-as => 'm'}}},
        });
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT e.*, '|', em.*, '|', m.*
FROM example_entries e
LEFT JOIN example_entry_members em ON em.entry_id = e.id
LEFT JOIN example_members m ON m.id = em.member_id
WHERE e.id = '1'")
_END_
    }
    
    {
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        $se->find(1, {
            select => '*.*',
            join   => {entry_members => {-as => 'em', member => {-as => 'm'}}},
        });
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT me.*, '|', em.*, '|', m.*
FROM example_entries me
LEFT JOIN example_entry_members em ON em.entry_id = me.id
LEFT JOIN example_members m ON m.id = em.member_id
WHERE me.id = '1'")
_END_
    }
    
    {
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        $se->find(1, {
            -as    => 'e',
            select => '*.*',
            join   => {entry_members => {-as => 'em', member => {-as => 'm'}}},
        });
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT e.*, '|', em.*, '|', m.*
FROM example_entries e
LEFT JOIN example_entry_members em ON em.entry_id = e.id
LEFT JOIN example_members m ON m.id = em.member_id
WHERE e.id = '1'")
_END_
    }
    
    {
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        $se->search(['id BETWEEN ? AND ?', 1, 100], {
            -as      => 'e',
            join     => {entry_members => {-as => 'em', member => {-as => 'm'}}},
            select   => ['category_id', 'max(e.id) max_id', 'max(m.id)'],
            order_by => 'category_id desc',
        });
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT e.category_id, max(e.id) max_id, max(m.id), e.id
FROM example_entries e
LEFT JOIN example_entry_members em ON em.entry_id = e.id
LEFT JOIN example_members m ON m.id = em.member_id
WHERE e.id BETWEEN '1' AND '100'
ORDER BY e.category_id desc")
_END_
    }
    
    {
        my $sto = $sem->storage;
        my $sql;
        $sto->dbh->do($sql) if ($sql = $sto->disable_constraint_sql);
        $_->truncate for ($sem, $se);
        $sto->dbh->do($sql) if ($sql = $sto->enable_constraint_sql);
    }
    
    {
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        my($rs, $pager) = $se->search([], {rows => 'a', page => 'b'});
        is join(',', map{ $_->id } @$rs), '';
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entries LIMIT 10")
_END_
    }
    
    {
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        my($rs, $pager) = $se->search([], {rows => 101});
        my $e = Capture->end;
        ok $e =~ s/^Rows\(101\) exceeded MAX_SEARCH_ROWS\(100\)\n( at .+\n)+//;
        is $e, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entries LIMIT 100")
_END_
    }
    
    my $w = ['id IN (?)', [1..5]];
    {
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        my($rs, $pager) = $se->search($w, {rows => 2, page => 1, order_by => 'id'});
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entries WHERE id IN ('1','2','3','4','5') ORDER BY id LIMIT 2")
_END_

        tie *STDERR, 'Capture';
        ($rs, $pager) = $se->search($w,
            {join => {entry_members => {}}, rows => 2, page => 1, order_by => 'id'});
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT me.* FROM (
  SELECT me.id FROM example_entries me
  LEFT JOIN example_entry_members entry_members ON entry_members.entry_id = me.id
  WHERE me.id IN ('1','2','3','4','5')
  GROUP BY me.id ORDER BY me.id LIMIT 2
) us JOIN example_entries me ON me.id = us.id
LEFT JOIN example_entry_members entry_members ON entry_members.entry_id = me.id
WHERE me.id IN ('1','2','3','4','5')
ORDER BY me.id")
_END_
    }
    
    $se->new->insert for 1 .. 5;
    {
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        my($rs, $pager) = $se->search($w, {rows => 2, page => 1, order_by => 'id'});
        is join(',', map{ $_->id } @$rs), '1,2';
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entries WHERE id IN ('1','2','3','4','5') ORDER BY id LIMIT 2")
$(Default:0)->execute("SELECT COUNT(*) FROM example_entries WHERE id IN ('1','2','3','4','5')")
_END_
        
        tie *STDERR, 'Capture';
        ($rs, $pager) = $se->search($w, {rows => 2, page => 2, order_by => 'id'});
        is join(',', map{ $_->id } @$rs), '3,4';
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entries WHERE id IN ('1','2','3','4','5') ORDER BY id LIMIT 2,2")
$(Default:0)->execute("SELECT COUNT(*) FROM example_entries WHERE id IN ('1','2','3','4','5')")
_END_
        
        tie *STDERR, 'Capture';
        ($rs, $pager) = $se->search($w, {rows => 2, page => 3, order_by => 'id'});
        is join(',', map{ $_->id } @$rs), '5';
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entries WHERE id IN ('1','2','3','4','5') ORDER BY id LIMIT 4,2")
_END_

        tie *STDERR, 'Capture';
        ($rs, $pager) = $se->search($w,
            {join => {entry_members => {}}, rows => 2, page => 1, order_by => 'id'});
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT me.* FROM (
  SELECT me.id FROM example_entries me
  LEFT JOIN example_entry_members entry_members ON entry_members.entry_id = me.id
  WHERE me.id IN ('1','2','3','4','5')
  GROUP BY me.id ORDER BY me.id LIMIT 2
) us JOIN example_entries me ON me.id = us.id
LEFT JOIN example_entry_members entry_members ON entry_members.entry_id = me.id
WHERE me.id IN ('1','2','3','4','5')
ORDER BY me.id")
$(Default:0)->execute("SELECT COUNT(*) FROM (
  SELECT me.id FROM example_entries me
  LEFT JOIN example_entry_members entry_members ON entry_members.entry_id = me.id
  WHERE me.id IN ('1','2','3','4','5')
  GROUP BY me.id
) us")
_END_
        
        tie *STDERR, 'Capture';
        ($rs, $pager) = $se->search($w, {page => 2, order_by => 'id'});
        is join(',', map{ $_->id } @$rs), '';
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entries WHERE id IN ('1','2','3','4','5') ORDER BY id LIMIT 10,10")
$(Default:0)->execute("SELECT COUNT(*) FROM example_entries WHERE id IN ('1','2','3','4','5')")
_END_

        tie *STDERR, 'Capture';
        ($rs, $pager) = $se->search($w, {rows => 2, page => 0, order_by => 'id'});
        is join(',', map{ $_->id } @$rs), '1,2';
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entries WHERE id IN ('1','2','3','4','5') ORDER BY id LIMIT 2")
$(Default:0)->execute("SELECT COUNT(*) FROM example_entries WHERE id IN ('1','2','3','4','5')")
_END_
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

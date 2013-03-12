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
is my $sec = $proj->schema->ExampleEntryContent,
    'MyProject::Schema::Default::ExampleEntryContent';
is my $sem = $proj->schema->ExampleEntryMember,
    'MyProject::Schema::Default::ExampleEntryMember';
is my $sm = $proj->schema->ExampleMember,
    'MyProject::Schema::Default::ExampleMember';
is my $sc = $proj->schema->ExampleCategory,
    'MyProject::Schema::Default::ExampleCategory';

$proj->begin;

eval{
    MyTest->migrate($proj);
    is $Flapp::Schema::VFK_SEQ, 0;
    {
        my $e1  = $se->new;
        my $e2  = $se->new;
        my $em1 = $sem->new;
        my $em2 = $sem->new;
        
        $e1->entry_members([$em1, $em2]);
        is $Flapp::Schema::VFK_SEQ, 1;
        is join('#', @{$e1->entry_members}), "$em1#$em2";
        is $em1->entry, $e1;
        is $em2->entry, $e1;
        
        $e1->entry_members([$em2]);
        is join('#', @{$e1->entry_members}), $em2;
        is $em1->entry, undef;
        is $em2->entry, $e1;
        
        $e2->entry_members([$em1, $em2]);
        is join('#', @{$e1->entry_members}), '';
        is join('#', @{$e2->entry_members}), "$em1#$em2";
        is $em1->entry, $e2;
        is $em2->entry, $e2;
        
        $em1->entry($e1);
        $em2->entry($e1);
        is join('#', @{$e1->entry_members}), "$em1#$em2";
        is join('#', @{$e2->entry_members}), '';
        is $em1->entry, $e1;
        is $em2->entry, $e1;
        
        $em1->entry(undef);
        is join('#', @{$e1->entry_members}), $em2;
        is join('#', @{$e2->entry_members}), '';
        is $em1->entry, undef;
        is $em2->entry, $e1;
        
        $em1->entry($e2);
        is join('#', @{$e1->entry_members}), $em2;
        is join('#', @{$e2->entry_members}), $em1;
        is $em1->entry, $e2;
        is $em2->entry, $e1;
        
        my $e3  = $se->new;
        my $em3 = $sem->new;
        $e3->entry_members([$em3]);
        is join('#', @{$e3->entry_members}), $em3;
        is $em3->entry, $e3;
        
        $e1->entry_members([$em3]);
        is join('#', @{$e1->entry_members}), $em3;
        is join('#', @{$e2->entry_members}), $em1;
        is join('#', @{$e3->entry_members}), '';
        is $em1->entry, $e2;
        is $em2->entry, undef;
        is $em3->entry, $e1;
        
        $e1->entry_members([$em1, $em2, $em3]);
        is join('#', @{$e1->entry_members}), "$em1#$em2#$em3";
        is join('#', @{$e2->entry_members}), '';
        is join('#', @{$e3->entry_members}), '';
        is $em1->entry, $e1;
        is $em2->entry, $e1;
        is $em3->entry, $e1;
        
        $e2->entry_members([$em2]);
        is join('#', @{$e1->entry_members}), "$em1#$em3";
        is join('#', @{$e2->entry_members}), $em2;
        is join('#', @{$e3->entry_members}), '';
        is $em1->entry, $e1;
        is $em2->entry, $e2;
        is $em3->entry, $e1;
    }
    is $Flapp::Schema::VFK_SEQ, 0;
    
    {
        my $e1  = $se->new;
        $e1->entry_members([]);
    }
    
    my @r;
    {
        $proj->_weaken_($r[0] = my $e = $se->new);
        $proj->_weaken_($r[1] = my $ec = $sec->new);
        
        $e->content($ec);
        my $i = "$ec";
        is $e->content, $i;
        undef $ec;
        is $e->content, $i;
    }
    is_deeply \@r, [undef, undef];
    
    {
        $proj->_weaken_($r[0] = my $e = $se->new);
        $proj->_weaken_($r[1] = my $ec = $sec->new);
        
        $e->content($ec);
        my $i = "$e";
        is $ec->entry, $i;
        undef $e;
        is $ec->entry, $i;
    }
    is_deeply \@r, [undef, undef];
    
    {
        $proj->_weaken_($r[0] = my $e = $se->new);
        $proj->_weaken_($r[1] = my $ec = $sec->new);
        
        $ec->entry($e);
        my $i = "$e";
        is $ec->entry, $i;
        undef $e;
        is $ec->entry, $i;
    }
    is_deeply \@r, [undef, undef];
    
    {
        $proj->_weaken_($r[0] = my $e = $se->new);
        $proj->_weaken_($r[1] = my $ec = $sec->new);
        
        $ec->entry($e);
        my $i = "$ec";
        is $e->content, $i;
        undef $ec;
        is $e->content, $i;
    }
    is_deeply \@r, [undef, undef];
    
    {
        my $new = sub{
            my $e = $se->new->content({});
            ok $e->content;
            $e;
        };
        my $e2c = sub{ shift->content };
        ok my $c = $e2c->($new->());
        ok $c->entry;
    }
    
    $se->new->insert;
    $sec->new({entry_id => 1})->insert;
    foreach(1 .. 3){
        $sm->new->insert;
        $sem->new({entry_id => 1, member_id => $_})->insert;
    }
    {
        my $e1 = $se->find(1);
        is $e1->id, 1;
        is $e1->lock_version, 1;
        
        my $ec = $e1->content;
        is $ec->entry_id, 1;
        
        my $e2 = $ec->entry;
        is $e1, $e2;
        is $e2->content, $ec;
        
        my $em = $e1->entry_members;
        is join('#', map{ $_->member_id } @$em), '1#2#3';
        is $em->[0]->entry, $e1;
        is $em->[1]->entry, $e1;
        is $em->[2]->entry, $e1;
    }
    
    {
        my $em1 = $sem->find([1, 2]);
        my $e1 = $em1->entry;
        
        my $em = $e1->entry_members;
        is join('#', map{ $_->member_id } @$em), '1#2#3';
        is $em->[1], $em1;
    }
    
    foreach my $e (undef, $se->new){
        my $em1 = $sem->find([1, 2]);
        my $e1 = $em1->entry;
        
        $em1->entry($e);
        my $em = $e1->entry_members;
        
        is $em1->entry_id, undef;
        is join('#', map{ $_->member_id } @{$e1->entry_members}), '1#3';
    }
    
    foreach my $e (undef, $se->new){
        my $em1 = $sem->find([1, 2]);
        my $e1 = $em1->entry;
        
        $em1->entry($e)->entry($e1);
        my $em = $e1->entry_members;
        
        is $em1->entry_id, 1;
        is join('#', map{ $_->member_id } @{$e1->entry_members}), '1#2#3';
    }
    
    foreach my $e (undef, $se->new){
        my $em1 = $sem->find([1, 2]);
        my $e1 = $em1->entry;
        
        my $em = $e1->entry_members;
        $em1->entry($e);
        
        is $em1->entry_id, undef if !$e;
        is join('#', map{ $_->member_id } @{$e1->entry_members}), '1#3';
    }
    
    {
        my $em1 = $sem->find([1, 2]);
        my $e1 = $em1->entry;
        $sem->new({member_id => 4})->entry($e1);
        my $em = $e1->entry_members;
        is $em->[1], $em1;
        is join('#', map{ $_->member_id } @{$e1->entry_members}), '1#2#3#4';
    }
    
    {
        my $e1 = $se->find(1);
        my $em = $e1->entry_members;
        my $em1 = $em->[1];
        is $em1->entry_id, 1;
        $e1->entry_members([$em->[0], $em->[2]]);
        is $em1->entry_id, undef;
    }
    
    {
        my $e1 = $se->find(1);
        my $em = $e1->entry_members;
        is $em->[0]->member_id, 1;
        is $em->[0]->priv_cd, 0;
        
        $e1->entry_members([{member_id => 2, priv_cd => 1}], {-o => [qw/priv_cd/]});
        $em = $e1->entry_members;
        is $em->[0]->member_id, undef;
        is $em->[0]->priv_cd, 1;
        ok !$em->[0]->in_storage;
        
        $e1->entry_members([{member_id => 2, priv_cd => 1}], {-x => [qw/member_id/]});
        $em = $e1->entry_members;
        is $em->[0]->member_id, undef;
        is $em->[0]->priv_cd, 1;
        ok !$em->[0]->in_storage;
        
        $e1 = $se->find(1);
        $e1->entry_members([{member_id => 1, priv_cd => 1}], {-i => [qw/member_id/]});
        $em = $e1->entry_members;
        is $em->[0]->member_id, 1;
        is $em->[0]->priv_cd, 1;
        ok $em->[0]->in_storage;
        
        $e1 = $se->new;
        $e1->entry_members([{member_id => 1, priv_cd => 1}]);
        $e1->entry_members([{member_id => 2}], {-i => [qw/foo bar/]});
        is @{$e1->entry_members}, 1;
        is $e1->entry_members->[0]->priv_cd, undef;
    }
    
    {
        my $e1 = $se->new;
        my $em = $sem->new;
        $e1->entry_members([$em]);
        $em->member({});
        is @{$e1->entry_members}, 1;
    }
    
    {
        my $rs = $sem->search({'me.entry_id' => 1}, {
            select => [qw/me.* entry.* content.*/],
            join => {entry => {content => {}}},
        });
        is $rs->[0]->entry, $rs->[1]->entry;
        ok $rs->[0]->entry->content;
        $rs->[0]->entry->content->delete;
        
        $rs = $sem->search({'me.entry_id' => 1}, {
            select => [qw/me.* entry.* content.*/],
            join => {entry => {content => {}}},
        });
        is $rs->[0]->entry, $rs->[1]->entry;
        
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        ok !$rs->[0]->entry->content;
        is Capture->end, '';
    }
    
    # save_related
    {
        $sm->new({id => 4})->insert;
        my $e1 = $se->find(1);
        $e1->set_related(entry_members => [
            {member_id => 2, priv_cd => 1},
            {member_id => 3, priv_cd => 2},
            {member_id => 4, priv_cd => 3},
        ], {-i => [qw/member_id/]});
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e1->save_related('entry_members') }
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entry_members WHERE entry_id = '1' ORDER BY member_id")
$(Default:0)->execute("DELETE FROM example_entry_members WHERE entry_id = '1' AND member_id = '1'")
$(Default:0)->execute("UPDATE example_entry_members SET priv_cd = '1' WHERE entry_id = '1' AND member_id = '2'")
$(Default:0)->execute("UPDATE example_entry_members SET priv_cd = '2' WHERE entry_id = '1' AND member_id = '3'")
$(Default:0)->execute("INSERT INTO example_entry_members (entry_id, member_id, priv_cd) VALUES ('1', '4', '3')")
_END_
        
        $e1->set_related(entry_members => [
            {member_id => 1, priv_cd => 1},
            {member_id => 2, priv_cd => 2},
            {member_id => 3, priv_cd => 3},
        ], {-i => [qw/member_id/]});
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e1->save_related('entry_members', {-d => 1})}
        is Capture->end, <<'_END_';
$(Default:0)->execute("DELETE FROM example_entry_members WHERE entry_id = '1' AND member_id NOT IN ('2','3')")
$(Default:0)->execute("INSERT INTO example_entry_members (entry_id, member_id, priv_cd) VALUES ('1', '1', '1')")
$(Default:0)->execute("UPDATE example_entry_members SET priv_cd = '2' WHERE entry_id = '1' AND member_id = '2'")
$(Default:0)->execute("UPDATE example_entry_members SET priv_cd = '3' WHERE entry_id = '1' AND member_id = '3'")
_END_
        
        $e1->set_related(entry_members => [
            {member_id => 1, priv_cd => 2},
            {member_id => 2, priv_cd => 3},
        ], {-i => [qw/member_id/]});
        tie *STDERR, 'Capture';
        {
            local $sem->_global_->{primary_key} = [qw/entry_id member_id priv_cd/];
            local $::ENV{FLAPP_DEBUG} = 1;
            $e1->save_related('entry_members', {-d => 1})
        }
        is Capture->end, <<'_END_';
$(Default:0)->execute("DELETE FROM example_entry_members WHERE entry_id = '1' AND NOT (member_id = '1' AND priv_cd = '1' OR member_id = '2' AND priv_cd = '2')")
$(Default:0)->execute("UPDATE example_entry_members SET priv_cd = '2' WHERE entry_id = '1' AND member_id = '1' AND priv_cd = '1'")
$(Default:0)->execute("UPDATE example_entry_members SET priv_cd = '3' WHERE entry_id = '1' AND member_id = '2' AND priv_cd = '2'")
_END_
        
        $e1->content({});
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e1->save_related('content')};
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entry_contents WHERE entry_id = '1'")
$(Default:0)->execute("INSERT INTO example_entry_contents (entry_id) VALUES ('1')")
_END_
        
        $e1->content({text => 'foo'});
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e1->save_related('content')};
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entry_contents WHERE entry_id = '1'")
$(Default:0)->execute("DELETE FROM example_entry_contents WHERE entry_id = '1'")
$(Default:0)->execute("INSERT INTO example_entry_contents (entry_id, text) VALUES ('1', 'foo')")
_END_
        
        $e1->content({text => 'foo'});
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e1->save_related('content', {-d => 1})};
        is Capture->end, <<'_END_';
$(Default:0)->execute("DELETE FROM example_entry_contents WHERE entry_id = '1'")
$(Default:0)->execute("INSERT INTO example_entry_contents (entry_id, text) VALUES ('1', 'foo')")
_END_
        
        $e1->content->text('bar');
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e1->save_related('content')};
        is Capture->end, <<'_END_';
$(Default:0)->execute("UPDATE example_entry_contents SET text = 'bar' WHERE entry_id = '1'")
_END_
        
        $e1->content->text('baz');
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e1->save_related('content', {-d => 1})};
        is Capture->end, <<'_END_';
$(Default:0)->execute("UPDATE example_entry_contents SET text = 'baz' WHERE entry_id = '1'")
_END_
        
        $e1->content(undef);
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e1->save_related('content')};
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entry_contents WHERE entry_id = '1'")
$(Default:0)->execute("DELETE FROM example_entry_contents WHERE entry_id = '1'")
_END_
        
        $e1->content(undef);
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e1->save_related('content', {-d => 1})};
        is Capture->end, <<'_END_';
$(Default:0)->execute("DELETE FROM example_entry_contents WHERE entry_id = '1'")
_END_
    }
    is $Flapp::Schema::VFK_SEQ, 0;
    
    {
        my $e = $se->new({id => 1});
        my $ec = $e->find_or_new_related('content');
        is $ec->entry, $e;
        is $e->content, $ec;
        ok !$ec->in_storage;
        $ec->save;
        
        $e = $se->new({id => 1});
        $ec = $e->find_or_new_related('content');
        is $ec->entry, $e;
        is $e->content, $ec;
        ok $ec->in_storage;
        
        eval{ $e->find_or_new_related('foo') };
        like $@, qr/^No such relationship "foo"/;
        
        eval{ $e->find_or_new_related('entry_members') };
        like $@, qr/^Can't find_or_new_related multiple relationship "entry_members"/;
    }
    
    {
        my $e = $se->find(1);
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e->search_related('entry_members')};
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entry_members WHERE entry_id = '1' ORDER BY member_id")
_END_
        
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e->search_related('entry_members', ['priv_cd = ?', 1])};
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entry_members WHERE entry_id = '1' AND (priv_cd = '1') ORDER BY member_id")
_END_
        
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e->search_related('entry_members', {priv_cd => 1})};
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entry_members WHERE entry_id = '1' AND priv_cd = '1' ORDER BY member_id")
_END_
        
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e->search_related('entry_members', {priv_cd => undef})};
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entry_members WHERE entry_id = '1' AND priv_cd IS NULL ORDER BY member_id")
_END_
        
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e->search_related('entry_members', [
            ['priv_cd = ?', 1], -or => ['priv_cd = ?', 2]
        ])};
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entry_members WHERE entry_id = '1' AND (priv_cd = '1' OR priv_cd = '2') ORDER BY member_id")
_END_
        
        tie *STDERR, 'Capture';
        {local $::ENV{FLAPP_DEBUG} = 1; $e->search_related('entry_members', [
            {priv_cd => 1}, -or => {priv_cd => 2}
        ])};
        is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entry_members WHERE entry_id = '1' AND (priv_cd = '1' OR priv_cd = '2') ORDER BY member_id")
_END_
        
        my($rs, $pager) = $e->search_related('entry_members');
        is $pager->entries_per_page, 10;
        is $pager->current_page, 1;
        
        tie *STDERR, 'Capture';
        {
            local $::ENV{FLAPP_DEBUG} = 1;
            my @r = $e->search_related('entry_members', [], {rows => 99999})
        };
        my $s = Capture->end;
        ok $s =~ s%^Rows\(99999\) exceeded MAX_SEARCH_ROWS\(100\)\n( at .+\n)+%%;
        is $s, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_entry_members WHERE entry_id = '1' ORDER BY member_id LIMIT 100")
_END_
    }
    
    {
        $sc->new->insert for 1, 2;
        ok my $e = $se->new({category_id => 1});
        is $e->category->id, 1;
        $e->category_id(2);
        is $e->category->id, 2;
        
        $se->new({category_id => 2})->insert;
        $se->new({category_id => 2})->insert;
        
        {
            tie *STDERR, 'Capture';
            local $::ENV{FLAPP_DEBUG} = 1;
            my $ec = $e->search_related('category');
            is int @{$ec->entries}, 2;
            is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_categories WHERE id = '2'")
$(Default:0)->execute("SELECT * FROM example_entries WHERE category_id = '2' ORDER BY id")
_END_

            tie *STDERR, 'Capture';
            my $rs = $ec->search_related('entries', [],
                {select => '*.*', join => {category => {}}});
            is int @$rs, 2;
            is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT me.*, '|', category.*
FROM example_entries me
LEFT JOIN example_categories category ON category.id = me.category_id
WHERE me.category_id = '2'
ORDER BY me.id")
_END_
        }
        
        my $rs = $se->search([], {select => '*.*', join => {category => {}}, order_by => 1});
        is $rs->[0]->category_id, undef;
        is $rs->[1]->category_id, 2;
        is $rs->[2]->category_id, 2;
        
        {
            tie *STDERR, 'Capture';
            local $::ENV{FLAPP_DEBUG} = 1;
            is $rs->[1]->category, $rs->[2]->category;
            is_deeply $rs->[1]->category->entries, [$rs->[1], $rs->[2]];
            is Capture->end, '';
        }
        
        {
            tie *STDERR, 'Capture';
            local $::ENV{FLAPP_DEBUG} = 1;
            isnt $rs->[1]->category_id(1)->category, $rs->[2]->category;
            is Capture->end, <<'_END_';
$(Default:0)->execute("SELECT * FROM example_categories WHERE id = '1'")
_END_
        }
        
        {
            tie *STDERR, 'Capture';
            local $::ENV{FLAPP_DEBUG} = 1;
            is $rs->[1]->category_id(2)->category, $rs->[2]->category;
            is Capture->end, '';
        }
    }
    
    {
        my $e = $se->new;
        is $e->category_id, undef;
        my $c2 = $sc->find(2);
        $e->category($c2);
        is $e->category, $c2;
        is $e->category_id, 2;
        
        $e->category(undef);
        is $e->category_id, undef;
        
        $c2 = $sc->find(2);
        $e->category($c2);
        is $e->category, $c2;
        is $e->category_id, 2;
    }
    
    #has_relation_loaded
    {
        my $e = $se->new;
        my $em = $sem->new;
        $e->entry_members([$em]);
        ok $e->has_relation_loaded('entry_members');
        ok $em->has_relation_loaded('entry');
        
        $e = $se->new;
        $em = $sem->new;
        $em->entry($e);
        ok $em->has_relation_loaded('entry');
        ok !$e->has_relation_loaded('entry_members');
        
        $em = $sem->search->[0];
        $e = $em->entry;
        ok $em->has_relation_loaded('entry');
        ok !$e->has_relation_loaded('entry_members');
        
        $e = $se->find($e->id);
        $em = $e->entry_members->[0];
        ok $e->has_relation_loaded('entry_members');
        ok $em->has_relation_loaded('entry');
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

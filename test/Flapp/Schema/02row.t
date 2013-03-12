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

$proj->begin;
eval{
    MyTest->migrate($proj);
    
    {
        my $e = $se->new;
        $e->set_columns({id => 100, title => 'foo'});
        is $e->id, undef;
        is $e->title, 'foo';
        
        $e->set_columns({id => 99, title => 'bar'}, {-o => [qw/id/]});
        is $e->id, 99;
        is $e->title, 'foo';
        
        $e->set_columns({id => 98, title => 'bar'}, {-x => [qw/id/]});
        is $e->id, 99;
        is $e->title, 'bar';
    }
    
    {
        my $e = $se->new;
        is $e->lock_version, 1;
        is $e->set_columns({lock_version => ''})->lock_version, 1;
        is $e->set_columns({lock_version => 0})->lock_version, 1;
        is $e->set_columns({lock_version => 100})->lock_version, 100;
    }
    
    {
        my $e = $se->new({lock_version => 'a'});
        ok !$e->is_valid;
        is $e->errors->count, 4;
        ok $e->errors->has_error(title => 107);
        ok $e->errors->has_error(lock_version => 106);
        ok $e->errors->has_error(entry_members => 111);
        
        $e->id(-1)->lock_version(-1);
        ok !$e->is_valid;
        ok $e->errors->has_error(id => 109);
        ok $e->errors->has_error(lock_version => 109);
    }
    
    {
        my $e = $se->new;
        eval{ $e->update };
        like $@, qr/^Row not in_storage/;
        
        $se->new->insert;
        ok $e = $se->find(1);
        $se->find(1)->id(2)->update;
        eval{ $e->id(2)->update };
        like $@, qr/^Row not found/;
        
        ok $e = $se->find(2);
        $se->find(2)->delete;
        eval{ $e->delete };
        like $@, qr/^Row not found/;
    }
    
    {
        my $em = $sem->new({priv_cd => 1});
        ok !$em->is_valid;
        ok $em->errors->has_error(entry_id => 107);
        ok $em->errors->has_error(member_id => 107);
        
        ok !$em->entry({})->is_valid;
        ok !$em->errors->has_error(entry_id => 107);
        ok $em->errors->has_error(member_id => 107);
        
        ok $em->member({})->is_valid;
    }
    
    {
        ok $se->new->save({-l => 0});
    }
};
$proj->end;

my $msg = $@;
$DBH->prepare("drop database $DBN;")->execute;
die $msg if $msg;

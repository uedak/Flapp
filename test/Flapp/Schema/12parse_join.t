use Test::More qw/no_plan/;
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


$proj->begin;
{
    is my $se = $proj->schema->ExampleEntry, 'MyProject::Schema::Default::ExampleEntry';
    ok my $sto = $se->storage;
    
    my $ji;
    my $cols = 'title';
    $sto->parse_join_columns(\$cols, {me => ($ji = {-as => 'me', schema => $se})}, 'me');
    is $cols, 'me.title, me.id, me.category_id';
    is join('#', @{$ji->{select}{cols}}), 'me.title#me.id#me.category_id';
    
    foreach my $q (qw/ ' " /){
        $cols = "id, title, ${q}id,title${q}";
        $sto->parse_join_columns(\$cols, {me => ($ji = {-as => 'me', schema => $se})}, 'me');
        is $cols, "me.id, me.title, ${q}id,title${q}, me.category_id";
        is join('#', @{$ji->{select}{cols}}), "me.id#me.title#${q}id,title${q}#me.category_id";
        
        $cols = "id, title, ${q}id \\${q} title${q}";
        $sto->parse_join_columns(\$cols, {me => ($ji = {-as => 'me', schema => $se})}, 'me');
        is $cols, "me.id, me.title, ${q}id \\${q} title${q}, me.category_id";
        is join('#', @{$ji->{select}{cols}}),
            "me.id#me.title#${q}id \\${q} title${q}#me.category_id";
        
        $cols = "id, title, ${q}id ${q}${q} title${q}";
        $sto->parse_join_columns(\$cols, {me => ($ji = {-as => 'me', schema => $se})}, 'me');
        is $cols, "me.id, me.title, ${q}id ${q}${q} title${q}, me.category_id";
        is join('#', @{$ji->{select}{cols}}),
            "me.id#me.title#${q}id ${q}${q} title${q}#me.category_id";
    }
    
    $cols = "id, (select id from (select id, ')(' from dual)), title";
    $sto->parse_join_columns(\$cols, {me => ($ji = {-as => 'me', schema => $se})}, 'me');
    is $cols, "me.id, (select id from (select id, ')(' from dual)), me.title, me.category_id";
    is join('#', @{$ji->{select}{cols}}),
        "me.id#(select id from (select id, ')(' from dual))#me.title#me.category_id";
    
    $cols = "id, id(id, id), title";
    $sto->parse_join_columns(\$cols, {me => ($ji = {-as => 'me', schema => $se})}, 'me');
    is $cols, "me.id, id(id, id), me.title, me.category_id";
    is join('#', @{$ji->{select}{cols}}), "me.id#id(id, id)#me.title#me.category_id";
};
$proj->end;

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
    
    foreach my $q (qw/ ' " /){
        my $w = "WHERE id = ${q}id${q}";
        $sto->resolve_ambiguous($se, 'me', \$w);
        is $w, "WHERE me.id = ${q}id${q}";
        
        $w = "WHERE id = ${q} id \\${q} id ${q}";
        $sto->resolve_ambiguous($se, 'me', \$w);
        is $w, "WHERE me.id = ${q} id \\${q} id ${q}";
        
        $w = "WHERE id = ${q}\\\n id ${q}${q} id ${q}";
        $sto->resolve_ambiguous($se, 'me', \$w);
        is $w, "WHERE me.id = ${q}\\\n id ${q}${q} id ${q}";
    }
    
    my $w = "WHERE id IN (select id from (select id, ')(' from dual)) AND (id = ?)";
    $sto->resolve_ambiguous($se, 'me', \$w);
    is $w, "WHERE me.id IN (select id from (select id, ')(' from dual)) AND (me.id = ?)";
    
    $w = 'WHERE id = id';
    $sto->resolve_ambiguous($se, 'me', \$w);
    is $w, "WHERE me.id = me.id";
    
    $w = 'WHERE id(id, id) = id';
    $sto->resolve_ambiguous($se, 'me', \$w);
    is $w, "WHERE id(me.id, me.id) = me.id";
};
$proj->end;

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
use MyProject::Schema::R3;
my $proj = 'MyProject';

$proj->begin;
my $cfg = $proj->Config->src($proj->config);
$cfg->{DB}{R3}{dsn} = [['dbi:mysql:r3']];
local $proj->_global_->{config}{$proj->env} = $proj->Config->new($cfg);
my $G1 = MyProject::Schema::R3->G1;
my $G2 = MyProject::Schema::R3->G2;
my $G3 = MyProject::Schema::R3->G3;
{
    my $g1_1 = $G1->new;
    $g1_1->g2s([{}, {}]);
    is int @{$g1_1->g2s}, 2;
    
    $_->g3s([{}, {}]) for @{$g1_1->g2s};
    is int (my @g2s = @{$g1_1->g2s}), 2;
    is int (my @g3s = @{$g1_1->g3s}), 4;
    
    $g1_1->id(100);
    is $_->g1_id, 100 for @g2s, @g3s;
};

{
    my $g1_1 = $G1->new->g2s([{}]);
    $g1_1->g2s->[0]->g3s([{}]);
    my $g2_1 = $g1_1->g2s->[0];
    my $g3_1 = $g2_1->g3s->[0];
    
    is_deeply $g1_1->g2s, [$g2_1];
    is_deeply $g1_1->g3s, [$g3_1];
    is $g2_1->g1, $g1_1;
    is_deeply $g2_1->g3s, [$g3_1];
    is $g3_1->g1, $g1_1;
    is $g3_1->g2, $g2_1;
    
    $g1_1->id(100);
    is $g2_1->g1_id, 100;
    is $g3_1->g1_id, 100;
    $g1_1->id(undef);
    is $g2_1->g1_id, undef;
    is $g3_1->g1_id, undef;
    
    
    
    my $g3_2 = $G3->new->g2({})->g1({});
    my $g2_2 = $g3_2->g2;
    my $g1_2 = $g3_2->g1;
    
    is_deeply $g1_2->g2s, [$g2_2];
    is_deeply $g1_2->g3s, [$g3_2];
    is $g2_2->g1, $g1_2;
    is_deeply $g2_2->g3s, [$g3_2];
    is $g3_2->g1, $g1_2;
    is $g3_2->g2, $g2_2;
    
    $g1_2->id(200);
    is $g2_2->g1_id, 200;
    is $g3_2->g1_id, 200;
    $g1_2->id(undef);
    is $g2_2->g1_id, undef;
    is $g3_2->g1_id, undef;
    
    
    
    $g1_1->g2s([$g2_2]);
    
    
    
    is_deeply $g1_1->g2s, [$g2_2];
    is_deeply $g1_1->g3s, [$g3_2];
    is $g2_1->g1, undef;
    is_deeply $g2_1->g3s, [$g3_1];
    is $g3_1->g1, undef;
    is $g3_1->g2, $g2_1;
    
    is_deeply $g1_2->g2s, [];
    is_deeply $g1_2->g3s, [];
    is $g2_2->g1, $g1_1;
    is_deeply $g2_2->g3s, [$g3_2];
    is $g3_2->g1, $g1_1;
    is $g3_2->g2, $g2_2;
};

{
    my $nc1 = MyProject::Schema::R3->Nc1->new;
    my $nc2 = MyProject::Schema::R3->Nc2->new;
    $nc2->nc1($nc1);
    is $nc2->nc1, $nc1;
    is_deeply $nc1->nc2s, [];
}

$proj->end;

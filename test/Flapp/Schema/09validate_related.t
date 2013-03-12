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
    $g1_1->g2s([{g2_type => 1}, {g2_type => 2}]);
    $_->g3s([{g3_type => 1}, {g3_type => 2}]) for @{$g1_1->g2s};
    
    $g1_1->validate->validate_related('g2s');
    $_->validate_related('g3s') for @{$g1_1->g2s};
    
    is_deeply $g1_1->errors->messages, [
        "[名前] 入力されていません",
        "[G2(1) 名前] 入力されていません",
        "[G2(1) G3(1) 名前] 入力されていません",
        "[G2(1) G3(2) 名前] 入力されていません",
        "[G2(2) 名前] 入力されていません",
        "[G2(2) G3(1) 名前] 入力されていません",
        "[G2(2) G3(2) 名前] 入力されていません",
    ];
};

{
    my $g1_1 = $G1->new;
    $g1_1->g2s([{g2_type => 1}, {g2_type => 2}]);
    $_->g3s([{g3_type => 1}, {g3_type => 2}]) for @{$g1_1->g2s};
    
    $_->validate_related('g3s') for @{$g1_1->g2s};
    $g1_1->validate_related('g2s')->validate;
    
    is_deeply $g1_1->errors->messages, [
        "[G2(1) G3(1) 名前] 入力されていません",
        "[G2(1) G3(2) 名前] 入力されていません",
        "[G2(1) 名前] 入力されていません",
        "[G2(2) G3(1) 名前] 入力されていません",
        "[G2(2) G3(2) 名前] 入力されていません",
        "[G2(2) 名前] 入力されていません",
        "[名前] 入力されていません",
    ];
};

{
    my $g1_1 = $G1->new;
    $g1_1->g2s([{g2_type => 1}, {g2_type => 2}]);
    $_->g3s([{g3_type => 1}, {g3_type => 2}]) for @{$g1_1->g2s};
    
    $g1_1->validate_related('g3s');
    is_deeply $g1_1->errors->messages, [
        "[G3(1) 名前] 入力されていません",
        "[G3(2) 名前] 入力されていません",
        "[G3(3) 名前] 入力されていません",
        "[G3(4) 名前] 入力されていません"
    ];
};

$proj->end;

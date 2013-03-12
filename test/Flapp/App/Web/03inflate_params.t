use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
use strict;
use warnings;

if(!eval{ require Plack }){
    $::INC{'Plack/Request.pm'} = $::INC{'Plack/Response.pm'} = $::INC{'HTTP/Body.pm'} = 1;
    no warnings;
    *Plack::Request::new = *Plack::Response::new = sub{};
}

use MyProject;
ok my $proj = 'MyProject';
is my $app = $proj->app('MyWebApp'), 'MyProject::MyWebApp';
$proj->begin;

{
    my $c = $app->new({});
    is_deeply $c->inflate_params({'foo[]' => 1, 'bar[' => 2}), {foo => [1], 'bar[' => 2};
    
    is_deeply $c->inflate_params({'foo[]' => ''}), {foo => []};
    is_deeply $c->inflate_params({'foo[]' => '', foo => 2}), {foo => [2]};
    is_deeply $c->inflate_params({'foo[bar]' => ''}), {foo => {bar => ''}};
    
    is_deeply $c->inflate_params({'foo[1][bar]' => 1}), {foo => {1 => {bar => 1}}};
    is_deeply $c->inflate_params({'foo[1][bar]' => 1, 'foo[0][bar]' => 0}),
        {foo => [{bar => 0}, {bar => 1}]};
    
    
    is_deeply $c->inflate_params({'x[]' => 1, 'x[1][y]' => 1}), {x => [1, {y => 1}]};
    is_deeply $c->inflate_params({'x[]' => [1, 2]}), {x => [1, 2]};
    is_deeply $c->inflate_params({'x[]' => ['', 2]}), {x => ['', 2]};
    is_deeply $c->inflate_params({'x[0][]' => 1, 'x[1][]' => 2}), {x => [[1], [2]]};
    is_deeply $c->inflate_params({'x[y][0][z]' => 2}), {x => {y => [{z => 2}]}};
    
    #print $c->_dump_($c->inflate_params({}));
}

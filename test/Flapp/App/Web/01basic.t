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

{
    ok my $c = $app->new({});
}

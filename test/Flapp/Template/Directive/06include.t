use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
use strict;
use warnings;

my $dir = Cwd::abs_path("$FindBin::Bin/06include");
use MyProject;
my $P = MyProject->Template->Parser;
ok my $p = $P->new;
MyProject->begin;

{
    is $p->open([$dir, '/index.ft'])->init->render, <<_END_;
<div id="header">
<h1>(TITLE)</h1>
</div>
INDEX
<div id="footer">
FOOTER
</div>
_END_
}

{
    ok !eval{ $p->open };
    like $@, qr/^No location/;
    
    ok !eval{ $p->open([]) };
    like $@, qr/^No base dir/;
    
    ok !eval{ $p->open([$dir]) };
    like $@, qr/^No src/;
    
    ok !eval{ $p->open([$dir, '/missing.ft'])->init->render };
    like $@, qr{^\Q$!($dir/404.ft)\E\n(.+\n)+ at \[%- INCLUDE \($dir/missing\.ft 2\)\n};
}

{
    is $p->open([$dir, '/foo.ft'])->init({stash => {foo => 'FOO'}})->render, <<_END_;
<FOO>
<FOO>
_END_
}

use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
use strict;
use warnings;

my $dir = Cwd::abs_path("$FindBin::Bin/07insert");
use MyProject;
my $P = MyProject->Template->Parser;
ok my $p = $P->new;
MyProject->begin;

{
    is $p->open([$dir, '/index.ft'])->init->render, <<_END_;
<div id="header">
HEADER
</div>
INDEX
<div id="footer">
FOOTER
</div>
_END_
}

{
    is $p->open([$dir, '/foo/bar.ft'])->init->render, <<_END_;
<div id="header">
HEADER
</div>
BAR
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
    like $@, qr{^^\Q$!($dir/404.ft)\E\n(.+\n)+ at \[%- INSERT \($dir/missing\.ft 2\)\n};
}

use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
use strict;
use warnings;

my $dir = Cwd::abs_path("$FindBin::Bin/09wrapper");
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
    ok !eval{ $p->open([$dir, '/_layout.ft'])->init->render };
    like $@, qr{^No WRAPPER
(.+\n)+ at \[%- CONTENT \($dir/_layout\.ft 4\)\n};
}

{
    is $p->open([$dir, '/index2.ft'])->init->render, <<_END_;
<div id="header">
<h1>(TITLE)</h1>
</div>
<h2>title</h2>
INDEX
<a>pagetop</a>
<div id="footer">
FOOTER
</div>
_END_
}

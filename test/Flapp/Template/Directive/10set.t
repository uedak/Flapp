use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
use strict;
use warnings;

use MyProject;
ok my $p = MyProject->Template->Parser->new;
MyProject->begin;

{
    ok my $ft = $p->open(\<<_END_);
[%- SET x = foo -%]
[%- SET x =~ s/./X/ -%]
[% x %]
_END_
    is $ft->init({stash => {foo => 'xxx'}})->render, "Xxx\n";
}

{
    is $p->open(\'[% SET foo.bar = "FOOBAR" %][% foo.bar %]')->init->render, 'FOOBAR';
}

{
    ok my $ft = $p->open(\<<'_END_');
[%- SET list = [
    'a', #A
    'b', #B
    'c', #C
] -%]
[% join('#', @{list}) %]
_END_
    is $ft->init->render, "a#b#c\n";
}

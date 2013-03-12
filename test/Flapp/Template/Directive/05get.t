use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
use strict;
use warnings;

use MyProject;
my $P = MyProject->Template->Parser;
ok my $p = $P->new;
MyProject->begin;

{
    ok !eval{ $p->open(\'[% foo | test([1]) %]') };
    like $@, qr/^Invalid filter\(test\)\n at \[% foo \(\? 1\)\n/;
}

{
    no warnings 'once';
    local *MyProject::Template::Filter::test = sub{
        my($f, $r, $i) = @_;
        $$r = ++$_[2];
    };
    
    ok my $ft = $p->open(\'[% foo | test(1) %]');
    is  $ft->init->render, 2;
    is  $ft->init->render, 2;
    
    ok $ft = $p->open(\'[% foo | test(i) %]')->init({stash => {i => 1}});
    is  $ft->render, 2;
    is  $ft->init->render, 2;
    
    ok !eval{ $ft = $p->open(\'[% foo() %]')->init({stash => {i => 1}})->render };
    like $@, qr/^Undefined subroutine &main::foo called/;
}

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
    my $src = <<'_END_';

[%- SWITCH foo #test -%]
[%- CASE 'a' #test -%]
A
[%- CASE ['b', 'c'] #test -%]
BC
[%- CASE #test -%]
?
[%- END #test -%]
_END_
    
    my $ft = $p->open(\$src);
    is $ft->init({stash => {foo => 'a'}})->render, "\nA\n";
    is $ft->init({stash => {foo => 'b'}})->render, "\nBC\n";
    is $ft->init({stash => {foo => 'c'}})->render, "\nBC\n";
    is $ft->init({stash => {foo => 'd'}})->render, "\n?\n";
}

{
    my $src = <<'_END_';

[%- SWITCH foo -%]
[%- CASE 'a' -%]
A
[%- CASE ['b', 'c'] -%]
BC
[%- CASE -%]
?
[%- END -%]
_END_
    
    my $ft = $p->open(\$src);
    is $ft->init({stash => {foo => 'a'}})->render, "\nA\n";
    is $ft->init({stash => {foo => 'b'}})->render, "\nBC\n";
    is $ft->init({stash => {foo => 'c'}})->render, "\nBC\n";
    is $ft->init({stash => {foo => 'd'}})->render, "\n?\n";
}

{
    my $src = <<'_END_';

[%- SWITCH foo -%]
[%- CASE , -%]
[%- END -%]
_END_
    
    eval{ $p->open(\$src) };
    like $@, qr/^Syntax error near `,`\n +at \Q[%- CASE (? 3)\E/;
}

{
    my $src = <<'_END_';

[%- SWITCH foo -%]
[%- CASE bar -%]
[%- END -%]
_END_
    
    tie *STDERR, 'Capture';
    $p->open(\$src)->init->render;
    is Capture->end, '';
    
    $p->{WARNINGS} = 1;
    tie *STDERR, 'Capture';
    $p->open(\$src)->init->render;
    like Capture->end, qr/Use of uninitialized value.* in string eq/;
}

package Capture;
sub TIEHANDLE { bless \(my $buf = ''), shift }
sub PRINT { ${+shift} .= shift }
sub end {
    (my $s = ${tied *STDERR}) =~ s/^-+\n//mg;
    untie *STDERR;
    $s;
}

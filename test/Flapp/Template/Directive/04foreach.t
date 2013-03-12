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

[%- FOREACH x IN list #test -%]
[% "(${loop.count})${x}" #test %]
[%- END #test -%]
_END_
    
    my $ft = $p->open(\$src);
    is $ft->init->render, "\n";
    is $ft->init({stash => {list => [qw/a b c/]}})->render, "\n(1)a\n(2)b\n(3)c\n";
    
    $ft = $P->new({STRICT => 1})->open(\$src);
    ok !eval{ $ft->init->render };
    like $@, qr/^"list" was not declared in this scope\n(.+\n)+ at \[%- FOREACH \(\? 2\)\n/;
    
    ok !eval{ $ft->init({stash => {list => undef}})->render };
    like $@, qr/^Can't use "" as an ARRAY ref while "strict refs" in use
(.+\n)+ at \[%- FOREACH \(\? 2\)\n/;
    
    ok !eval{ $ft->init({stash => {list => {}}})->render };
    like $@, qr/^Can't use "HASH\(\w+\)" as an ARRAY ref while "strict refs" in use
(.+\n)+ at \[%- FOREACH \(\? 2\)\n/;
}

{
    my $ft = $p->open(\<<'_END_');
[%- FOREACH x IN [1,2,3] #test -%]
[% x #test %]
[%- LAST IF loop.count == 2 #test -%]
[%- END #test -%]
_END_

    is $ft->init->render, "1\n2\n";
}

{
    my $ft = $p->open(\<<'_END_');
[%- SET loop = {count => 'C'} -%]
[% loop.count %]
[%- FOREACH x IN list #test -%]
[%- LAST IF loop.count == 3 #test -%]
[% x #test %]
[%- END #test -%]
[% loop.count %]
_END_

    is $ft->init({stash => {list => [qw/a b c d e/]}})->render, "C\na\nb\nC\n";
    
    ok !eval{ $p->open(\"\n[% LAST %]")->init->render };
    like $@, qr/^Can't "LAST" outside a loop block\n(.+\n)+ at \[% LAST \(\? 2\)\n/;
}

{
    my $ft = $p->open(\<<'_END_');
[%- SET loop = {count => 'C'} -%]
[% loop.count %]
[%- FOREACH x IN list #test -%]
[%- NEXT IF loop.count == 3 #test -%]
[% x #test %]
[%- END #test -%]
[% loop.count %]
_END_

    is $ft->init({stash => {list => [qw/a b c d e/]}})->render, "C\na\nb\nd\ne\nC\n";
    
    ok !eval{ $p->open(\"\n[% NEXT %]")->init->render };
    like $@, qr/^Can't "NEXT" outside a loop block\n(.+\n)+ at \[% NEXT \(\? 2\)\n/;
}

{
    my $ft = $p->open(\<<'_END_');
[%- FOREACH x IN list #test -%]
count:[% loop.count %]
even:[% loop.even %]
first:[% loop.first %]
index:[% loop.index %]
last:[% loop.last %]
max:[% loop.max %]
next:[% loop.next %]
odd:[% loop.odd %]
parity:[% loop.parity %]
prev:[% loop.prev %]
size:[% loop.size %]
---
[%- END #test -%]
_END_

    is $ft->init({stash => {list => [qw/a b c/]}})->render, <<_END_;
count:1
even:
first:1
index:0
last:
max:2
next:b
odd:1
parity:odd
prev:
size:3
---
count:2
even:1
first:
index:1
last:
max:2
next:c
odd:
parity:even
prev:a
size:3
---
count:3
even:
first:
index:2
last:1
max:2
next:
odd:1
parity:odd
prev:b
size:3
---
_END_

}

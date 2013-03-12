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
    my $ft = $p->open(\<<'_END_');
[%- IF a == 1 #test -%]
a1
[%- ELSIF a == 2 #test -%]
a2
[%- ELSIF a == 3 #test -%]
a3
[%- ELSE #test -%]
a?
[%- END #test -%]
_END_
    is $ft->init({stash => {a => 1}})->render, "a1\n";
    is $ft->init({stash => {a => 2}})->render, "a2\n";
    is $ft->init({stash => {a => 3}})->render, "a3\n";
    is $ft->init({stash => {a => 0}})->render, "a?\n";
    is $p->open(\'[% IF a == 1 %][% END %]')->init->render, '';
    
    $ft = $p->open(\'[% IF a =~ /[abc]/ %]ok[% ELSE %]ng[% END %]');
    is $ft->init->render, 'ng';
    is $ft->init({stash => {a => 'b'}})->render, 'ok';
    is $ft->init({stash => {a => 'B'}})->render, 'ng';
    
    $ft = $p->open(\'[% IF a =~ /[abc]/i %]ok[% ELSE %]ng[% END %]');
    is $ft->init({stash => {a => 'B'}})->render, 'ok';
    
    $ft = $p->open(\'[% IF a =~ /${b}/ %]ok[% ELSE %]ng[% END %]');
    is $ft->init->render, 'ok';
    is $ft->init({stash => {b => 'b'}})->render, 'ng';
    is $ft->init({stash => {a => 'abc', b => 'b'}})->render, 'ok';
    is $ft->init({stash => {a => 'abc', b => 'b$'}})->render, 'ng';
    is $ft->init({stash => {a => 'ab', b => 'b$'}})->render, 'ok';
}

{
    my $ft = $p->open(\<<'_END_');
[%- IF a =~ /a/ || a =~ /b/ -%]OK[% END %]
_END_
    is $ft->init({stash => {a => 1}})->render, "\n";
    is $ft->init({stash => {a => 'a'}})->render, "OK\n";
}

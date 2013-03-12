use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use strict;
use warnings;

if(!eval{ require Plack }){
    $::INC{'Plack/Request.pm'} = $::INC{'Plack/Response.pm'} = $::INC{'HTTP/Body.pm'} = 1;
    no warnings;
    *Plack::Request::new = *Plack::Response::new = sub{};
}

use MyProject;
is (MyProject->Template, 'MyProject::Template');

my $P = MyProject->Template->Parser;
MyProject->begin;
my $p   = $P->new;
my $sp  = $P->new({STRICT => 1});
my $wp  = $P->new({WARNINGS => 1});
my $swp = $P->new({STRICT => 1, WARNINGS => 1});
my %opt = (context => MyProject->app('MyWebApp')->new({}), auto_filter => [qw/html/]);

{ #test for var
    
    my $ft = $p->open(\'[% foo %]')->init({stash => {foo => 'Hello World'}, %opt});
    is $ft->render, 'Hello World';

    is $p->open(\'[% Flapp.dump([{x, y}, z]) | raw %]')
        ->init({stash => {Flapp => 'Flapp'}, %opt})->render, "[{'' => undef},undef]";
    
    is $p->open(\'-[% x %]-')->init({%opt})->render, "--";
    is $p->open(\'-[% x _ y %]-')->init({%opt})->render, "--";
}

{
    my $ft = $p->open(\"[% foo %] => [% foo | raw %]");
    is $ft->init({stash => {foo => qq[\n"&'()<>]}, %opt})->render,
        qq[<br />&quot;&amp;&#39;&#40;&#41;&lt;&gt; => \n"&'()<>];
}

{
    is $p->open(\'[% foo %]')->init->render, '';
    ok !eval{ $sp->open(\'[% foo %]')->init->render };
    like $@, qr/^"foo" was not declared in this scope\n(.+\n)+ at \[% foo \(\? 1\)\n/;
    
    my $ft = $sp->open(\'[% foo.bar %]');
    is $ft->init({stash => {foo => {bar => 'foobar'}}, %opt})->render, 'foobar';
    
    $ft = $sp->open(\'[% foo.bar() %]');
    ok !eval{ $ft->init({stash => {foo => {bar => 'foobar'}}, %opt})->render };
    like $@, qr/^Can't call method "bar" on unblessed reference
(.+\n)+ at \[% foo\.bar\(\) \(\? 1\)\n/;
    
    $ft = $sp->open(\'[% foo.bar %]');
    ok !eval{ $ft->init({stash => {foo => []}, %opt})->render };
    like $@, qr/^Can't use "foo" as a HASH ref\n(.+\n)+ at \[% foo\.bar \(\? 1\)\n/;
    
    $ft = $sp->open(\'[% foo["bar"] %]');
    is $ft->init({stash => {foo => {bar => 'foobar'}}, %opt})->render, 'foobar';
    ok !eval{ $ft->init({stash => {foo => 'x'}, %opt})->render };
    like $@, qr/^Can't use "foo" as a HASH or ARRAY ref\n(.+\n)+ at \[% foo\["bar"\] \(\? 1\)\n/;
    
    $ft = $p->open(\"[% foo['bar'] %]");
    is $ft->init({stash => {foo => []}, %opt})->render, '';
    
    ok !eval{ $p->open(\'[% foo[] %]') };
    like $@, qr/^Syntax error near `foo\[\]`\n at \[% foo\[\] \(\? 1\)\n/;
    
    ok !eval{ $p->open(\'[% foo[ ] %]') };
    like $@, qr/^Syntax error near `foo\[ \]`\n at \[% foo\[ \(\? 1\)\n/;
    
    
    
    $ft = $sp->open(\'[% foo[1] %]');
    is $ft->init({stash => {foo => [qw/a b c/]}, %opt})->render, 'b';
    ok !eval{ $ft->init({stash => {foo => 'x'}, %opt})->render };
    like $@, qr/^Can't use "foo" as a HASH or ARRAY ref\n(.+\n)+ at \[% foo\[1\] \(\? 1\)\n/;
    
    $ft = $p->open(\'[% foo[1] %]');
    is $ft->init({stash => {foo => {}}, %opt})->render, '';
    
    ok !eval{ $p->open(\'[% foo[] %]') };
    like $@, qr/^Syntax error near `foo\[\]`\n at \[% foo\[\] \(\? 1\)\n/;
    
    ok !eval{ $p->open(\'[% foo[ ] %]') };
    like $@, qr/^Syntax error near `foo\[ \]`\n at \[% foo\[ \(\? 1\)\n/;
    
    is $p->open(\'[% x _ y %]')->init({stash => {x => 'X', y => 'Y'}, %opt})->render, 'XY';
    is $p->open(\q/[% join('#', map({ 1 } 1 .. 3)) %]/)->init->render, '1#1#1';
    is $p->open(\q/[% join('#', map({ $_ } 1 .. 3)) %]/)->init->render, '1#2#3';
    is $p->open(\q/[% join('#', grep({ $_ % 2 } 1 .. 10)) %]/)->init->render, '1#3#5#7#9';
    is $p->open(\q{[% join('#', grep({ /[2-4]/ } 1 .. 5)) %]})->init->render, '2#3#4';
    like $p->open(\q{[% foo %]})->init({stash => {foo => {}}, %opt})->render, qr/^HASH\(\w+\)\z/;
    
    is $p->open(\q/[% join('#', grep({ $_ % 2 } 1 .. 5)) %]/)->init->render, '1#3#5';
    is $p->open(\q/[% join('#', map({ $_.x } ({x => 1}, {x => 2}, {x => 3}))) %]/)->init->render, '1#2#3';
    
    is $p->open(\q/[% join('#', map({ h[$_] } (1 .. 3))) %]/)->init({stash => {h => {2 => 'X'}}})->render, '#X#';
    
    is $p->open(\'[% (x || y).z %]')->init({stash => {y => {z => 'Z'}}, %opt})->render, 'Z';
    
    is $p->open(\q{[% join(':', map({ $_ + 1 } sort({ $b cmp $a } split(/,/, '1,3,20')))) %]})->init->render, '4:21:2';
    
    is $p->open(\q{[% join(':', map({ $_ + 1 } sort({ $b <=> $a } split(/,/, '3,20,1')))) %]})->init->render, '21:4:2';
    
    is $p->open(\q{[% c.include_path[-1] %]})
        ->init({stash => {c => MyProject->app('MyWebApp')->new({})}})
        ->render, Flapp->root_dir.'/view';
    
    is $p->open(\q{[% foo.bar %]})->init->render, '';
    
    is $p->open(\q{[% foo.bar %]})->init({stash => {foo => '1a'}})->render, '';
    
    is $p->open(\q{[% SET x ||= 100 %][% x %]})->init->render, 100;
    
    is $p->open(\q{[% SET x[y] ||= 100 %][% x[y] %]})
        ->init({stash => {x => {}, y => 'y'}})->render, 100;
    
    is $p->open(\q{[% SET x[y.z] = y.z %][% x[y.z] %]})
        ->init({stash => {x => {}, y => {z => 'z'}}})->render, 'z';
    
    is $p->open(\q{[% SET x += 3 %][% x %]})
        ->init({stash => {x => 2}})->render, 5;
    
    is $p->open(\q{[% SET x ||= 'Y' %][% x %]})
        ->init({stash => {x => 'X'}})->render, 'X';
    
    is $p->open(\q{[% SET x &&= 'Y' %][% x %]})
        ->init({stash => {x => 'X'}})->render, 'Y';
    
    is $p->open(\q{[% SET map({$_['x'] ||= 'Y'} (X)) %][% X.x %]})
        ->init({stash => {X => {x => 0}}})->render, 'Y';
    
    is $p->open(\q{[% SET map({$_['x'] ||= 'Y'} (X)) %][% X.x %]})
        ->init({stash => {X => {x => 'X'}}})->render, 'X';
    
    
    
    tie *STDERR, 'Capture';
    
    $ft = $p->open(\'[% foo %]');
    is $ft->init->render, '';
    is ${tied *STDERR}, '';
    
    $ft = $wp->open(\'[% foo %]');
    is $ft->init->render, '';
    like ${tied *STDERR}, qr/^Use of undefined value: "foo"\n(.+\n)+ at \[% foo \(\? 1\)\n/;
    ${tied *STDERR} = '';
    
    $ft = $sp->open(\'[% foo %]');
    is $ft->init({stash => {foo => undef}, %opt})->render, '';
    is ${tied *STDERR}, '';
    
    $ft = $swp->open(\'[% foo %]');
    is $ft->init({stash => {foo => undef}, %opt})->render, '';
    like ${tied *STDERR}, qr/^Use of undefined value: "foo"\n(.+\n)+ at \[% foo \(\? 1\)\n/;
    ${tied *STDERR} = '';
    
    
    
    $ft = $wp->open(\'[% foo.bar %]');
    is $ft->init({stash => {foo => {}}, %opt})->render, '';
    like ${tied *STDERR}, qr/^Use of undefined value: "foo\.bar"
(.+\n)+ at \[% foo\.bar \(\? 1\)\n/;
    ${tied *STDERR} = '';
    
    is $ft->init({stash => {foo => []}, %opt})->render, '';
    like ${tied *STDERR}, qr/^Use of undefined value: "foo\.bar"
(.+\n)+ at \[% foo\.bar \(\? 1\)\n/;
    ${tied *STDERR} = '';
    
    untie *STDERR;
}

{ #test for block
    my $src = <<'_END_';
[%- SET x = '[x]' -%]
[%- SET X = '[X]' -%]
[%- SET loop = {count => 100} -%]
[%- SET i = '[i]' -%]
[%- FOREACH i IN ['[I]'] -%]
    [%- SET x = y = X = Y = '[y]' -%]
    [%- "${x}-${y}-${X}-${Y}-${loop.count}-${i}" %]
[%- END -%]
[% "${x}-${y}-${X}-${Y}-${loop.count}-${i}" %]
_END_
    
    is $p->open(\$src)->init->render, "[y]-[y]-[y]-[y]-1-[I]\n[y]--[y]-[y]-100-[i]\n";
    
    ok !eval{ $sp->open(\$src)->init->render };
    like $@, qr/^"y" was not declared in this scope
(.+\n)+ at \[% "\${x}-\${y}-\${X}-\${Y}-\${loop.count}-\${i}" \(\? 9\)\E\n/;
}

{ #TRIM_INDENT
    my $src = <<'_END_';
AAA
    BBB

CCC
_END_
    is $P->new({TRIM_INDENT => 1})->open(\$src)->init->render, "AAA\nBBB\n\nCCC\n";
    
    $src = <<'_END_';
AAA
    BBB

[% IF %]
_END_
    
    eval{ $P->new({TRIM_INDENT => 1})->open(\$src) };
    like $@, qr/^Syntax error\n at \[% IF \(\? 4\)/;
}

{ #CR
    my $src = "a\r [%- IF 0 -%] \rb\r[%- END -%]\rc\r";
    is $P->new({})->open(\$src)->init->render, "a\rc\r";
}

package Capture;
sub TIEHANDLE { bless \(my $buf = ''), shift }
sub PRINT { ${+shift} .= shift }

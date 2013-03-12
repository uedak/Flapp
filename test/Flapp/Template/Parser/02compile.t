use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
use strict;
use warnings;

use MyProject;
ok my $p = MyProject->Template->Parser->new;
$p->{pragma} = '';

{
    my($src, @res);
    ok(@res = $p->compile('"/${x || y}/"'));
    is $res[1], q{"/".($_[0]->var('x') || $_[0]->var('y'))."/"};
    
    ok(@res = $p->compile(\($src = q{join("#", @{foo})})));
    is $res[1], q{join("#", @{$_[0]->var('foo') || []})};
    
    ok(@res = $p->compile(\($src = q{foo.bar.bar(1).baz(x || 100)})));
    is $res[1], q{$_[0]->var('foo', ['.', 'bar'], ['.', 'bar', [1]], ['.', 'baz', sub{ [$_[0]->var('x') || 100] }])};
    
    ok(@res = $p->compile(\($src = q{foo.bar['baz'][0][-1]["-${x}-"]})));
    is $res[1], q%$_[0]->var('foo', ['.', 'bar'], ['[', 'baz'], ['[', 0], ['[', -1], ['[', sub{ "-".($_[0]->var('x'))."-" }])%;
    
    ok(@res = $p->compile(\($src = '"foo$a@a${bar.bar}baz"')));
    is $res[1], q{"foo\$a\@a".($_[0]->var('bar', ['.', 'bar']))."baz"};
    
    ok(@res = $p->compile(\($src = q{xxx =~ /^.+\z/})));
    is $res[1], q{$_[0]->var('xxx') =~ /^.+\z/};
    
    ok(@res = $p->compile(\($src = q{xxx =~ m{^\w+${foo}\w+\z}})));
    is $res[1], q{$_[0]->var('xxx') =~ m{^\w+(??{ $_[0]->var('foo') })\w+\z}};
    
    ok(@res = $p->compile(\($src = q{foo = bar})));
    is $res[1], q{$_[0]->var('foo', '=') = $_[0]->var('bar')};
    
    ok(@res = $p->compile(\($src = q{foo = FOO = 1})));
    is $res[1], q{$_[0]->var('foo', '=') = $_[0]->var('FOO', '=') = 1};
    
    ok(@res = $p->compile(\($src = q{foo = {bar => baz, hoge, fuga}})));
    is $res[1], q{$_[0]->var('foo', '=') = {bar => $_[0]->var('baz'), $_[0]->var('hoge'), $_[0]->var('fuga')}};
    
    ok(@res = $p->compile('/.+/'));
    is $res[1], '/.+/';
    
    ok(@res = $p->compile(' /.+/ '));
    is $res[1], ' /.+/ ';
    
    ok(@res = $p->compile('xxx =~ s/././g'));
    is $res[1], q{$_[0]->var('xxx', '=') =~ s/././g};
    
    ok(@res = $p->compile('xxx =~ s{.}{.}'));
    is $res[1], q{$_[0]->var('xxx', '=') =~ s{.}{.}};
    
    ok(@res = $p->compile('(x || y).z'));
    is $res[1], q{$_[0]->var(sub{ $_[0]->var('x') || $_[0]->var('y') }, ['.', 'z'])};
    
    ok(@res = $p->compile('join((x || y).z, 1)'));
    is $res[1], q{join($_[0]->var(sub{ $_[0]->var('x') || $_[0]->var('y') }, ['.', 'z']), 1)};
    
    local $p->{ln} = 1;
    ok !$p->compile('');
    is $p->error, "Syntax error";
    
    ok !$p->compile(' ');
    is $p->error, "Syntax error near ` `";
    
    ok !$p->compile(q{join('#', 1, 2});
    is $p->error, "Missing right bracket ')' near `join('#', 1, 2`";
    
    ok !$p->compile('(1, 2, 3');
    is $p->error, "Missing right bracket ')' near `(1, 2, 3`";
    
    ok !$p->compile('x || [1 .. 10');
    is $p->error, "Missing right bracket ']' near `[1 .. 10`";
    
    ok !$p->compile('x + @{foo.bar');
    is $p->error, "Missing right bracket '}' near `\@{foo.bar`";
    
    ok !$p->compile('1, 2');
    is $p->error, "Syntax error near `1, `";
    
    ok !$p->compile('"x');
    is $p->error, qq{Can't find string terminator '"' anywhere near `"x`};
}

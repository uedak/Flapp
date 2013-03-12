use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
use strict;
use warnings;

use MyProject;
ok my $P = MyProject->Template->Parser;
MyProject->begin;

{
    my $src = <<'_END_';
[%- BLOCK foo #test -%]
    <<[% "${bar}/${baz}/${hoge}" %]>>
[%- END #test -%]
[%- SET baz = '<BAZ>' -%]
[% PROCESS foo bar='<BAR>' baz=baz #test %]
_END_
    
    is $P->new->open(\$src)->init->render, "    <<<BAR>/<BAZ>/>>\n\n";
    
    ok !eval{ $P->new({STRICT => 1})->open(\$src)->init->render };
    like $@, qr{^"hoge" was not declared in this scope
(.+\n)+ at \[% "\${bar}/\${baz}/\${hoge}" \(\? 2\)\n at \[% PROCESS \(\? 5\)\n}; #"
    
    ok !eval{ $P->new->open(\'[% PROCESS hoge %]')->init->render };
    like $@, qr/^No BLOCK\n(.+\n)+ at \[% PROCESS \(\? 1\)\n/;
}

{
    my $ft = $P->new->open(\<<'_END_');
[%- BLOCK foo -%]
    [%- FOREACH k IN [sort(keys(%{h}))] -%]
        [%- "${(' ' x i)}${k}" -%]:
        [%- PROCESS foo h=h["${k}"] i=i+1 -%]
    [%- END -%]
[%- END -%]
[%- PROCESS foo h=h i=0 -%]
_END_
    
    is $ft->init->render, '';
    is $ft->init({stash => {h => {a => {}}}})->render, "a:\n";
    is $ft->init({stash => {h => {a => {}, b => {c => {d => {}}}, e => {}}}})->render, <<_END_;
a:
b:
 c:
  d:
e:
_END_
}

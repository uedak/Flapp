use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
use strict;
use warnings;

use MyProject;
ok my $p = MyProject->Template->Parser->new;

{
    ok !eval{ $p->parse(\"\n[%x%]") };
    is $@, qq{No white space after "[%"\n at (? 2)\n};
    
    ok !eval{ $p->parse(\"\n[% x%]") };
    is $@, qq{No white space before "%]"\n at (? 2)\n};
    
    ok !eval{ $p->parse(\"\n[%-x-%]") };
    is $@, qq{No white space after "[%-"\n at (? 2)\n};
    
    ok !eval{ $p->parse(\"\n[%- x-%]") };
    is $@, qq{No white space before "-%]"\n at (? 2)\n};
    
    #ok !eval{ $p->parse(\"\nxxx %]") };
    #is $@, qq{No "[%"\n at (? 2)\n};
    
    ok !eval{ $p->parse(\"\n[%\n\n") };
    is $@, qq{No "%]" after "[%"\n at (? 2)\n};
    
    ok !eval{ $p->parse(\"\n[% `ls` %]\n") };
    is $@, qq{Syntax error near ``ls``\n at \[% `ls` (? 2)\n};
    
    ok !eval{ $p->parse(\"\n[% END %]\n") };
    is $@, qq{No begin directive\n at [% END (? 2)\n};
    
    ok !eval{ $p->parse(\"\n[% IF %]\n") };
    is $@, qq{Syntax error\n at [% IF (? 2)\n};
    
    ok !eval{ $p->parse(\"\n[% IF 1 %]\n[% x %]\n") };
    is $@, qq{No "END" directive\n at [% IF (? 2)\n};
    
    ok !eval{ $p->parse(\"\n[% x = 1 y = 2 %]\n") };
    is $@, qq{Syntax error near ` y = 2`\n at [% x (? 2)\n};
    
    ok !eval{ $p->parse(\"\n[% x=1 y=2 %]\n") };
    is $@, qq{Syntax error near ` y=2`\n at [% x=1 (? 2)\n};
    
    ok !eval{ $p->parse(\"\n[% join('#', \@{sort keys \%{foo}}) %]\n") };
    is $@, qq/Missing right bracket '}' near `join('#', \@{sort`\n at [% join('#', (? 2)\n/;
    
    {
        no warnings 'redefine';
        local *MyProject::Template::Parser::_compile = sub{ $_[2]->{sub} = '!' };
        my $p = MyProject->Template->Parser->new;
        $p->{pragma} = '';
        $p->compile("\nxyz");
        $p->error, qr/^syntax error at eval `!`/;
    }
}

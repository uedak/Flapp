use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib "$FindBin::Bin/tlib";
use lib Cwd::abs_path("$FindBin::Bin/../../lib");
use strict;
use warnings;


use Flapp;
my $FILE = __FILE__;

{
    my $baz = 'baz';
    
    sub foo {
        &bar()
    }
    
    sub bar {
        &baz()
    }
    
    sub baz {
        warn $baz
    }
    
    Flapp->begin;
    
    tie *STDERR, 'Capture';
    &foo();
    
    is ${tied *STDERR}, <<END;
baz
 at __WARN__($FILE 25)
 at main::baz($FILE 21)
 at main::bar($FILE 17)
 at main::foo($FILE 31)
END
    
    $baz = "baz\n";
    ${tied *STDERR} = '';
    &foo();
    
    is ${tied *STDERR}, <<END;
baz
 at __WARN__($FILE 25)
 at main::baz($FILE 21)
 at main::bar($FILE 17)
 at main::foo($FILE 43)
END
    untie *STDERR;
    Flapp->end;
}

{
    my($hoge, $fuga);
    my $piyo = 'piyo';
    
    sub hoge {
        eval{
            &fuga()
        };
        die $hoge = $@
    }
    
    sub fuga {
        eval{
            &piyo()
        };
        die $fuga = $@
    }
    
    sub piyo {
        die $piyo;
    }
    
    Flapp->begin;
    eval{
        &hoge()
    };
    Flapp->end;
    
    is $fuga, <<END;
piyo
 at __DIE__($FILE 75)
 at main::piyo($FILE 69)
 at (eval)($FILE 68)
END
    
    is $hoge, <<END;
${fuga} at __DIE__($FILE 71)
 at main::fuga($FILE 62)
 at (eval)($FILE 61)
END
    
    is $@, <<END;
${hoge} at __DIE__($FILE 64)
 at main::hoge($FILE 80)
 at (eval)($FILE 79)
END
    
    $piyo = "piyo\n";
    Flapp->begin;
    eval{
        &hoge()
    };
    Flapp->end;
    
    is $fuga, <<END;
piyo
 at __DIE__($FILE 75)
 at main::piyo($FILE 69)
 at (eval)($FILE 68)
END
    
    is $hoge, <<END;
${fuga} at __DIE__($FILE 71)
 at main::fuga($FILE 62)
 at (eval)($FILE 61)
END
    
    is $@, <<END;
${hoge} at __DIE__($FILE 64)
 at main::hoge($FILE 106)
 at (eval)($FILE 105)
END
}

package Capture;
sub TIEHANDLE { bless \(my $buf = ''), shift }
sub PRINT { ${+shift} .= shift }

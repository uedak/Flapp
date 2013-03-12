use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use strict;
use warnings;
use Encode;

use MyProject;
my $proj = 'MyProject';
is my $u = $proj->Util, 'MyProject::Util';
$proj->begin;

{
    my @chr = map{ chr $_ } 0 .. 127;
    my %exp = map{ $_ => "'$_'" } @chr;
    $exp{chr $_} = sprintf('"\x%02X"', $_) for (0 .. 31, 127);
    $exp{$_} = $_ for 0 .. 9;
    $exp{"\t"} = '"\t"';
    $exp{"\n"} = '"\n"';
    $exp{"\r"} = '"\r"';
    $exp{"'"}  = q{"'"};
    $exp{'\\'} = '"\\\\"';
    
    is $u->dump($_), $exp{$_} for @chr;
    
    is $u->dump(undef), 'undef';
    is $u->dump(''), "''";
}

{
    my $v = ['あ', "あゔ\xE0\xE0"];
    my $d;
    is $d = $u->dump($v), q{["あ","あ\xE3\x82\x94\xE0\xE0"]};
    ok !utf8::is_utf8($d);
    Encode::_utf8_on($_) for @$v;
    is $d = $u->dump($v), q{["あ","あ\xE3\x82\x94\xE0\xE0"]};
    ok !utf8::is_utf8($d);
}

{
    local $Flapp::UTF8 = 1;
    my $v = ['あ', "あゔ\xE0\xE0"];
    my $d;
    Encode::_utf8_on(my $exp = q{["\xE3\x81\x82","\xE3\x81\x82\xE3\x82\x94\xE0\xE0"]});
    is $d = $u->dump($v), $exp;
    ok utf8::is_utf8($d);
    
    Encode::_utf8_on($_) for @$v;
    Encode::_utf8_on($exp = q{["あ","あ\x{3094}\xE0\xE0"]});
    is $d = $u->dump($v), $exp;
    ok utf8::is_utf8($d);
}

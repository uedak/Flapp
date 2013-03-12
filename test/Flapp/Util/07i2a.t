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
    my @w = (0 .. 9, 'A' .. 'Z', 'a' .. 'z');
    my $i = 0;
    is $u->i2a($i++), $_ for @w;
    is $u->i2a($i++), "1$_" for @w;
    
    is $u->i2a(62 * 62 - 1), 'zz';
    is $u->i2a(62 * 62), '100';
    
    is $u->i2a(62 * 62 * 62 - 1), 'zzz';
    is $u->i2a(62 * 62 * 62), '1000';
}

{
    my @w = (0 .. 9, 'A' .. 'Z', 'a' .. 'z');
    my $i = 0;
    is $u->a2i($_), $i++ for @w;
    is $u->a2i("1$_"), $i++ for @w;
    
    is $u->a2i('zz'), 62 * 62 - 1;
    is $u->a2i('100'), 62 * 62;
    
    is $u->a2i('zzz'), 62 * 62 * 62 - 1;
    is $u->a2i('1000'), 62 * 62 * 62;
}

{
    my @w = ('A' .. 'Z');
    my $i = 0;
    is $u->i2a($i++, \@w), $_ for @w;
    is $u->i2a($i++, \@w), "B$_" for @w;
    
    is $u->i2a(26 * 26 - 1, \@w), 'ZZ';
    is $u->i2a(26 * 26, \@w), 'BAA';
    
    is $u->i2a(26 * 26 * 26 - 1, \@w), 'ZZZ';
    is $u->i2a(26 * 26 * 26, \@w), 'BAAA';
}

{
    my @w = ('A' .. 'Z');
    my $i = 0;
    is $u->a2i($_, \@w), $i++ for @w;
    is $u->a2i("B$_", \@w), $i++ for @w;
    
    is $u->a2i('ZZ', \@w), 26 * 26 - 1;
    is $u->a2i('BAA', \@w), 26 * 26;
    
    is $u->a2i('ZZZ', \@w), 26 * 26 * 26 - 1;
    is $u->a2i('BAAA', \@w), 26 * 26 * 26;
}

{
    is $u->a2i('zzz'), 62 ** 3 - 1;
    'zzz' =~ /(.+)/;
    is $u->a2i($1), 62 ** 3 - 1;
    
    is $u->i2a(999999999999999), '4ZxYle1gV';
    is $u->a2i('4ZxYle1gV'), 999999999999999;
    
    eval{ $u->i2a(999999999999999 + 1) };
    like "$@", qr/^Too large/;
    
    eval{ $u->a2i('4ZxYle1gW') };
    like "$@", qr/^Too large/;
}

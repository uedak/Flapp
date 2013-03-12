use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use strict;
use warnings;

use MyProject;
my $proj = 'MyProject';
is $proj->Util, 'MyProject::Util';
$proj->begin;

use Encode;
Encode::from_to(my $sjis = '川', 'utf8', 'shift-jis');

{
    is $proj->Util->tr('ｳﾞｶｶﾞｶﾟﾊﾞﾊﾟ', 'kana_h2z'), 'ヴカガカ゜バパ';
    is $proj->Util->tr('ヴカガカ゜バパ', 'kana_z2h'), 'ｳﾞｶｶﾞｶﾟﾊﾞﾊﾟ';
    
    my $z = '０１２３';
    my $h = '0123';
    
    my $s = $z;
    is $proj->Util->tr(\$s, 'asc_z2h'), $h;
    is $s, $h;
    
    $s = $h;
    is $proj->Util->tr(\$s, 'asc_h2z'), $z;
    is $s, $z;
    
    eval{ $proj->Util->tr(\($s = $sjis), 'kana_z2h') };
    like $@, qr/^Malformed UTF-8 character/;
    is $s, $sjis;
    
    is $proj->Util->tr("カガカ゜${s}バパ", 'kana_z2h', 1), "ｶｶﾞｶﾟ${s}ﾊﾞﾊﾟ";
}

{
    local $proj->Util->_global_->{tr} = {};
    local $Flapp::UTF8 = 1;
    use utf8;
    Encode::_utf8_on($sjis);
    
    is $proj->Util->tr('ｳﾞｶｶﾞｶﾟﾊﾞﾊﾟ', 'kana_h2z'), 'ヴカガカ゜バパ';
    is $proj->Util->tr('ヴカガカ゜バパ', 'kana_z2h'), 'ｳﾞｶｶﾞｶﾟﾊﾞﾊﾟ';
    
    my $z = '０１２３';
    my $h = '0123';
    
    my $s = $z;
    is $proj->Util->tr(\$s, 'asc_z2h'), $h;
    is $s, $h;
    
    $s = $h;
    is $proj->Util->tr(\$s, 'asc_h2z'), $z;
    is $s, $z;
    
    eval{ $proj->Util->tr(\($s = $sjis), 'kana_z2h') };
    like $@, qr/^Malformed UTF-8 character/;
    is $s, $sjis;
    
    is $proj->Util->tr("カガカ゜${s}バパ", 'kana_z2h', 1), "ｶｶﾞｶﾟ${s}ﾊﾞﾊﾟ";
}

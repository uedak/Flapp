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

{
    my $x = 'ABC';
    is $proj->Util->uri_unescape($x), $x;
    $x = 'あいうえお';
    my $y = '%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A';
    is $proj->Util->uri_escape($x), $y;
    is $proj->Util->uri_unescape($y), $x;
}

{
    local $Flapp::UTF8 = 1;
    use utf8;
    my $x = 'ABC';
    is $proj->Util->uri_unescape($x), $x;
    $x = 'あいうえお';
    my $y = '%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A';
    is $proj->Util->uri_escape($x), $y;
    is $proj->Util->uri_unescape($y), $x;
    
    ok utf8::is_utf8($proj->Util->uri_unescape('%E3%81%82'));
    ok !utf8::is_utf8($proj->Util->uri_unescape('%82%A0'));
}

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
    my @chr;
    ok $proj->Util->each_chr_do('ｶｶﾞｶﾟﾊﾞﾊﾟ', sub{ $_[0] =~ /(.+)/ && push(@chr, $1) });
    is_deeply \@chr, [qw/ｶ ｶ ﾞ ｶ ﾟ ﾊ ﾞ ﾊ ﾟ/];
    is utf8::is_utf8($chr[0]), '';
    
    undef @chr;
    ok $proj->Util->each_chr_do('ｶｶﾞｶﾟﾊﾞﾊﾟ', sub{ $_[0] =~ /(.+)/ && push(@chr, $1) }, {dh => 1});
    is_deeply \@chr, [qw/ｶ ｶﾞ ｶ ﾟ ﾊﾞ ﾊﾟ/];
    is utf8::is_utf8($chr[0]), '';
    
    undef @chr;
    ok !$proj->Util->each_chr_do('ｶｶﾞｶﾟﾊﾞﾊﾟ', sub{ !push(@chr, shift) }, {stop_if_false => 1});
    is_deeply \@chr, [qw/ｶ/];
    is utf8::is_utf8($chr[0]), '';
    
    eval{ $proj->Util->each_chr_do("あ\xFFあ", sub{}) };
    like $@, qr/^Malformed UTF-8 character "\\xff"/;
    
    undef @chr;
    ok $proj->Util->each_chr_do("あ\xFFあ", sub{ push(@chr, shift) }, {force => 1});
    is_deeply \@chr, ['あ', "\xFF", 'あ'];
    is utf8::is_utf8($chr[0]), '';
}

{
    local $Flapp::UTF8 = 1;
    use utf8;
    
    my @chr;
    $proj->Util->each_chr_do('ｶｶﾞｶﾟﾊﾞﾊﾟ', sub{ $_[0] =~ /(.+)/ && push(@chr, $1) });
    is_deeply \@chr, [qw/ｶ ｶ ﾞ ｶ ﾟ ﾊ ﾞ ﾊ ﾟ/];
    is utf8::is_utf8($chr[0]), 1;
    
    undef @chr;
    $proj->Util->each_chr_do('ｶｶﾞｶﾟﾊﾞﾊﾟ', sub{ $_[0] =~ /(.+)/ && push(@chr, $1) }, {dh => 1});
    is_deeply \@chr, [qw/ｶ ｶﾞ ｶ ﾟ ﾊﾞ ﾊﾟ/];
    is utf8::is_utf8($chr[0]), 1;
    
    undef @chr;
    ok !$proj->Util->each_chr_do('ｶｶﾞｶﾟﾊﾞﾊﾟ', sub{ !push(@chr, shift) }, {stop_if_false => 1});
    is_deeply \@chr, [qw/ｶ/];
    is utf8::is_utf8($chr[0]), 1;
}

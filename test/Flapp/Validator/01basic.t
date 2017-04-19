use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use strict;
use warnings;

use MyProject;
my $proj = 'MyProject';
is my $v = $proj->Validator, 'MyProject::Validator';

my @e;

{
    is int(@e = $proj->validate('あ', qw/chr(int)/)), 1;
    is_deeply \@e, [[101, '「あ」']];
    
    ok !$proj->validate(123, qw/chr(int)/);
    
    is int(@e = $proj->validate("abc\ndef", qw/chr(alpha)/)), 1;
    is_deeply \@e, [[101, '改行']];
    
    ok !$proj->validate("abc\ndef", qw/chr(alpha+LF)/);
    
    is int(@e = $proj->validate("①\t②", qw/chr(alpha)/)), 1;
    is_deeply \@e, [[101, '「①」, タブ文字, 「②」']];
    
    is int(@e = $proj->validate("①\t②③④", qw/chr(alpha)/)), 1;
    is_deeply \@e, [[101, '「①」, タブ文字, 「②」, ...']];

    my @v;
    ok  !$proj->validate('1',  @v = qw/chr(int)/);
    ok !!$proj->validate('a',  @v);
    ok !!$proj->validate('1a', @v);

    ok  !$proj->validate('a',  @v = qw/chr(-int)/);
    ok !!$proj->validate('1',  @v);
    ok !!$proj->validate('1a', @v);

    ok  !$proj->validate('1',  @v = qw/chr(alpha+int)/);
    ok  !$proj->validate('a',  @v);
    ok !!$proj->validate(' ',  @v);
    ok  !$proj->validate('1a', @v);
    ok !!$proj->validate('1 ', @v);
    ok !!$proj->validate('a ', @v);
    ok !!$proj->validate('1a ', @v);

    ok  !$proj->validate('a',  @v = qw/chr(url+int)/);
    ok  !$proj->validate('1',  @v);
    ok !!$proj->validate(' ',  @v);
    ok  !$proj->validate('1a', @v);
    ok !!$proj->validate('1 ', @v);
    ok !!$proj->validate('a ', @v);
    ok !!$proj->validate('1a ', @v);

    ok  !$proj->validate('a',  @v = qw/chr(url-int)/);
    ok !!$proj->validate('1',  @v);
    ok !!$proj->validate(' ',  @v);
    ok !!$proj->validate('1a', @v);
    ok !!$proj->validate('1 ', @v);
    ok !!$proj->validate('a ', @v);
    ok !!$proj->validate('1a ', @v);

    ok !!$proj->validate('a',  @v = qw/chr(-url+int)/);
    ok  !$proj->validate('1',  @v);
    ok !!$proj->validate(' ',  @v);
    ok !!$proj->validate('1a', @v);
    ok !!$proj->validate('1 ', @v);
    ok !!$proj->validate('a ', @v);
    ok !!$proj->validate('1a ', @v);

    ok !!$proj->validate('a',  @v = qw/chr(-url-int)/);
    ok !!$proj->validate('1',  @v);
    ok  !$proj->validate(' ',  @v);
    ok !!$proj->validate('1a', @v);
    ok !!$proj->validate('1 ', @v);
    ok !!$proj->validate('a ', @v);
    ok !!$proj->validate('1a ', @v);

    ok  !$proj->validate('a',  @v = qw/chr(int+url)/);
    ok  !$proj->validate('1',  @v);
    ok !!$proj->validate(' ',  @v);
    ok  !$proj->validate('1a', @v);
    ok !!$proj->validate('1 ', @v);
    ok !!$proj->validate('a ', @v);
    ok !!$proj->validate('1a ', @v);

    ok !!$proj->validate('a',  @v = qw/chr(int-url)/);
    ok !!$proj->validate('1',  @v);
    ok !!$proj->validate(' ',  @v);
    ok !!$proj->validate('1a', @v);
    ok !!$proj->validate('1 ', @v);
    ok !!$proj->validate('a ', @v);
    ok !!$proj->validate('1a ', @v);

    ok  !$proj->validate('a',  @v = qw/chr(-int+url)/);
    ok  !$proj->validate('1',  @v);
    ok !!$proj->validate(' ',  @v);
    ok  !$proj->validate('1a', @v);
    ok !!$proj->validate('1 ', @v);
    ok !!$proj->validate('a ', @v);
    ok !!$proj->validate('1a ', @v);

    ok !!$proj->validate('a',  @v = qw/chr(-int-url)/);
    ok !!$proj->validate('1',  @v);
    ok  !$proj->validate(' ',  @v);
    ok !!$proj->validate('1a', @v);
    ok !!$proj->validate('1 ', @v);
    ok !!$proj->validate('a ', @v);
    ok !!$proj->validate('1a ', @v);
}

{
    is int(@e = $proj->validate('3/17', qw/date/)), 1;
    is $e[0], 102;
    
    ok !$proj->validate('2010-03-17', qw/date/);
    
    is int(@e = $proj->validate('2010-02-31', qw/date/)), 1;
    is $e[0], 102;
}

{
    is int(@e = $proj->validate('test@.test.co.jp', qw/eml/)), 1;
    is $e[0], 103;
    
    ok !$proj->validate('test@test.co.jp', qw/eml/);
    ok !$proj->validate('test+@test.co.jp', qw/eml/);
    ok !$proj->validate('test+.@test.co.jp', qw/eml/);
}

{
    foreach my $src ({qw/a A b B c C/}, [[a => 'A'], [b => 'B'], [c => 'C']]){
        ok !$proj->validate('a', [enum => $src]);
        ok !$proj->validate([qw/a c/], [enum => $src]);
        
        is int(@e = $proj->validate([qw/x y z/], [enum => $src])), 1;
        is_deeply \@e, [[104, 'x, y, z']];
        
        is int(@e = $proj->validate([qw/A B C D/], [enum => $src])), 1;
        is_deeply \@e, [[104, 'A, B, C, ...']];
    }
}

{
    ok !$proj->validate('235959', qw/hms/);
    is int(@e = $proj->validate('235960', qw/hms/)), 1;
    is $e[0], 105;
}

{
    is int(@e = $proj->validate('abc', qw/int/)), 1;
    is $e[0], 106;
    
    ok !$proj->validate(100, qw/int/);
    ok !$proj->validate(-100, qw/int/);
}

{
    ok !$proj->validate('x', qw/nn/);
    is int(@e = $proj->validate('', qw/nn/)), 1;
    is $e[0], 107;
    
    is int(@e = $proj->validate(' ', qw/nn/)), 1;
    is $e[0], 107;
    
    is int(@e = $proj->validate("\t\r\n 　", qw/nn/)), 1;
    is $e[0], 107;
}

{
    ok !$proj->validate(10, qw/range(9<=11)/);
    ok !$proj->validate(10, qw/range(10<=10)/);
    ok !$proj->validate(10, qw/range(10<=)/);
    ok !$proj->validate(10, qw/range(<=10)/);
    
    is int(@e = $proj->validate('x', qw/range(9<=11)/)), 1;
    is $e[0], 108;
    
    ok !$proj->validate(-3.5, qw/range(-3.5<=)/);
    is int(@e = $proj->validate(-3.6, qw/range(-3.5<=)/)), 1;
    is_deeply \@e, [[109, -3.5]];
    
    ok !$proj->validate(3.50, qw/range(<=3.5)/);
    is int(@e = $proj->validate(3.51, qw/range(<=3.5)/)), 1;
    is_deeply \@e, [[110, 3.5]];
}

{
    ok !$proj->validate('x', qw/sel/);
    ok !$proj->validate([1], qw/sel/);
    
    is int(@e = $proj->validate('', qw/sel/)), 1;
    is $e[0], 111;
    
    is int(@e = $proj->validate(undef, qw/sel/)), 1;
    is $e[0], 111;
    
    is int(@e = $proj->validate([], qw/sel/)), 1;
    is $e[0], 111;
}

{
    ok !$proj->validate('あA', qw/size(2)/);
    is int(@e = $proj->validate('abcd', qw/size(2)/)), 1;
    is_deeply \@e, [[112, 2]];
    
    ok !$proj->validate('あAB', qw/size(3<=)/);
    is int(@e = $proj->validate('あA', qw/size(3<=)/)), 1;
    is_deeply \@e, [[113, 3]];
    
    ok !$proj->validate('あAB', qw/size(<=3)/);
    is int(@e = $proj->validate('あABC', qw/size(<=3)/)), 1;
    is_deeply \@e, [[114, 3]];
    
    ok !$proj->validate('', qw/size(3<=)/);
    ok !$proj->validate('', qw/size(<=3)/);
    ok !$proj->validate('', qw/size(3<=3)/);
    ok !$proj->validate('', qw/size(3)/);
}

{
    ok !$proj->validate('01-2345-6789', qw/tel/);
    is int(@e =$proj->validate('01-2345-67890', qw/tel/)), 1;
    is $e[0], 115;
}

{
    ok !$proj->validate("2010-03-17T23:59:59", qw/time/);
    is int(@e = $proj->validate('2010-03-17T24:00:00', qw/time/)), 1;
    is $e[0], 116;
    
    is int(@e = $proj->validate('2010-03-17T23:60:59', qw/time/)), 1;
    is $e[0], 116;
    
    is int(@e = $proj->validate('2010-03-17T23:59:60', qw/time/)), 1;
    is $e[0], 116;
}

{
    ok !$proj->validate('http://foo.bar/baz', qw/url/);
    ok !$proj->validate('https://foo.bar/baz?x=1&y=2#1', qw/url/);
    is int(@e = $proj->validate('ftp://foo.bar/baz', qw/url/)), 1;
    is $e[0], 117;
    
    ok $proj->validate('http://??', qw/url/);
    ok $proj->validate('http://??/', qw/url/);
    ok $proj->validate('http://&/', qw/url/);
    ok $proj->validate('http://#?/', qw/url/);
    ok $proj->validate('mailto:test@test.com', qw/url/);
    
    is int(@e = $proj->validate("http://foo.bar/baz\n", qw/url/)), 1;
    is_deeply \@e, [[101, '改行']];
    
    is int(@e = $proj->validate("http://foo.bar/<baz>", qw/url/)), 1;
    is_deeply \@e, [[101, '「<」, 「>」']];
}

{
    ok !$proj->validate('20100228', qw/ymd/);
    ok !$proj->validate('', qw/ymd/);
    is int(@e = $proj->validate('20100229', qw/ymd/)), 1;
    is $e[0], 102;
    
    is int(@e = $proj->validate('201002281', qw/ymd/)), 1;
    is $e[0], 102;
    
    is int(@e = $proj->validate('2010022', qw/ymd/)), 1;
    is $e[0], 102;
    
    is int(@e = $proj->validate('2010-910', qw/ymd/)), 1;
    is $e[0], 102;
    
    is int(@e = $proj->validate('20101301', qw/ymd/)), 1;
    is $e[0], 102;
    
    is int(@e = $proj->validate('20100001', qw/ymd/)), 1;
    is $e[0], 102;
    
    is int(@e = $proj->validate('あいうえお', qw/ymd/)), 1;
    is $e[0], 102;
    
    ok !$proj->validate('20101231', qw/ymd/);
    is int(@e = $proj->validate('20101301', qw/ymd/)), 1;
    is $e[0], 102;
}

{
    ok !$proj->validate('123-4567', qw/zip/);
    is int(@e = $proj->validate('123-456', qw/zip/)), 1;
    is $e[0], 118;
}

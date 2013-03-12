use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
use strict;
use warnings;

my $dir = Cwd::abs_path("$FindBin::Bin/03cache");
use MyProject;
my $P = MyProject->Template->Parser;
ok my $p = $P->new({CACHE_SIZE => 5});
MyProject->begin;

{
    ok my $ft1 = $p->open([$dir, '/1.ft']);
    ok my $ft2 = $p->open([$dir, '/2.ft']);
    ok my $ft3 = $p->open([$dir, '/3.ft']);
    ok my $ft4 = $p->open([$dir, '/4.ft']);
    ok my $ft5 = $p->open([$dir, '/5.ft']);
    
    is int(keys %{$p->{cache}}), 5;
    my $k1 = (sort keys %{$p->{cache}})[0];
    is $p->{cache}{$k1}[0], 1;
    ok my $ft = $p->open([$dir, '/1.ft']);
    is "$ft1->{doc}[0]{body}", "$ft->{doc}[0]{body}";
    is $p->{cache}{$k1}[0], 2;
    
    tie *STDERR, 'Capture';
    ok my $ft6 = $p->open([$dir, '/6.ft']);
    is int(keys %{$p->{cache}}), 2;
    is $p->{cache}{$k1}[0], 0;
    ok $ft = $p->open([$dir, '/1.ft']);
    is "$ft1->{doc}[0]{body}", "$ft->{doc}[0]{body}";
    is $p->{cache}{$k1}[0], 1;
    
    like ${tied *STDERR}, qr/^Cache reduced from 5 to 1\n/;
    untie *STDERR;
}

package Capture;
sub TIEHANDLE { bless \(my $buf = ''), shift }
sub PRINT { ${+shift} .= shift }

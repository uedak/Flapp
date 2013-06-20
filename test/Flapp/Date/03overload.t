use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use strict;
use warnings;
use Flapp;

ok my $d = Flapp->Date->new('2013-06-19');
ok my $e = $d->epoch;

ok $d gt '2013-06-18';
ok $d ge '2013-06-18';
ok $d ge '2013-06-19';
ok $d lt '2013-06-20';
ok $d le '2013-06-20';
ok $d le '2013-06-19';
ok $d >  $e - 1;
ok $d >= $e - 1;
ok $d >= $e;
ok $d <  $e + 1;
ok $d <= $e + 1;
ok $d <= $e;

ok '2013-06-18' lt $d;
ok '2013-06-18' le $d;
ok '2013-06-19' le $d;
ok '2013-06-20' gt $d;
ok '2013-06-20' ge $d;
ok '2013-06-19' ge $d;
ok $e - 1 <  $d;
ok $e - 1 <= $d;
ok $e     <= $d;
ok $e + 1 >  $d;
ok $e + 1 >= $d;
ok $e     >= $d;



ok my $t = Flapp->Time->new('2013-06-19T12:00:00+09:00');
ok $e = $t->epoch;

ok $t gt '2013-06-19T11:59:59+09:00';
ok $t ge '2013-06-19T11:59:59+09:00';
ok $t ge '2013-06-19T12:00:00+09:00';
ok $t lt '2013-06-19T12:00:01+09:00';
ok $t le '2013-06-19T12:00:01+09:00';
ok $t le '2013-06-19T12:00:00+09:00';
ok $t >  $e - 1;
ok $t >= $e - 1;
ok $t >= $e;
ok $t <  $e + 1;
ok $t <= $e + 1;
ok $t <= $e;

ok '2013-06-19T11:59:59+09:00' lt $t;
ok '2013-06-19T11:59:59+09:00' le $t;
ok '2013-06-19T12:00:00+09:00' le $t;
ok '2013-06-19T12:00:01+09:00' gt $t;
ok '2013-06-19T12:00:01+09:00' ge $t;
ok '2013-06-19T12:00:00+09:00' ge $t;
ok $e - 1 <  $t;
ok $e - 1 <= $t;
ok $e     <= $t;
ok $e + 1 >  $t;
ok $e + 1 >= $t;
ok $e     >= $t;

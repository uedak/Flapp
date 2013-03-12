use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use strict;
use warnings;
use Flapp;

ok my $dt = Flapp->Date->new('2011-02-08');

is $dt->strftime('%%'), '%';
is $dt->strftime('%a'), 'Tue';
is $dt->strftime('%A'), 'Tuesday';
is $dt->strftime('%b'), 'Feb';
is $dt->strftime('%B'), 'February';
is $dt->strftime('%C'), '20';
is $dt->strftime('%d'), '08';
is $dt->strftime('%e'), ' 8';
is $dt->strftime('%F'), '2011-02-08';
is $dt->strftime('%h'), 'Feb';
is $dt->strftime('%m'), '02';
is $dt->strftime('%n'), "\n";
is $dt->strftime('%s'), '1297090800';
is $dt->strftime('%t'), "\t";
is $dt->strftime('%u'), '2';
is $dt->strftime('%w'), '2';
is $dt->strftime('%y'), '11';
is $dt->strftime('%Y'), '2011';

is $dt->day(6)->strftime('%u/%w'), '7/0';

eval{ $dt->strftime('%x') };
like $@, qr/^Unimplemented format: "%x"/;

is $dt->strftime('%{year}/%{mon}/%{day}'), '2011/2/6';

eval{ $dt->strftime('%{foo}') };
like $@, qr/^Can't locate object method "foo"/;

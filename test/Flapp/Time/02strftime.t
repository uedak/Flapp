use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use strict;
use warnings;
use Flapp;

ok my $dt = Flapp->Time->parse(2011, 2, 8, 7, 9, 3, '+09:00');

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
is $dt->strftime('%H'), '07';
is $dt->strftime('%I'), '07';
is $dt->strftime('%k'), ' 7';
is $dt->strftime('%l'), ' 7';
is $dt->strftime('%m'), '02';
is $dt->strftime('%M'), '09';
is $dt->strftime('%n'), "\n";
is $dt->strftime('%p'), 'AM';
is $dt->strftime('%P'), 'am';
is $dt->strftime('%r'), '07:09:03 AM';
is $dt->strftime('%R'), '07:09';
is $dt->strftime('%s'), '1297116543';
is $dt->strftime('%S'), '03';
is $dt->strftime('%t'), "\t";
is $dt->strftime('%T'), '07:09:03';
is $dt->strftime('%u'), '2';
is $dt->strftime('%w'), '2';
is $dt->strftime('%y'), '11';
is $dt->strftime('%Y'), '2011';
is $dt->strftime('%z'), '+0900';

$dt += -3 + 60 * -9 + 60 * 60 * 5;
is $dt, '2011-02-08T12:00:00+09:00';
is $dt->strftime('%p %P %r'), 'PM pm 12:00:00 PM';
$dt--;
is $dt->strftime('%p %P %r'), 'AM am 11:59:59 AM';

is $dt->hour(0)->strftime('%I/%l'), '12/12';
is $dt->hour(1)->strftime('%I/%l'), '01/ 1';
is $dt->hour(12)->strftime('%I/%l'), '12/12';
is $dt->hour(13)->strftime('%I/%l'), '01/ 1';
is $dt->hour(23)->strftime('%I/%l'), '11/11';

is $dt->day(6)->strftime('%u/%w'), '7/0';

1;

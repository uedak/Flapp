use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib "$FindBin::Bin/tlib";
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use strict;
use warnings;
use Flapp;
use Flapp::Date;

{ #accessor
    is my $dt = Flapp->Time->new('0999-02-03T04:05:06+09:00'), '0999-02-03T04:05:06+09:00';
    is $dt->year, 999;
    is $dt->month, 2;
    is $dt->mon, 2;
    is $dt->day, 3;
    is $dt->Y, '0999';
    is $dt->m, '02';
    is $dt->d, '03';
    
    is $dt->hour, 4;
    is $dt->H, '04';
    is $dt->minute, 5;
    is $dt->min, 5;
    is $dt->M, '05';
    is $dt->second, 6;
    is $dt->sec, 6;
    is $dt->S, '06';
    
    eval{ Flapp->Time->new('x')->year };
    like $@, qr/^Invalid Time: "x" at .*?01basic\.t line \d+/;
    
    eval{ Flapp->Date->new('2001-01-01')->hour };
    like $@, qr/^Can't locate object method "hour" via package "Flapp::Date"/;
}

{ #add
    my $tm = Flapp->Time->parse('2011-02-08+9');
    is $tm, '2011-02-08T00:00:00+09:00';
    is $tm->add(1), '2011-02-08T00:00:01+09:00';
    is $tm->add(+60), '2011-02-08T00:01:01+09:00';
    $tm += 60 * 60;
    is $tm, '2011-02-08T01:01:01+09:00';
    is $tm->add(-1), '2011-02-08T01:01:00+09:00';
    
    eval{ $tm->add(0.1) };
    like $@, qr/^Argument "0.1" isn't integer/;
    
    $tm = Flapp->Time->new('2011-02-08T00:00:00+09:00');
    my $tm2 = Flapp->Time->new('2011-02-11T00:00:00+09:00');
    eval{ my $t = $tm + $tm2 };
    like $@, qr/^Argument "2011-02-11T00:00:00\+09:00" isn't integer at .*01basic\.t line \d+/;
    
    eval{ my $t = $tm2 + $tm };
    like $@, qr/^Argument "2011-02-08T00:00:00\+09:00" isn't integer at .*01basic\.t line \d+/;
    
    is $tm2 - $tm, 60 * 60 * 24 * 3;
    is $tm - $tm2, -(60 * 60 * 24 * 3);
    
    my $dt = Flapp->Date->new('2011-02-11');
    is $dt - $tm, 60 * 60 * 24 * 3;
    is $tm - $dt, -(60 * 60 * 24 * 3);
}

{ #epoch
    my $dt = Flapp->Time->parse('1901-12-13T20:45:53+00:00');
    is $dt->epoch, -2147483647;
    
    $dt--;
    is $dt->epoch, -2147483648;
    is $dt, '1901-12-13T20:45:52+00:00';
    
    $dt--;
    is $dt->epoch, -2147483649;
    is $dt, '1901-12-13T20:45:51+00:00';
    
    $dt = Flapp->Time->parse('10000101+0');
    is $dt->epoch, -30610224000;
    is $dt, '1000-01-01T00:00:00+00:00';
    
    $dt--;
    is $dt->epoch, -30610224001;
    is $dt, '0999-12-31T23:59:59+00:00';
    
    $dt--;
    is $dt->epoch, -30610224002;
    is $dt, '0999-12-31T23:59:58+00:00';
    
    $dt->epoch(-62167219200);
    is $dt->epoch, -62167219200;
    is $dt, '0000-01-01T00:00:00+00:00';
    
    $dt = Flapp->Time->parse('2038-01-19T03:14:06+00:00');
    is $dt->epoch, 2147483646;
    
    $dt++;
    is $dt->epoch, 2147483647;
    is $dt, '2038-01-19T03:14:07+00:00';
    
    $dt++;
    is $dt->epoch, 2147483648;
    is $dt, '2038-01-19T03:14:08+00:00';
    
    $dt->epoch(253402300799);
    is $dt->epoch, 253402300799;
    is $dt, '9999-12-31T23:59:59+00:00';
    
    $dt = Flapp->Time->parse('1799-01-02+0');
    is $dt->epoch, -5396112000;
    $dt -= 60 * 60 * 24;
    is $dt->epoch, -5396198400;
    is $dt, '1799-01-01T00:00:00+00:00';
    
    $dt = Flapp->Time->parse('1796-03-01+0');
    is $dt->epoch, -5485708800;
    $dt -= 60 * 60 * 24;
    is $dt->epoch, -5485795200;
    is $dt, '1796-02-29T00:00:00+00:00';
    
    $dt = Flapp->Time->parse('1796-01-03+0');
    is $dt->epoch, -5490720000;
    $dt -= 60 * 60 * 24;
    is $dt->epoch, -5490806400;
    is $dt, '1796-01-02T00:00:00+00:00';
}

{ #now
    like (Flapp->Time->now, qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d[\+\-]\d{2}:\d{2}\z/);
}

{ #parse
    local $Flapp::Date::LOCAL_TIME_ZONE_OFFSET = 0;
    is(Flapp->Time->parse(''), undef);
    is(Flapp->Time->parse(2011), undef);
    is(Flapp->Time->parse(201102), undef);
    is(Flapp->Time->parse('2011/2/3'), '2011-02-03T00:00:00+00:00');
    is(Flapp->Time->parse('20110203'), '2011-02-03T00:00:00+00:00');
    is(Flapp->Time->parse('2011/2/3 4:5:6+9'), '2011-02-03T04:05:06+09:00');
    is(Flapp->Time->parse('2011-2-3T04:05:06Z'), '2011-02-03T04:05:06+00:00');
    is(Flapp->Time->parse('20110203040506'), '2011-02-03T04:05:06+00:00');
    is(Flapp->Time->parse(2011, 2, 3, 4, 5, 6), '2011-02-03T04:05:06+00:00');
}

{ #time_zone
    my $dt = Flapp->Time->new('2011-03-21T12:23:20+09:00');
    is $dt->tz, '+09:00';
    is $dt->epoch, 1300677800;
    
    $dt->tz('+08:30');
    is $dt->tz, '+08:30';
    is $dt->epoch, 1300677800;
    is $dt, '2011-03-21T11:53:20+08:30';
}

{ #include
    use X;
    my $x = 'X';
    my $t1 = $x->now;
    my $t2 = $t1->clone->add(+10);
    is $t2 - $t1, 10;
}

{
    my $now = Flapp->now;
    ok $now->can('TO_JSON');
}

{ #to_date
    no warnings 'once';
    local *Flapp::Time::project = sub{ 'Flapp' };
    
    is (Flapp->Time->new('2012-06-04T19:55:00+00:00')->to_date, '2012-06-04');
}

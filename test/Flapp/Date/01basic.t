use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use strict;
use warnings;
use Flapp;
use Flapp::Date;

{ #accessor
    is my $dt = Flapp->Date->new('0999-02-03'), '0999-02-03';
    is $dt->year, 999;
    is $dt->month, 2;
    is $dt->mon, 2;
    is $dt->day, 3;
    is $dt->Y, '0999';
    is $dt->m, '02';
    is $dt->d, '03';
    
    eval{ Flapp->Date->new('x')->year };
    like $@, qr/^Invalid Date: "x" at .*?01basic\.t line \d+/;
}

{ #add
    is my $dt = Flapp->Date->new('2011-02-28'), '2011-02-28';
    is $dt + 1, '2011-03-01';
    is 1 + $dt, '2011-03-01';
    is $dt, '2011-02-28';
    
    is $dt - 1, '2011-02-27';
    is -1 + $dt, '2011-02-27';
    is $dt, '2011-02-28';
    
    is $dt->add(1), '2011-03-01';
    is $dt, '2011-03-01';
    
    is $dt->add(-1), '2011-02-28';
    is $dt, '2011-02-28';
    
    is ++$dt, '2011-03-01';
    is --$dt, '2011-02-28';
    
    eval{ $dt->add(0.1) };
    like $@, qr/^Argument "0.1" isn't integer at .*01basic\.t line \d+/;
    
    eval{ $dt->add(-0.1) };
    like $@, qr/^Argument "-0.1" isn't integer at .*01basic\.t line \d+/;
    
    eval{ my $d = $dt + 0.1 };
    like $@, qr/^Argument "0.1" isn't integer at .*01basic\.t line \d+/;
    
    eval{ my $d = $dt - 0.1 };
    like $@, qr/^Argument "-0.1" isn't integer at .*01basic\.t line \d+/;
    
    my $dt2 = Flapp->Date->new('2011-03-03');
    eval{ my $d = $dt + $dt2 };
    like $@, qr/^Argument "2011-03-03" isn't integer at .*01basic\.t line \d+/;
    
    eval{ my $d = $dt2 + $dt };
    like $@, qr/^Argument "2011-02-28" isn't integer at .*01basic\.t line \d+/;
    
    is $dt2 - $dt, 3;
    is $dt - $dt2, -3;
}

{ #add_month
    my $dt = Flapp->Date->new('2011-01-31');
    is "$dt", '2011-01-31';
    
    $dt->add_month(1);
    is "$dt", '2011-02-28';
    
    $dt->mon('+1');
    is "$dt", '2011-03-28';
    
    $dt->add_month(-1);
    is "$dt", '2011-02-28';
    
    $dt->mon(-1);
    is "$dt", '2011-01-28';
    
    $dt->mon(-1);
    is "$dt", '2010-12-28';
    
    $dt->mon('+12');
    is "$dt", '2011-12-28';
    
    $dt->mon('+1');
    is "$dt", '2012-01-28';
    
    $dt->mon('-13');
    is "$dt", '2010-12-28';
    
    $dt->mon('+13');
    is "$dt", '2012-01-28';
}

{ #add_year
    my $dt = Flapp->Date->new('2012-02-29');
    ok $dt->is_valid;
    
    $dt->add_year(1);
    is "$dt", '2013-02-28';
    ok $dt->is_valid;
    
    $dt = Flapp->Date->new('2012-02-29')->year('+1');
    is "$dt", '2013-02-28';
    ok $dt->is_valid;
}

{ #day_of_week
    my $dt = Flapp->Time->parse('20110208');
    is $dt->day_of_week, 2;
    is $dt->day(6)->dow, 7;
}

{ #epoch
    local $Flapp::Date::LOCAL_TIME_ZONE_OFFSET = 0;
    my $dt = Flapp->Date->new('2000-01-01');
    is my $e = $dt->epoch, 946684800;
    my $days = (365 * 400 + 97) * 5;
    
    $dt->day(-$days);
    $e -= 60 * 60 * 24 * $days;
    is $dt, '0000-01-01';
    is $dt->epoch, $e;
    
    $days = sub{
        my($days, $ymd) = @_;
        $dt->day("+$days");
        $e += 60 * 60 * 24 * $days;
        is $dt, $ymd, $ymd;
        is $dt->epoch, $e;
    };
    my $y = '0000';
    while($y <= 2801){
        my $ldom = $dt->is_leap_year ? 29 : 28;
        $days->(31 + $ldom - 1,  "$y-02-$ldom");
        $days->(1, "$y-03-01");
        $days->(31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30 + 31 - 1, "$y-12-31");
        $y = sprintf('%04d', $y + 1);
        $days->(1, "$y-01-01");
        
        next if $y % 5;
        $y = sprintf('%04d', $y + 95);
        $days->(365 * 95 + 23, "$y-01-01");
    }
    
    ok ($dt == $e);
    ok !($dt == $e + 60 * 60 * 24);
    ok ($dt + 1 == $e + 60 * 60 * 24);
}

{ #is_valid
    ok (Flapp->Date->new('0000-01-01')->is_valid);
    ok (Flapp->Date->new('9999-12-31')->is_valid);
    ok !(Flapp->Date->new('0000-01-00')->is_valid);
    ok !(Flapp->Date->new('9999-12-32')->is_valid);
}

{ #parse
    is(Flapp->Date->parse(''), undef);
    is(Flapp->Date->parse(2011), '2011-01-01');
    is(Flapp->Date->parse(201102), '2011-02-01');
    is(Flapp->Date->parse('2011/2/3'), '2011-02-03');
    is(Flapp->Date->parse(2011, 2, 3), '2011-02-03');
}

{ #today
    like (Flapp->Date->today, qr/^\d{4}-\d\d-\d\d\z/);
}

{ #to_time
    no warnings 'once';
    local *Flapp::Date::project = sub{ 'Flapp' };
    
    local $Flapp::Date::LOCAL_TIME_ZONE_OFFSET = 0;
    is (Flapp->Date->new('2012-06-04')->to_time, '2012-06-04T00:00:00+00:00');
    
    local $Flapp::Date::LOCAL_TIME_ZONE_OFFSET = 60 * 60 * 9;
    is (Flapp->Date->new('2012-06-04')->to_time, '2012-06-04T00:00:00+09:00');
}

{ #_data_
    my $d1 = Flapp->Date->new('2012-06-04');
    my $d2 = Flapp->Date->new('2012-06-04');
    
    $d1->_data_->{d} = 'd1';
    $d2->_data_->{d} = 'd2';
    
    is $d1->_data_->{d}, 'd1';
    is $d2->_data_->{d}, 'd2';
}

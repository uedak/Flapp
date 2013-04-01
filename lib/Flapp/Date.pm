package Flapp::Date;
our @OVERLOAD;
BEGIN{ @OVERLOAD = qw/cmp _ov_cmp - _ov_minus + _ov_plus <=> _ov_ss "" to_s/ }
use Flapp qw/-b Flapp::Object -m -s -w/;
use Carp;
use Time::Local qw/timegm_nocheck/;
use overload @OVERLOAD;

our $IS_32BIT = 1; #(~0 >> 31 == 1); #Some linux64 doesn't support 2038 problems...
our $LOCAL_TIME_ZONE_OFFSET = timegm_nocheck(localtime(0));
our $MIN_EPOCH = $^O eq 'MSWin32' ? 0 : -2147483648;
our @YEAR_CACHE = (
    [400, 12622780800],
    [100,  3155673600, -3],
    [  4,   126230400],
    [  1,    31536000, -3],
);

sub INCLUDED { $_[1]->overload::OVERLOAD(@OVERLOAD) }

sub add { shift->add_day(@_) }

sub add_month {
    my $self = shift;
    my $m = $self->month + $self->_int(shift);
    
    if(my $y = int(($m - ($m > 0 ? 1 : 12)) / 12)){
        $self->year($self->year + $y);
        $m -= $y * 12;
    }
    $self->month($m);
    if((my $d = $self->day) > 28){
        my $ldom = $self->last_day_of_month;
        $self->day($ldom) if $d > $ldom;
    }
    $self;
}

sub add_year {
    my $self = shift;
    $self->year($self->year + $self->_int(shift));
    if((my $d = $self->day) > 28){
        my $ldom = $self->last_day_of_month;
        $self->day($ldom) if $d > $ldom;
    }
    $self;
}

sub clone { bless \"$_[0]", ref $_[0] }

sub day_of_week {
    my $self = shift;
    my($y, $m, $d) = @_ ? @_ : map{ $self->$_ } qw/year month day/;
    ($y, $m) = ($y - 1, $m + 12) if $m <= 2;
    ($y + int($y / 4) - int($y / 100) + int($y / 400) + int(2.6 * $m + 1.6) + $d) % 7 || 7;
}
*dow = \&day_of_week;

sub epoch {
    my $self = shift;
    if(@_){
        my $t = $self->_gmtime($self->_int(shift) + $LOCAL_TIME_ZONE_OFFSET);
        $$self = sprintf('%04d-%02d-%02d', $t->[5] + 1900, $t->[4] + 1, $t->[3]);
        return $self;
    }
    $self->_timegm(($self->_match || $self->_invalid), $LOCAL_TIME_ZONE_OFFSET);
}

sub _gmtime {
    return [gmtime($_[1])] if !$IS_32BIT || ($MIN_EPOCH <= $_[1] && $_[1] <= 2147483647);
    my $self = shift;
    my($y, $e) = (2000, $_[0] - 946684800);
    foreach my $yc (@YEAR_CACHE){
        my $i = int($e / $yc->[1]);
        $i++ if $e > 0;
        next if !$i;
        $i = $yc->[2] if $yc->[2] && $i < $yc->[2];
        $y += $yc->[0] * $i;
        ($e -= $yc->[1] * $i) || last;
    }
    
    #94694400 => 1973-01-01 for 1972(leap)
    $e += $self->is_leap_year(--$y) ? 94694400 : 31536000 if $e;
    
    my @gmt = gmtime($e);
    $gmt[5] = $y - 1900;
    \@gmt;
}

sub _int { $_[1] =~ /^[\+\-]?[0-9]+\z/ ? $_[1] : croak qq{Argument "$_[1]" isn't integer} }

sub _invalid {
    my $self = shift;
    croak 'Invalid '.($self->can('hms') ? 'Time' : 'Date').qq{: "$self"};
}

sub is_leap_year {
    my $self = shift;
    my $y = @_ ? shift : $self->year;
    (!($y % 4) && ($y % 100) || !($y % 400)) && 1;
}

sub is_valid {
    my $self = shift;
    $self->_is_valid($self->_match);
}

sub _is_valid {
    my($self, $r) = @_;
    ($r
     && 1 <= $r->[1] && $r->[1] <= 12
     && 1 <= $r->[2] && $r->[2] <= $self->last_day_of_month($r->[0], $r->[1])
    );
}

our @LAST_DAY_OF_MONTH = (0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
sub last_day_of_month {
    my $self = shift;
    my($y, $m) = @_ ? @_ : map{ $self->$_ } qw/year month/;
    $m == 2 && $self->is_leap_year($y) ? 29 : $LAST_DAY_OF_MONTH[$m];
}
*ldom = \&last_day_of_month;

sub _match { ${$_[0]} =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2})\z/ && [$1, $2, $3] }

sub _mk_accessors {
    my $pkg = shift;
    
    foreach(@_){
        my($name, $nm, $pos, $len, $sec) = @$_;
        my $add = "add_$name";
        my %sub;
        $sub{$name} = sub{
            my $self = shift;
            $self->_invalid if $pos + $len > length($$self);
            if(@_){
                return $self->$add(shift) if $_[0] =~ /^[\+\-][0-9]+\z/;
                substr($$self, $pos, $len) = sprintf("%0${len}d", shift);
                return $self;
            }
            int substr($$self, $pos, $len);
        };
        $sub{$nm} = sub{
            my $self = shift;
            $self->_invalid if $pos + $len > length($$self);
            substr($$self, $pos, $len);
        };
        $sub{$add} = sub{
            my $self = shift;
            $self->epoch($self->epoch + $self->_int(shift) * $sec)
        } if $sec;
        no strict 'refs';
        *{$pkg.'::'.$_} = $sub{$_} for keys %sub;
    }
}

sub new { bless \(defined $_[1] ? "$_[1]" : ''), $_[0] }

sub _ov_cmp { "$_[0]" cmp "$_[1]" }

sub _ov_minus {
    if(ref $_[1] && $_[1]->can('epoch')){
        my($d1, $d2) = @_;
        my $e = $d1->epoch - $d2->epoch;
        $e /= 86400 if !$d1->can('hms') && !$d2->can('hms');
        return $e;
    }
    shift->_ov_plus(-shift);
}

sub _ov_plus {
    my $self = shift;
    $self->clone->add($self->_int(shift));
}

sub _ov_ss {
    my($_a, $_b) = map{ ref($_) ? $_->epoch : $_ } @_;
    $_a <=> $_b;
}

sub parse {
    my $pkg = shift;
    my @t = @_ > 1 ? @_ :
        $_[0] && $_[0] =~ /^(\d{4})[\-\/]?(\d{1,2})[\-\/]?(\d{1,2})\z/ ? ($1, $2, $3) :
        return undef;
    $pkg->new(sprintf('%04d-%02d-%02d', $t[0], $t[1], $t[2]));
}

sub strftime {
    my($self, $f) = @_;
    my $s = $self->_strftime;
    $f =~ s/%({([0-9A-Za-z_]+)}|.)/
        defined $2 ? $self->$2 : ($s->{$1} || croak qq{Unimplemented format: "%$1"})->($self)
    /eg;
    $f;
}

our $STRFTIME;
sub _strftime {
    $STRFTIME ||= do{
        my @a = qw/0 Mon Tue Wed Thu Fri Sat Sun/;
        my @A = qw/0 Monday Tuesday Wednesday Thursday Friday Saturday Sunday/;
        my @b = qw/0 Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
        my @B = qw/0 January February March April May June
            July August September October November December/;
        
        my $s = {
            '%' => sub{ '%' },
            A => sub{ $A[shift->dow] },
            a => sub{ $a[shift->dow] },
            b => sub{ $b[shift->m] },
            B => sub{ $B[shift->m] },
            C => sub{ substr(shift->Y, 0, 2) },
            d => sub{ shift->d },
            e => sub{ sprintf('%2s', shift->day) },
            F => sub{ shift->ymd },
            m => sub{ shift->m },
            n => sub{ "\n" },
            s => sub{ shift->epoch },
            t => sub{ "\t" },
            u => sub{ shift->dow },
            w => sub{ shift->dow % 7 },
            Y => sub{ shift->Y },
            y => sub{ substr(shift->Y, -2) },
        };
        $s->{h} = $s->{b};
        $s;
    };
}

sub to_s { $Flapp::Object::OVERLOAD ? ${$_[0]} : $_[0] }
*TO_JSON = \&to_s;

sub to_time {
    my $self = shift;
    $self->project->Time->new('')->epoch($self->epoch);
}

sub today { $Flapp::NOW ? shift->new(substr($Flapp::NOW, 0, 10)) : shift->new('')->epoch(time) }

sub _timegm {
    my($self, $r, $o) = @_;
    if($IS_32BIT && $r->[0] < 1000){
        my $i = int((1000 - $r->[0]) / 400) + 1;
        $r->[0] += 400 * $i;
        $o += $YEAR_CACHE[0]->[1] * $i;
    }
    timegm_nocheck(@$r[5, 4, 3, 2], $r->[1] - 1, $r->[0]) - $o;
}

sub ymd {
    my $self = shift;
    join(@_ ? shift : '-', map{ $self->$_ } qw/Y m d/);
}

__PACKAGE__->_mk_accessors(
    [year  => 'Y', 0, 4],
    [month => 'm', 5, 2],
    [day   => 'd', 8, 2, 60 * 60 * 24],
);
*mon = \&month;

1;

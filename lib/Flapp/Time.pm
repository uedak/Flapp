package Flapp::Time;
use Flapp qw/-b Flapp::Date -m -s -w/;
use Carp;

sub add { shift->add_second(@_) }

sub as_cookie_expires { shift->time_zone('+00:00')->strftime('%a, %d-%b-%Y %T GMT') }

sub epoch {
    my $self = shift;
    if(@_){
        my $r = $self->_match;
        my $o = $r ? $self->_tz2ofs($r->[6]) : $Flapp::Date::LOCAL_TIME_ZONE_OFFSET;
        my $t = $self->_gmtime($self->_int(shift) + $o);
        $$self = sprintf('%04d-%02d-%02dT%02d:%02d:%02d%s',
            $t->[5] + 1900, $t->[4] + 1, @$t[3, 2, 1, 0], $self->_ofs2tz($o));
        return $self;
    }
    my $r = $self->_match || $self->_invalid;
    $self->_timegm($r, $self->_tz2ofs($r->[6]));
}

sub hms {
    my $self = shift;
    join(@_ ? shift : ':', map{ $self->$_ } qw/H M S/);
}

sub _is_valid {
    my($self, $r) = @_;
    ($r
     && $self->SUPER::_is_valid($r)
     && $r->[3] <= 23 && $r->[4] <= 59 && $r->[5] <= 59
     && substr($r->[6], 1, 2) <= 23 && substr($r->[6], -2) <= 59
    );
}

sub _match {
    ${$_[0]} =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2})
        T([0-9]{2}):([0-9]{2}):([0-9]{2})([\+\-][0-9]{2}:?[0-9]{2})\z/x
     && [$1, $2, $3, $4, $5, $6, $7];
}

sub now { $Flapp::NOW ? shift->new($Flapp::NOW) : shift->new('')->epoch(time) }

sub _ofs2tz {
    my $m = $_[1] / 60;
    sprintf('%+03d:%02d', $m / 60, $m % 60);
}

sub parse {
    my $pkg = shift;
    my @t = @_ > 1 ? @_ : $_[0] && (
        $_[0] =~ /^([0-9]{4})[\-\/]([0-9]{1,2})[\-\/]([0-9]{1,2})
        (?:[T\ ]([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,2}))?(Z|[\+\-].+)?\z/x
     || $_[0] =~ /^([0-9]{4})([0-9]{2})([0-9]{2})
        (?:[T\ ]?([0-9]{2})([0-9]{2})([0-9]{2}))?(Z|[\+\-].+)?\z/x
    ) ? ($1, $2, $3, $4, $5, $6, $7) : return undef;
    $pkg->new(sprintf('%04d-%02d-%02dT%02d:%02d:%02d%s',
        $t[0], $t[1], $t[2], $t[3] || 0, $t[4] || 0, $t[5] || 0,
        $pkg->_ofs2tz($t[6] ? $pkg->_tz2ofs($t[6]) : $Flapp::Date::LOCAL_TIME_ZONE_OFFSET),
    ));
}

our $STRFTIME;
sub _strftime {
    $STRFTIME ||= do{
        my $I = sub{ sprintf('%02d', shift->H % 12 || 12) };
        my $p = sub{ shift->H < 12 ? 'AM' : 'PM' };
        
        my $s = {
            %{shift->SUPER::_strftime(@_)},
            H => sub{ shift->H },
            I => $I,
            k => sub{ sprintf('%2s', shift->hour) },
            l => sub{ sprintf('%2s', shift->H % 12 || 12) },
            M => sub{ shift->M },
            p => $p,
            P => sub{ shift->H < 12 ? 'am' : 'pm' },
            r => sub{ $I->(@_).':'.$_[0]->M.':'.$_[0]->S.' '.$p->(@_) },
            R => sub{ $_[0]->H.':'.$_[0]->M },
            S => sub{ shift->S },
            T => sub{ shift->hms },
            z => sub{ my $tz = shift->tz; substr($tz, 0, 3).substr($tz, -2) },
        };
    };
}

sub time_zone {
    my $self = shift;
    my $r = $self->_match || $self->_invalid;
    if(@_){
        if((my $o1 = $self->_tz2ofs(shift)) != (my $o2 = $self->_tz2ofs($r->[6]))){
            $self->add($o1 - $o2);
            substr($$self, 19) = $self->_ofs2tz($o1);
        }
        return $self;
    }
    $r->[6];
}
*tz = \&time_zone;

sub to_date {
    my $self = shift;
    $self->project->Date->new($self->ymd);
}

sub _tz2ofs {
    return 0 if $_[1] eq 'Z';
    $_[1] =~ /^([\+\-]?)(?:([0-9]{2}):?([0-9]{2})|([0-9]{1,2}))\z/
     || croak qq{Invalid time_zone: "$_[1]"};
    ($1.(($2 || $4) * 60 + ($3 || 0))) * 60;
}

__PACKAGE__->_mk_accessors(
    [hour   => 'H', 11, 2, 60 * 60],
    [minute => 'M', 14, 2, 60],
    [second => 'S', 17, 2, 1],
);
*min = \&minute;
*sec = \&second;

1;

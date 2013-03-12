package Flapp::App::Web::UserAgent;
use Flapp qw/-b Flapp::Object -m -r -s -w/;
use constant content_type => 'text/html; charset=utf-8';
use constant cookie_enabled => 1;
use constant encoding => 'utf-8';
use constant input_kana_h2z => 1;
use constant is_mobile => !1;
use constant view_suffix => '';

use constant HEAD5 => {
    'DoCoM' => 'Docomo',
    'KDDI-' => 'Au',
    'UP.Br' => 'Au',
    'J-PHO' => 'Softbank',
    'Vodaf' => 'Softbank',
    'SoftB' => 'Softbank',
};

sub context { shift->{context} || die 'No context' }
*c = \&context;

sub detect {
    my($class, $c) = @_;
    my $ua = $c->req->user_agent || return undef;
    
    if(
        length($ua) >= 5
     && (my $m = $class->HEAD5->{substr($ua, 0, 5)})
     && eval{ require Encode::JP::Emoji }
    ){
        return $m;
    }
    
    $ua =~ m%iPhone|iPod% ? 'IPhone' : undef;
}

sub filter_input {
    my $self = shift;
    my $u = $self->c->Util;
    sub{
        $_[0] =~ s/\r\n?/\n/g;
        $u->utf8_on($_[0]) || return if $Flapp::UTF8;
        $u->tr(\$_[0], 'kana_h2z', 1) if $self->input_kana_h2z;
    };
}

sub filter_output {
    my $self = shift;
    return undef if !$Flapp::UTF8;
    require Encode;
    sub{ Encode::_utf8_off($_[0]) };
}

sub new {
    my($class, $c) = @_;
    my $ua = $class->detect($c) || 'PC';
    $class->$ua->_new($c);
}

sub _new {
    my $ua = shift->_new_({});
    $ua->_weaken_($ua->{context} = shift);
    $ua;
}

1;

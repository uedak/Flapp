package Flapp::App::Web::UserAgent::Mobile;
use Flapp qw/-b Flapp::App::Web::UserAgent -m -s -w/;
use Encode;
use constant cookie_enabled => 0;
use constant internal_encoding => 'x-utf8-e4u-mixed';
use constant is_mobile => 1;
use constant view_suffix => '.mobile';

sub filter_input {
    my $self = shift;
    #require Encode::JP::Emoji; #in Flapp::App::Web::UserAgent::detect
    my $u = $self->c->Util;
    
    sub{
        $_[0] =~ s/\r\n?/\n/g;
        Encode::from_to($_[0], $self->encoding, $self->internal_encoding);
        $u->utf8_on($_[0]) || return if $Flapp::UTF8;
        $u->tr(\$_[0], 'kana_h2z', 1) if $self->input_kana_h2z;
    };
}


sub filter_output {
    my $self = shift;
    return undef if $self->c->res->content_type !~ /html/;
    #require Encode::JP::Emoji; #in Flapp::App::Web::UserAgent::detect
    my $u = $self->c->Util;
    
    sub{
        $u->tr(\$_[0], 'kana_z2h', 1);
        Encode::_utf8_off($_[0]) if $Flapp::UTF8;
        Encode::from_to($_[0], $self->internal_encoding, $self->encoding);
    };
}

1;

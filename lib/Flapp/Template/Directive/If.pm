package Flapp::Template::Directive::If;
use Flapp qw/-b Flapp::Template::Directive -s -w/;
use constant HAS_END => 1;

sub begin {
    my($dtv, $doc, $ft) = @_;
    ($doc->{tmp}{$dtv->{id}} = $dtv->{code}->($doc) && 1) ? $doc->block($dtv) : $dtv->{next_id};
}

sub chain {
    my($dtv, $b2, $end) = @_;
    shift->SUPER::chain(@_);
    $_->{last_id} = $end->{id} for @$b2;
}

1;

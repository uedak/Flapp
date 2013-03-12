package Flapp::Template::Directive::Set;
use Flapp qw/-b Flapp::Template::Directive -s -w/;

sub begin {
    my($dtv, $doc, $ft) = @_;
    $dtv->{code}->($doc);
    $dtv->{id} + 1;
}

1;

package Flapp::Template::Directive::Switch;
use Flapp qw/-b Flapp::Template::Directive -s -w/;
use constant HAS_END => 1;

sub begin {
    my($dtv, $doc, $ft) = @_;
    $doc->{tmp}{$dtv->{id}} = \($dtv->{code}->($doc));
    $dtv->{next_id};
}

sub chain {
    my($dtv, $b2, $end) = @_;
    @$_{qw/first_id last_id/} = ($dtv->{id}, $end->{id}) for @$b2;
    shift->SUPER::chain(@_);
}

1;

package Flapp::Template::Directive::Next;
use Flapp qw/-b Flapp::Template::Directive -s -w/;

sub begin {
    my($dtv, $doc, $ft) = @_;
    return $dtv->{id} + 1 if $dtv->{code} && !$dtv->{code}->($doc);
    my $lb = $doc->loop_block || die qq{Can't "NEXT" outside a loop block};
    $lb->{end};
}

sub parse { shift->_parse_last(@_) }

1;

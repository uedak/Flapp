package Flapp::Template::Directive::Last;
use Flapp qw/-b Flapp::Template::Directive -s -w/;

sub begin {
    my($dtv, $doc, $ft) = @_;
    return $dtv->{id} + 1 if $dtv->{code} && !$dtv->{code}->($doc);
    my $lb = $doc->loop_block || die qq{Can't "LAST" outside a loop block};
    delete $doc->{tmp}{$lb->{begin}};
    $lb->{end} + 1;
}

sub parse { shift->_parse_last(@_) }

1;

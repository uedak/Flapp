use Flapp qw/-m -s -w/;

sub {
    my($dtv, $doc, $ft) = @_;
    $#{$doc->{body}} + 1;
};

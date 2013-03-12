use Flapp qw/-m -s -w/;

sub {
    my $c = shift;
    my $r = ref $_[0] ? shift : do{ \(my $s = shift) };
    $$r =~ s/(&(?:[a-z]+|#[0-9]+);)/$c->HTM2STR->{$1} || $1/eg;
    $$r;
};

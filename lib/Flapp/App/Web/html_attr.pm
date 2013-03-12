use Flapp qw/-m -s/; #no warnings;

sub {
    my $c = shift;
    my $r = ref $_[0] ? shift : do{ \(my $s = shift) };
    $$r =~ s/(["&'()<>])/$c->STR2HTM->{$1}/eg;
    $$r;
};

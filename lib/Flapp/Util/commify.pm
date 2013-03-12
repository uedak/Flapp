use Flapp qw/-m -s -w/;

sub{
    shift;
    my $r = ref $_[0] ? shift : do{ \(my $s = shift) };
    1 while $$r =~ s/(\d)(\d{3})(?!\d)/$1,$2/g;
    $$r;
};

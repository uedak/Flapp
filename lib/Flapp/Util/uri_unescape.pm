use Flapp qw/-m -s/; #no warnings;

sub{
    my $util = shift;
    my $r = ref $_[0] ? shift : do{ \(my $s = shift) };
    $$r =~ s/%([0-9A-Fa-f]{2})|\+/$1 ? pack('H*', lc $1) : ' '/eg;
    $util->utf8_on($$r) if $Flapp::UTF8;
    $$r;
};

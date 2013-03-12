use Flapp qw/-m -s -w/;
use Scalar::Util;

sub{
    my $os = shift;
    die 'No arguments' if !defined($_[0]) || $_[0] eq '';
    return $_[0] if $os->is_path($_[0]);
    
    die qq{Unsafe cmd: "$_[0]"} if !Scalar::Util::readonly($_[0]);
    (my $cmd = shift) =~ s/%(?:\{([0-9a-z_]+)\}|([0-9a-z_]+)|%)/
        defined($+) ? do{
            my $arg = shift;
            my $method = "is_$+";
            no warnings 'uninitialized';
            join(' ',
                map{ $os->$method($_) ? $_ : die "Invalid $+($_)" }
                ref($arg) eq 'ARRAY' ? @$arg : $arg
            )
        } : '%';
    /eg;
    $cmd;
};

use Flapp qw/-m -s -w/;

sub{
    my($self, $mode, $path) = (shift, $_[1], $_[2]);
    die "Invalid mode($mode)" if !$mode || $mode !~ /^(<|>>?)(:[0-9a-z\(\)]+)?\z/;
    $self->open(my $h, $mode, $path) || return undef;
    if(substr($mode, 0, 1) eq '<'){
        local $/;
        $_[0] = <$h>;
    }else{
        print $h $_[0];
    }
    close($h);
};

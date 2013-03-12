use Flapp qw/-m -s -w/;

sub {
    my($dtv, $sr, $p) = @_;
    $dtv->{code} = $p->compile($sr) || return;
    while($$sr =~ s/^[\t\n\r ]*([a-z_][0-9a-z_]*)[\t\n\r ]*=[\t\n\r ]*//){
        $dtv->{local}{$1} = $p->compile($sr) || return;
    }
    1;
};

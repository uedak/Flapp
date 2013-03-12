use Flapp qw/-m -s -w/;

sub {
    my($self, $cds, $src, $opt) = @_;
    my $sr = ref($src);
    die "Invalid src ref($sr)" if $sr ne 'HASH' && $sr ne 'ARRAY';
    my $v = $opt->{validate};
    my $s = $opt->{safe};
    my(@err, @str);
    if($sr eq 'HASH'){
        foreach my $cd (ref($cds) eq 'ARRAY' ? @$cds : $cds){
            next if !defined $cd || $cd eq '';
            $v ? push(@err, $cd) : $s ? next : die "Not exists($cd)" if !exists $src->{$cd};
            push(@str, $src->{$cd});
        }
    }elsif($sr eq 'ARRAY'){
        CD: foreach my $cd (ref($cds) eq 'ARRAY' ? @$cds : $cds){
            next if !defined $cd || $cd eq '';
            foreach(@$src){
                if($_->[0] eq $cd){
                    push(@str, $_->[$opt->{index} || 1]);
                    next CD;
                }
            }
            $v ? push(@err, $cd) : $s ? next : die "Not exists($cd)";
        }
    }
    return @err if $v;
    no warnings 'uninitialized';
    join($opt->{join} || ' / ', @str);
};

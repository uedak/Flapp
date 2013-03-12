use Flapp qw/-m -s -w/;

sub{
    my($self, $sr, $rows, $page) = @_;
    my $lim = ' LIMIT ';
    $lim .= (($page - 1) * $rows).',' if $page && $page > 1;
    $lim .= $rows;
    $$sr .= $lim;
};

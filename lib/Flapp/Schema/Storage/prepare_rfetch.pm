use Flapp qw/-m -s -w/;

sub{
    my($self, $sth, $j) = @_;
    my($nm, $i) = ($sth->{NAME_lc}, 0);
    while($j){
        my($sel, $i1, $i2) = ($j->{select} || die, $i);
        if($sel->{has}{'*'}){
            $nm->[++$i] eq '|' && ($i2 = $i++ - 1) while $i < $#$nm && !defined $i2;
            $i2 ||= $i;
        }else{
            $i2 = ($i += @{$sel->{cols}}) - 1;
        }
        $j->{idxs} = [$i1 .. $i2];
        $j->{nms} = [@$nm[@{$j->{idxs}}]];
        $j->{pk_idxs} = [grep{ $sel->{pk}{$nm->[$_]} } @{$j->{idxs}}];
        $j = $j->{next};
    }
};

use Flapp qw/-m -s -w/;
use Encode;

sub{
    local $Flapp::UTF8;
    my($self, $t, $f, $opt) = @_;
    my $u = $self->Util;
    my $cnt = 0;
    
    my $sth = $self->dbh->prepare('SELECT '.$self->asterisk_for($t)." FROM $t");
    $sth->{mysql_use_result} = 1;
    $sth->execute;
    
    $self->OS->open(my $H, '>', $f) || die "$!($f)";
    print $H join("\t", @{$sth->{NAME_lc}})."\n" if !exists $opt->{header} || $opt->{header};
    while(my $r = $sth->fetchrow_arrayref){
        Encode::_utf8_off(my $tsv = $u->ary2tsv(@$r)."\n");
        print $H $tsv;
        $cnt++;
    }
    close($H);
    $cnt;
};

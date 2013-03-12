use Flapp qw/-m -s -w/;

sub{
    my($self, $f, $t, $opt) = @_;
    local $Flapp::UTF8 if $opt->{bin};
    my $u = $self->Util;
    my $dbh = $self->dbh;
    
    $self->OS->open(my $H, $f) || die "$!($f)";
    my @col;
    if(!defined $opt->{header} || $opt->{header}){
        chomp(my $h = <$H>);
        @col = $u->tsv2ary($h);
    }else{
        @col = @{$self->table_columns($t)};
    }
    
    my $per = defined $opt->{commit_per} ? $opt->{commit_per} : 1000;
    my $sth = $dbh->prepare(
        "INSERT INTO $t(".join(', ', @col).') VALUES('.
        join(', ', map{ $self->placeholder_for($t, $_) } @col).')'
    );
    $dbh->do("TRUNCATE TABLE $t") if !defined $opt->{truncate} || $opt->{truncate};
    $dbh->begin_work if $per;
    my $cnt = 0;
    my @n = defined $opt->{strict} && !$opt->{strict} ? (0 .. $#col) : ();
    while(my $r = <$H>){
        chomp $r;
        $sth->execute(@n ? ($u->tsv2ary($r))[@n] : $u->tsv2ary($r));
        $cnt++;
        next if !$per || ($cnt % $per);
        $dbh->commit;
        $dbh->begin_work;
    }
    $dbh->commit if $per;
    close($H);
    $cnt;
};

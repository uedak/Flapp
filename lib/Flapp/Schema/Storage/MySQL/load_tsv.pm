use Flapp qw/-m -s -w/;

sub{
    my($self, $f, $t, $opt) = @_;
    local $Flapp::UTF8 if $opt->{bin};
    my $u = $self->Util;
    
    $self->OS->open(my $H, $f) || die "$!($f)";
    my @col;
    if(!defined $opt->{header} || $opt->{header}){
        chomp(my $h = <$H>);
        @col = $u->tsv2ary($h);
    }else{
        @col = @{$self->table_columns($t)};
    }
    
    my $per = $opt->{commit_per};
    my $ldr = $self->BulkLoader->new($self, $t, -c => \@col, $per ? (-n => $per) : ());
    $self->dbh->do("TRUNCATE TABLE $t") if !defined $opt->{truncate} || $opt->{truncate};
    my $cnt = 0;
    my @n = defined $opt->{strict} && !$opt->{strict} ? (0 .. $#col) : ();
    while(my $r = <$H>){
        chomp $r;
        $ldr->add(@n ? ($u->tsv2ary($r))[@n] : $u->tsv2ary($r));
        $cnt++;
    }
    close($H);
    $cnt;
};

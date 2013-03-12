use Flapp qw/-m -s -w/;

sub{
    my $self = shift;
    my $dbh = $self->dbh;
    my(@rn, @del);
    
    /\W/ && die qq{Invalid name "$_"} for @_;
    while(my $f = shift){
        my $t = shift || die qq{No name for "$f"};
        if($dbh->selectrow_arrayref("SHOW TABLES LIKE '$t'")){
            push @rn, "$t TO _$t", "$f TO $t";
            push @del, "_$t";
        }else{
            push @rn, "$f TO $t";
        }
    }
    
    $dbh->do('RENAME TABLE '.join(",\n", @rn));
    $dbh->do("DROP TABLE $_") for @del;
    
    $self;
};

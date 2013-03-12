use Flapp qw/-m -s -w/;

sub{
    my($self, $sch) = @_;
    my $t = $sch->table || die "No table for $sch";
    int $self->dbh->prepare_cached("TRUNCATE TABLE $t")->execute;
};

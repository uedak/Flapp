use Flapp qw/-m -s -w/;

sub{
    my($self, $sch) = @_;
    my $opt = $sch->table_option;
    my $e = $opt->{engine};
    local $opt->{suffix} = ($opt->{suffix} ? "$opt->{suffix} " : '')."ENGINE=$e" if $e;
    $self->SUPER::create_table_sql($sch);
};

use Flapp qw/-m -s -w/;

sub{
    my($self, $sch) = @_;
    my $pk = $sch->primary_key;
    return if $pk && @$pk == 1 && $sch->column_info($pk->[0])->{-t} eq 'serial';
    $self->SUPER::create_table_sql_pk($sch);
};

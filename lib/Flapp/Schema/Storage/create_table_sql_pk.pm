use Flapp qw/-m -s -w/;

sub{
    my($self, $sch) = @_;
    my @sql;
    if(my $pk = $sch->primary_key){
        push @sql, 'CONSTRAINT '.$sch->table.'_pk PRIMARY KEY ('.join(', ', @$pk).')';
    }
    @sql;
};

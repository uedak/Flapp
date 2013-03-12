use Flapp qw/-m -s -w/;

sub{
    my($self, $sch) = @_;
    my $opt = $sch->table_option || {};
    
    no warnings 'uninitialized';
    my $sql = 'CREATE';
    $sql .= " $opt->{prefix}" if $opt->{prefix} ne '';
    $sql .= " TABLE ".$sch->table.' (';
    $sql .= join(',', map{ "\n  $_" }
        (map{ $self->create_table_sql_column($sch, $_) } @{$sch->column_infos}),
        $self->create_table_sql_pk($sch),
        $self->create_table_sql_constraint($sch),
    );
    $sql .= "\n)";
    $sql .= " $opt->{suffix}" if $opt->{suffix} ne '';
    $sql.";\n";
};

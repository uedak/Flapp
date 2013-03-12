use Flapp qw/-m -s -w/;

sub{
    my($self, $sch) = @_;
    $self->add_index_by_relation($sch);
    
    no warnings 'uninitialized';
    my $sql = '';
    foreach my $i (@{$sch->indexes || []}){
        $sql .= 'ALTER TABLE '.$sch->table.' ADD';
        $sql .= " $i->{prefix}" if $i->{prefix} ne '';
        $sql .= ' INDEX';
        $sql .= " $i->{name}" if $i->{name} ne '';
        $sql .= ' ('.join(', ', @{$i->{columns}}).")";
        $sql .= " $i->{suffix}" if $i->{suffix} ne '';
        $sql .= ";\n";
    }
    $sql;
};

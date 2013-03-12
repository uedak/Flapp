use Flapp qw/-m -s -w/;

sub{
    my($self, $sch) = @_;
    my $t = $sch->table;
    my @sql;
    foreach my $ri (@{$sch->relation_infos || []}){
        next if $ri->{type} ne 'belongs_to' || $ri->{-no_constraint};
        push @sql, "CONSTRAINT $t\_fk_$ri->{name} FOREIGN KEY (".
            join(', ', map{ $_->[1] } @{$ri->{on}}).
            ') REFERENCES '.$ri->{schema}->table.' ('.
            join(', ', map{ $_->[0] } @{$ri->{on}}).
            ')';
    }
    
    push @sql, "CONSTRAINT $_" for @{$sch->constraints || []};
    @sql;
};

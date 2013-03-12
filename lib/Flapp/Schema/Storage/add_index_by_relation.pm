use Flapp qw/-m -s -w/;

sub{
    my($self, $sch) = @_;
    my $proj = $sch->project;
    
    my %c2i;
    my $pk = $sch->primary_key;
    foreach my $cols (($pk ? $pk : ()), map{ $_->{columns} } @{$sch->indexes || []}){
        my $c2i = \%c2i;
        $c2i = $c2i->{$_} ||= {} for @$cols;
    }
    
    foreach(@{$sch->_schema_names_}){
        my $fsch = $sch->SCHEMA_BASE->$_;
        foreach my $ri (@{$fsch->relation_infos || []}){
            next if $ri->{schema} ne $sch;
            my @fk = map{ $_->[0] } @{$ri->{on}};
            my $c2i = \%c2i;
            ($c2i = $c2i->{$_}) || last for @fk;
            next if $c2i;
            $sch->add_index(\@fk);
            $c2i = \%c2i;
            $c2i = $c2i->{$_} ||= {} for @fk;
        }
    }
};

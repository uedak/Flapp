use Flapp qw/-m -s -w/;

sub{
    my $self = shift;
    my $proj = $self->project;
    
    my $ddl = $self->disable_constraint_sql;
    $ddl .= "\n" if $ddl;
    my $sb = $proj->schema($self->DB);
    foreach(@{$sb->_schema_names_}){
        my $sch = $sb->$_;
        $ddl .= $self->create_table_sql($sch).$self->add_index_sql($sch)."\n";
    }
    $ddl .= $self->enable_constraint_sql;
    $ddl;
};

use Flapp qw/-m -s -w/;

sub{
    my($self, $sch, $me) = (shift, shift, shift);
    my($qt, $pr) = ($self->REG_QT, $self->REG_PR);
    my $ci;
    
    $$_ =~ s%($qt|\(\s*SELECT\s(?:[^"'()]+|$qt|$pr)+\)|(\w+\.)?(\w+)(?!\s*\())%
        defined $3 && !$2 && ($ci ||= $sch->column_info)->{$3} ? "$me.$3" : $1%egi for @_;
};

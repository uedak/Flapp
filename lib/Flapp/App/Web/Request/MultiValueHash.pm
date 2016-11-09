package Flapp::App::Web::Request::MultiValueHash; #for compatibility
use Flapp qw/-b Flapp::Object -m -s -w/;

sub add {
    my $self = shift;
    $self->merge_mixed(shift, \@_);
    $self;
}

sub as_hashref { +{%{+shift}} }
*as_hashref_mixed = \&as_hashref;
*mixed = \&as_hashref;

sub as_hashref_multi {
    my $self = shift;
    my %h;
    $h{$_} = ref $self->{$_} eq 'ARRAY' ? [@{$self->{$_}}] : [$self->{$_}] for keys %$self;
    \%h;
}
*multi = \&as_hashref_multi;

sub clear {
    my $self = shift;
    undef %$self;
    $self;
}

sub clone {
    my $self = shift;
    my %h;
    $h{$_} = ref $self->{$_} eq 'ARRAY' ? [@{$self->{$_}}] : $self->{$_} for keys %$self;
    (ref $self)->_new_(\%h);
}

sub create { shift->_new_({}) }

#sub each {}

sub flatten {
    my $self = shift;
    my @f;
    foreach my $k (keys %$self){
        push @f, $k, $_ for ref $self->{$k} eq 'ARRAY' ? @{$self->{$k}} : $self->{$k};
    }
    @f;
}

sub from_mixed { shift->_new_({%{+shift}}) }

sub get { shift->{+shift} }

sub get_all {
    my($self, $k) = @_;
    !exists $self->{$k} ? () : ref $self->{$k} ne 'ARRAY' ? ($self->{$k}) : @{$self->{$k}};
}

sub get_one {
    my($self, $k) = @_;
    !exists $self->{$k} ? die qq{Key not found: "$k"} :
    ref $self->{$k} ne 'ARRAY' ? $self->{$k} :
    die qq{Multiple values match: "$k"};
}

#sub keys { keys %{+shift} } #not ordered

sub merge_flat {
    my $self = shift;
    
    while(my $k = shift){
        !exists $self->{$k} ? $self->{$k} = shift :
        ref $self->{$k} ne 'ARRAY' ? $self->{$k} = [$self->{$k}, shift] :
        push @{$self->{$k}}, shift;
    }
    $self;
}

sub merge_mixed {
    my $self = shift;
    my $h = @_ == 1 && shift;
    
    while(my($k, $v) = $h ? each %$h : splice @_, 0, 2){
        foreach(ref $v eq 'ARRAY' ? @$v : $v){
            !exists $self->{$k} ? $self->{$k} = $_ :
            ref $self->{$k} ne 'ARRAY' ? $self->{$k} = [$self->{$k}, $_] :
            push @{$self->{$k}}, $_;
        }
    }
    $self;
}

sub new {
    my $self = shift->_new_({});
    $self->merge_flat(@_) if @_;
    $self;
}

sub remove {
    my $self = shift;
    delete $self->{+shift};
    $self;
}

#sub values { values %{+shift} } #not ordered

1;

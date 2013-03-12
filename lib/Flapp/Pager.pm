package Flapp::Pager;
use Flapp qw/-b Flapp::Object -m -s -w/;
__PACKAGE__->_mk_accessors_(qw/total_entries current_page/);

use constant DEFAULT_ENTRIES_PER_PAGE => 10;

sub TO_JSON {
    my $self = shift;
    +{map{ $_ => $self->$_ } qw/current_page entries_per_page total_entries/};
}

sub entries_on_this_page {
    my $self = shift;
    return 0 if !$self->{total_entries};
    $self->last - $self->first + 1;
}

sub entries_per_page {
    my $self = shift;
    if(@_){
        my $i = shift;
        die $i if $i < 1;
        $self->{current_page} = int($self->first / $i) + 1;
        $self->{entries_per_page} = $i;
        return $self;
    }
    $self->{entries_per_page};
}

sub first {
    my $self = shift;
    return 0 if !$self->{total_entries};
    $self->{entries_per_page} * ($self->{current_page} - 1) + 1;
}

sub first_page { 1 }

sub last {
    my $self = shift;
    return $self->{total_entries} if $self->{current_page} == $self->last_page;
    $self->{entries_per_page} * $self->{current_page};
}

sub last_page {
    my $self = shift;
    return 1 if !$self->{total_entries};
    int(($self->{total_entries} - 1) / $self->{entries_per_page}) + 1;
}

sub next_page {
    my $self = shift;
    $self->{current_page} < $self->last_page ? $self->{current_page} + 1 : undef;
}

sub new {
    my $pkg = shift;
    $pkg->_new_({
        total_entries    => (shift || 0),
        entries_per_page => (shift || $pkg->DEFAULT_ENTRIES_PER_PAGE),
        current_page     => (shift || 1),
    });
}

sub pages {
    my $self = shift;
    my $n = shift || 10;
    my $i = $self->current_page - int(($n - 1) / 2);
    my $j = $self->current_page + int($n / 2);
    my $l = $self->last_page;
    
    if($i < 1){
        $j += 1 - $i;
        $i = 1;
    }
    if($j > $l){
        $i -= $j - $l;
        $j = $l;
    }
    $i = 1 if $i < 1;
    $j = $l if $j > $l;
    [$i .. $j];
}

sub previous_page {
    my $self = shift;
    $self->{current_page} > 1 ? $self->{current_page} - 1 : undef;
}
*prev_page = \&previous_page;

1;

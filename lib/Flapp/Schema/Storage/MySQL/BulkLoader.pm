package Flapp::Schema::Storage::MySQL::BulkLoader;
use Flapp qw/-b Flapp::Object -s -w/;

sub add {
    my $self = shift;
    die 'add '.@_.' bind variables when '.@{$self->{-c}}.' are needed' if @_ != @{$self->{-c}};
    push @{$self->{x}}, @_;
    ++$self->{n} >= $self->{-n} ? $self->flush : $self;
}

sub flush {
    my $self = shift;
    return $self if !$self->{n};
    my $t = $self->{-t} && &Time::HiRes::time * 1000;
    my($n, $x) = @$self{qw/n x/};
    @$self{qw/n x/} = (0, []);
    if(($self->{sth_n} || 0) != $n){
        my($sto, $t) = @$self{qw/storage table/};
        $self->{sth_x} ||= '('.join(',', map{ $sto->placeholder_for($t, $_) } @{$self->{-c}}).')';
        $self->{sth} = $sto->dbh->prepare(
            "INSERT INTO $t (".join(',', @{$self->{-c}}).
            ") VALUES\n".join(",\n", ($self->{sth_x}) x ($self->{sth_n} = $n))
        );
    }
    $self->{i} += int $self->{sth}->execute(@$x);
    $self->{t} += (&Time::HiRes::time * 1000 - $t) if $self->{-t};
    $self;
}

sub i { shift->{i} }

# -c => columns
# -n => num of rows for flush(default 100)
# -t => measure time
sub new {
    my $self = shift->_new_({storage => shift, table => shift, -n => 100, @_, i => 0, x => []});
    $self->{-c} ||= $self->{storage}->table_columns($self->{table});
    require Time::HiRes if $self->{-t};
    $self;
}

sub t { (shift->{t} || 0) / 1000 }

sub DESTROY { shift->flush->SUPER::DESTROY(@_) }

1;

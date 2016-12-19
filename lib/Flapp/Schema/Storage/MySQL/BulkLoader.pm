package Flapp::Schema::Storage::MySQL::BulkLoader;
use Flapp qw/-b Flapp::Object -s -w/;

sub add {
    my $self = shift;
    die 'add '.@_.' bind variables when '.@{$self->{-c}}.' are needed' if @_ != @{$self->{-c}};
    if(my $auto = $self->{-a}){
        my $i = -1;
        my $ph;
        my $vs = join(',', map{
            my $v = !defined($_) ? 'NULL' : /^[0-9]+\z/ ? $_ : $auto->[0]->quote($_);
            $auto->[1][++$i] eq '?' ? $v : ($ph = $auto->[1][$i]) =~ s/\?/$v/ ? $ph : die $ph;
        } @_);
        my $len = do{ use bytes; length($vs) } + 3;
        $self->flush if $auto->[4] && ($auto->[4] += $len) > $auto->[2];
        if(!$auto->[4]){
            $auto->[3] = "$auto->[5]\n($vs)";
            $auto->[4] = $auto->[6] + $len;
        }else{
            $auto->[3] .= ",($vs)";
        }
        $self->{n}++;
        return $self;
    }
    push @{$self->{x}}, @_;
    ++$self->{n} >= $self->{-n} ? $self->flush : $self;
}

sub flush {
    my $self = shift;
    return $self if !$self->{n};
    my $t = $self->{-t} && &Time::HiRes::time * 1000;
    if(my $auto = $self->{-a}){
        $self->{i} += int $auto->[0]->do($auto->[3]);
        $self->{t} += (&Time::HiRes::time * 1000 - $t) if $self->{-t};
        $auto->[3] = '';
        $auto->[4] = $self->{n} = 0;
        return $self;
    }
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
# -n => num of rows for flush(default auto)
# -t => measure time
sub new {
    my $self = shift->_new_({storage => shift, table => shift, @_, i => 0, x => []});
    $self->{-c} ||= $self->{storage}->table_columns($self->{table});
    $self->{-a} = do{
        my $dbh = $self->{storage}->dbh;
        my $phf = [map{ $self->{storage}->placeholder_for($self->{table}, $_) } @{$self->{-c}}];
        my $mal = $dbh->selectall_arrayref("SHOW VARIABLES LIKE 'max_allowed_packet'")->[0][1];
        my $sql = "INSERT INTO $self->{table}(".join(',', @{$self->{-c}}).") VALUES";
        [$dbh, $phf, $mal, '', 0, $sql, do{ use bytes; length($sql) }];
    } if !$self->{-n};
    require Time::HiRes if $self->{-t};
    $self;
}

sub t { (shift->{t} || 0) / 1000 }

sub DESTROY { shift->flush->SUPER::DESTROY(@_) }

1;

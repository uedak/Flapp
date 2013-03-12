package Flapp::Schema;
use Flapp qw/-b Flapp::Object -m -r -s -w/;
use Flapp::Schema::Core::Relationship;
use Flapp::Schema::Core::Row;
use constant COLUMN_OPTIONS => {
    -a => 1, #auto increment id
    -d => 1, #default (implement with perl, not DB, for validation)
    -e => 1, #enum
    -i => 1, #inflate
    -l => 1, #label
    -n => 1, #nullable
    -s => 1, #size
    -t => 1, #type
    -u => 1, #unsigned
    -v => 1, #validation
    -x => 1, #extra, for storage
};
use constant DEFAULT_SEARCH_ROWS => 10;
use constant MAX_SEARCH_ROWS => 100;

sub add_columns {
    die $_[0]->_dmsg_(1) if ref $_[0];
    my $sch = shift;
    my $co = $sch->COLUMN_OPTIONS;
    while(@_){
        my $cn = lc shift;
        my $ci = shift || die qq{No column info for "$sch.$cn"};
        die $sch->_dmsg_(4, $cn) if $sch->can($cn);
        die qq{No type(-t) for "$sch.$cn"} if !$ci->{-t};
        $co->{$_} || die qq{Invalid column option "$_" for column "$cn"} for keys %$ci;
        $sch->_add_column_($cn, $ci);
    }
    $sch;
}

sub _add_column_ {
    my($sch, $cn, $ci) = @_;
    $ci = {%$ci, name => $cn, -t => lc($ci->{-t})};
    $sch->storage->on_add_column($sch, $ci);
    $ci->{-d} ||= 1 if $cn eq $sch->LOCK_VERSION;
    
    my $g = $sch->_global_;
    push @{$g->{columns} ||= []}, $cn;
    $g->{column_info}{$cn} = $ci;
    $sch->_define_method_($cn, sub{ @_ > 1 ? shift->set_column($cn, @_) : shift->get_column($cn) });
}

sub add_constraint {
    die $_[0]->_dmsg_(1) if ref $_[0];
    my $sch = shift;
    push @{$sch->_global_->{constraints} ||= []}, shift;
    $sch;
}

sub add_index {
    die $_[0]->_dmsg_(1) if ref $_[0];
    my $sch = shift;
    my $g = $sch->_global_;
    (my @cn = @{+shift}) || die 'No columns';
    $g->{column_info}{$_} || die $sch->_dmsg_(5, $_) for @cn;
    push @{$g->{indexes} ||= []}, {%{shift || {}}, columns => \@cn};
    $sch;
}

sub columns { shift->_global_->{columns} }

sub column_enum { shift->column_info($_[0])->{-e} || die qq{No enum(-e) defined on "$_[0]"} }

sub column_info {
    my $ci = $_[0]->_global_->{column_info};
    $ci = $ci->{$_[1]} || die $_[0]->_dmsg_(5, $_[1]) if @_ > 1;
    $ci;
}

sub column_infos {
    my $g = shift->_global_;
    [@{$g->{column_info}}{@{$g->{columns} || []}}];
}

sub column_label {
    my $ci = shift->column_info($_[0]);
    defined $ci->{-l} ? $ci->{-l} : die qq{No label(-l) defined on "$_[0]"};
}

sub constraints { shift->_global_->{constraints} }

sub count {
    die $_[0]->_dmsg_(1) if ref $_[0];
    shift->search(shift, {select => 'COUNT(*)'})->[0]->get_column('COUNT(*)');
}

sub delete_by_sql {
    die $_[0]->_dmsg_(1) if ref $_[0];
    my $n = $_[0]->storage->delete_by_sql(@_);
    my $sc = $_[0]->_schema_cache_;
    undef %$sc if $sc;
    $n;
}

sub _dmsg_ {
    my $self = shift;
    my $cd = shift || die;
    (caller(1))[3] =~ /([0-9A-Za-z_]+)\z/;
    $cd eq 1 ? qq{Can't call class method "$1" via $self} :
    $cd eq 2 ? qq{Can't call instance method "$1" via $self} :
    $cd eq 3 ? qq{Can't define $1 via instance $self} :
    $cd eq 4 ? qq{Can't define reserved method "$_[0]"} :
    $cd eq 5 ? qq{No such column "$_[0]" on }.$self->_class_ :
    $cd eq 6 ? qq{Column "$_[0]" has not loaded} :
    $cd eq 7 ? qq{No primary_key on }.$self->_class_ :
    $cd eq 8 ? qq{Can't omit join condition for $self->$_[0]} :
    $cd eq 9 ? qq{No such relationship "$_[0]" on }.$self->_class_ :
    die "$cd?";
}

sub find {
    die $_[0]->_dmsg_(1) if ref $_[0];
    my($sch, $cnd, $opt) = @_;
    return undef if !defined $cnd;
    
    return $sch->_find_by_hash_($cnd, $opt) if UNIVERSAL::isa($cnd, 'HASH');
    $cnd = [$cnd] if !ref $cnd;
    
    my $pk = $sch->primary_key || die $sch->_dmsg_(7);
    return undef if @$cnd != @$pk;
    defined $_ || return undef for @$cnd;
    
    my($sc, $k);
    if((!$opt || !%$opt) && ($sc = $sch->_schema_cache_) && exists $sc->{$k = join "\0", @$cnd}){
        $sch->project->debug_with_trace(sprintf '%s->schema_cache->{%s}{%s}{%s} => %s',
            $sch->project, $sch->SCHEMA_BASE, $sch->_schema_name_,
            join('\0', @$cnd), $sc->{$k} || 'undef'
        ) if $::ENV{FLAPP_DEBUG};
        return $sc->{$k};
    }
    
    my $row = $sch->search([join(' AND ', map{ "$_ = ?" } @$pk), @$cnd], $opt)->[0];
    $sc ? ($sc->{$k} = $row) : $row;
}

sub _find_by_hash_ {
    my($sch, $cnd, $opt, $find_or_new) = @_;
    return undef if !%$cnd;
    
    my $pk = $sch->primary_key || die $sch->_dmsg_(7);
    if(keys %$cnd == @$pk){
        my @cnd;
        exists $cnd->{$_} ? push(@cnd, $cnd->{$_}) : last for @$pk;
        return $sch->find(\@cnd, $opt) if @cnd == @$pk;
    }
    
    my $rs = $sch->search($cnd, {rows => 2, %{$opt || {}}});
    return $rs->[0] if @$rs <= 1;
    
    my $msg = 'Found '.@$rs.' rows on '.$sch->dump([$cnd, $opt]);
    $find_or_new ? die $msg : warn $msg;
    undef;
}

sub find_by_pk {
    die $_[0]->_dmsg_(1) if ref $_[0];
    my($sch, $cnd, $opt) = @_;
    $cnd = [@$cnd{@{$sch->primary_key || die $sch->_dmsg_(7)}}] if UNIVERSAL::isa($cnd, 'HASH');
    $sch->find($cnd, $opt);
}

sub find_or_new {
    die $_[0]->_dmsg_(1) if ref $_[0];
    my($sch, $cnd, $opt) = @_;
    
    !defined $cnd ? $sch->new :
    UNIVERSAL::isa($cnd, 'HASH') ? ($sch->_find_by_hash_($cnd, $opt, 1) || $sch->new($cnd)) :
    ($sch->find($cnd, $opt) || $sch->new(do{
        my $pk = $sch->primary_key || die $sch->_dmsg_(7);
        !ref $cnd ? {$pk->[0] => $cnd} : {map{ $pk->[$_] => $cnd->[$_] } 0 .. $#$pk}
    }));
}

sub indexes { shift->_global_->{indexes} }

sub instantiate { shift->_new_({-org => shift}) }

sub _merge_options_ {
    my $self = shift;
    my $opt = {%{+shift}};
    if(my $h = shift){
        exists $opt->{$_} ? ($opt->{$_} = $h->{$_}) : die qq{Invalid option: "$_"} for keys %$h;
    }
    ref $opt->{$_} eq 'CODE' && ($opt->{$_} = $opt->{$_}->($self)) for keys %$opt;
    $opt;
}

sub new {
    die $_[0]->_dmsg_(1) if ref $_[0];
    my $row = shift->_new_({});
    my $h = shift;
    my $cih = $row->column_info;
    my @d;
    foreach my $cn (@{$row->columns}){
        next if $h && exists $h->{$cn} && $row->set_column($cn, $h->{$cn});
        my $ci = $cih->{$cn};
        push @d, $ci if exists $ci->{-d};
    }
    
    $h = $row->{-txn};
    my $now;
    foreach(@{$row->SET_CURRENT_TIME_ON_NEW}){
        next if !$cih->{$_} || $h && exists $h->{$_};
        $row->set_column($_, ($now ||= $row->project->now)->clone);
    }
    
    !exists $h->{$_->{name}} && $row->set_column($_->{name},
        ref $_->{-d} eq 'CODE' ? $_->{-d}->($row, $_->{name}) : $_->{-d}) for @d;
    
    $row;
}

sub primary_key {
    my $self = shift;
    my $g = $self->_global_;
    return $g->{primary_key} if !@_;
    die $self->_dmsg_(3) if ref $self;
    (my @pk = @{+shift}) || die 'No columns';
    my $i;
    $self->column_info($_)->{pk} = ++$i for @pk;
    $g->{primary_key} = \@pk;
    $self;
}

sub _schema_cache_ {
    my $self = shift;
    my $sc = $self->project->schema_cache;
    $sc && ($sc = $sc->{$self->SCHEMA_BASE}) && $sc->{$self->_schema_name_};
}

sub _schema_name_ { substr($_[0]->_class_, length($_[0]->SCHEMA_BASE) + 2) }

sub _schema_names_ {
    $_[0]->SCHEMA_BASE->_global_->{schema_names} ||= do{
        my $base = shift->SCHEMA_BASE;
        (my $pm = "$base.pm") =~ s%::%/%g;
        $::INC{$pm} =~ /^(.+)\.pm\z/ || die $::INC{$pm};
        my $ls = $base->OS->ls($1) || die "$!($1)";
        [map{ /^(.+)\.pm\z/ ? $1 : () } @$ls];
    };
}

sub search {
    die $_[0]->_dmsg_(1) if ref $_[0];
    $_[0]->storage->search(@_);
}

sub storage {
    $_[0]->SCHEMA_BASE->_global_->{storage} ||= do{
        my $base = shift->SCHEMA_BASE;
        my $proj = $base->project;
        (my($db) = $base =~ /([^:]+)\z/) || die $base;
        my $dsn = $proj->config->DB->$db->dsn->[0][0];
        $dsn =~ /^dbi:([0-9A-Za-z_]+):[0-9A-Za-z_]+/ || die qq{Can't parse dsn: "$dsn"};
        $proj->Schema->Storage->$1->new($db);
    };
}

sub table {
    my $self = shift;
    my $g = $self->_global_;
    return $g->{table} if !@_;
    die $self->_dmsg_(3) if ref $self;
    $g->{table} = shift;
    $self;
}

sub table_option {
    my $self = shift;
    my $g = $self->_global_;
    return $g->{table_option} ||= {} if !@_;
    die $self->_dmsg_(3) if ref $self;
    $g->{table_option} = shift;
    $self;
}

sub truncate {
    die $_[0]->_dmsg_(1) if ref $_[0];
    my $n = $_[0]->storage->truncate(@_);
    my $sc = $_[0]->_schema_cache_;
    undef %$sc if $sc;
    $n;
}

sub txn_do { shift->storage->dbh->txn_do(@_) }

sub update_by_sql {
    die $_[0]->_dmsg_(1) if ref $_[0];
    my $n = $_[0]->storage->update_by_sql(@_);
    my $sc = $_[0]->_schema_cache_;
    undef %$sc if $sc;
    $n;
}

1;

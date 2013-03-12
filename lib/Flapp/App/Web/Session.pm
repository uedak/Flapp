package Flapp::App::Web::Session;
use Flapp qw/-b Flapp::Object -m -r -s -w/;
use Digest::MD5;

use constant DEFAULT_CONFIG => {
    key => '.sid',
    state => {Cookie => {}, Url => {}},
    store => {File => {}},
};

sub cleanup {
    my $self = shift;
    return $self if !$self->id;
    $self->store->cleanup($self);
    $self->{id} = undef;
    delete $self->{$_} for qw/got _stash txn/;
    $self;
}

sub context { shift->{context} || die 'No context' }
*c = \&context;

sub ensure_id {
    my $self = shift;
    $self->id || ($self->{id} = $self->generate_id);
}

sub finalize {
    my $self = shift;
    my $s = $self->{txn} && $self->{_stash};
    $self->ensure_id if $s;
    $self->state->finalize($self) if $self->id;
    return !1 if !$s;
    %$s ? $self->store->finalize($self, $s) : $self->store->cleanup($self);
    1;
}

sub generate_id {
    my $t = time;
    sprintf('%x', $t).Digest::MD5::md5_hex(rand().$$.{}.$t);
}

sub get {
    my $self = shift;
    return $self->{got}{$_[0]} if exists $self->{got}{$_[0]};
    my $g = $self->_stash->{$_[0]};
    $g = Storable::dclone($g) if ref $g && (require Storable);
    $self->{got}{$_[0]} = $g;
}

sub id {
    my $self = shift;
    if(@_){
        $self->{id} = shift;
        return $self;
    }
    return $self->{id} if exists $self->{id};
    my $id = $self->state->load_sid($self);
    $id = undef if !$id || !$self->is_valid_sid($id);
    $self->{id} = $id;
}

sub is_valid_sid { defined $_[1] && $_[1] =~ /\A[0-9a-f]{40}\Z/ }

sub key { shift->{key} || die 'No session key' }

sub new {
    my $self = shift->_new_({});
    $self->_weaken_($self->{context} = my $c = shift);
    
    my $cfg = $c->app_config->{session} || {};
    my $def = $self->DEFAULT_CONFIG;
    $self->{key} = $cfg->{key} || $def->{key} || die 'No session key';
    $self->state($cfg->{state} || $def->{state});
    $self->store($cfg->{store} || $def->{store});
    $self;
}

sub remove {
    my $self = shift;
    $self->{txn} = 1;
    delete $self->{got}{$_[0]};
    delete $self->_stash->{$_[0]};
    $self;
}

sub set {
    my $self = shift;
    $self->{txn} = 1;
    $self->{got}{$_[0]} = $self->_stash->{$_[0]} = $_[1];
    $self;
}

sub _stash {
    my $self = shift;
    $self->{_stash} ||= $self->id ? $self->store->load($self) : {};
}

sub state {
    my $self = shift;
    return $self->{state} || die if !@_;
    my $cfg = shift;
    my $st = $cfg->{Cookie} && $cfg->{Url} ? ($self->c->ua->cookie_enabled ? 'Cookie' : 'Url') :
        $cfg->{Cookie} ? 'Cookie' :
        $cfg->{Url} ? 'Url' : 
        die "Can't specify session state";
    
    $self->{state} = $self->State->$st->new($cfg->{$st}, $self);
}

sub store {
    my $self = shift;
    return $self->{store} || die if !@_;
    my $cfg = shift;
    my $st = $cfg->{File} ? 'File' : $cfg->{DB} ? 'DB' :  die "Can't specify session store";
    
    $self->{store} = $self->Store->$st->new($cfg->{$st}, $self);
}

1;

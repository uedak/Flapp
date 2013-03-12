package Flapp::App::Web::Session::Store::DB;
use Flapp qw/-b Flapp::App::Web::Session::Store -m -s -w/;
use Encode;
use Storable;

sub cleanup {
    my($self, $ses) = @_;
    my $r = $self->row($ses);
    $r->storage->dbh->no_txn_log_do(sub{
        $r->_class_->delete_by_sql({id => $ses->id})
    }) if $r->in_storage;
}

sub finalize {
    my($self, $ses, $stash) = @_;
    my $r = $self->row($ses)->data(Storable::freeze($stash));
    $r->storage->dbh->no_txn_log_do(sub{ eval{ $r->save } || do{
        my $msg = $@;
        my $x = $r->_class_->find($r->id, {select => [qw/data/]});
        die $msg if !$x || $x->data($r->data)->is_column_changed('data');
    } });
}

sub load {
    my($self, $ses) = @_;
    my $r = $self->row($ses);
    Encode::_utf8_off(my $data = $r->data);
    $r->in_storage ? Storable::thaw($data) : {};
}

sub row {
    my($self, $ses) = @_;
    $self->{row}{$ses->id || die} ||= $self->schema($ses->c)
        ->find_or_new($ses->id)
        ->access_at($ses->c->project->now);
}

sub schema {
    my($self, $c) = @_;
    my $schema = $self->{schema};
    $c->project->schema($self->{db})->$schema;
}

sub sweep {
    my($self, $c) = @_;
    $self->schema($c)->delete_by_sql(['access_at <= ?', $c->project->now - $c->SESSION_EXPIRE]);
}

1;

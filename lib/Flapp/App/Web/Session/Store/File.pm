package Flapp::App::Web::Session::Store::File;
use Flapp qw/-b Flapp::App::Web::Session::Store -m -s -w/;
use Storable;

sub cleanup { unlink shift->path(@_) }

sub finalize {
    my($self, $ses, $stash) = @_;
    Storable::lock_nstore $stash => $self->path($ses);
}

sub load {
    my($self, $ses) = @_;
    my $f = $self->path($ses);
    -f $f ? Storable::lock_retrieve $f : {};
}

sub path {
    my($self, $ses) = @_;
    $ses->c->session_dir.'/'.$ses->id.'.ses';
}

sub sweep {
    my($self, $c) = @_;
    my $dir = $c->session_dir;
    -d $dir && $c->OS->unlink_expired($dir, $c->project->now->epoch - 60 * 60 * 24);
}

1;

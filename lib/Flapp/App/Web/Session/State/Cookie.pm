package Flapp::App::Web::Session::State::Cookie;
use Flapp qw/-b Flapp::App::Web::Session::State -m -s -w/;

sub finalize {
    my($self, $ses) = @_;
    my %cok = (value => $ses->id);
    $cok{path} = $self->{path} || '/';
    defined $self->{$_} && ($cok{$_} = $self->{$_}) for qw/domain httponly secure/;
    $ses->c->res->cookies->{$ses->key} = \%cok;
}

sub load_sid {
    my($self, $ses) = @_;
    my $sid = $ses->c->req->cookies->{$ses->key};
    ref $sid ? $sid->value : $sid; # for old Plack::Request
}

1;

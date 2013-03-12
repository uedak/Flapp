use Flapp qw/-m -s -w/;

sub {
    my $c = shift;
    my $p = $c->req->body_params;
    
    (exists $p->{$_[0]} || exists $p->{"$_[0].x"} && exists $p->{"$_[0].y"})
     && $c->req->method eq 'POST'
     && $p->{'.csrf_token'}
     && $p->{'.csrf_token'} eq $c->csrf_token;
};

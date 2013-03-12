use Flapp qw/-m -s -w/;

sub{
    my $c = shift;
    my $prt = @_ ? shift : $c->req->secure ? 'https' : 'http';
    $c->_global_->{static_root}{$prt} ||= do{
        my $cfg = $c->app_config;
        my $sr = $cfg->static_root->$prt;
        if(my $rev = $cfg->{static_root_rev}){
            $sr .= '_'.($c->project->_global_->{static_root_rev}{$_} ||= $c->Util->i2a(
                (stat "$_/$rev")[9] || ($c->debug ? 1 : die "$!($_/$rev)")
            )) for @{$c->static_roots};
        }
        $sr;
    };
};

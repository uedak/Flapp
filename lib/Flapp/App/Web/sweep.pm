use Flapp qw/-m -s -w/;

sub{
    my($c, $cc) = @_;
    
    my $cnt = $c->new({})->session->store->sweep($c, $cc);
    $cc->log($c->app_name." remove sessions: $cnt") if $cnt;
    
    if(-d (my $dir = $c->upload_dir)){
        my $cnt = $c->OS->unlink_expired($dir, $c->project->now->epoch - 60 * 60 * 24);
        $cc->log($c->app_name." remove uploads: $cnt") if $cnt;
    }
};

use MyProject qw/-m -s -w/;

sub{
    my($self, $cfg) = @_;
    my $tmp = $self->project_root.'/tmp';
    
    $cfg->{log_dir} = "$tmp/log";
    $cfg->{DB} = {
        Default => {
            allow_from => [qw/localhost %/],
            dsn => [
                ['dbi:mysql:MyProjectTest;host=localhost', 'root', '', {}],
            ],
        },
    };
    $cfg->{Mailer}{filter} = undef;
    $cfg->{Mailer}{spool_dir} = "$tmp/mail";
    $cfg;
}

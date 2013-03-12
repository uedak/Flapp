use MyProject qw/-m -s -w/;

sub{
    my($self, $cfg) = @_;
    $cfg->{DB} = {
        Default => {
            allow_from => [qw/%/],
            dsn => [
                ['dbi:mysql:MyProject;host=127.0.0.1', 'root', '', {}],
            ],
        },
    };
    $cfg->{Mailer}{filter} = undef;
    $cfg->{Mailer}{spool_dir} = $self->project_root.'/tmp/mail';
    $cfg;
}

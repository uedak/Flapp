use MyProject qw/-m -s -w/;

sub{
    my($self, $cfg) = @_;
    $cfg->{DB} = {
        Default => {
            allow_from => [qw/localhost %/],
            dsn => [
                ['dbi:mysql:MyProject;host=localhost', 'root', '', {}],
            ],
        },
    };
    $cfg->{Mailer}{filter} = undef;
    $cfg->{Mailer}{spool_dir} = $self->project_root.'/tmp/mail';
    $cfg;
}

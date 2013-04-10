use MyProject qw/-m -s -w/;

sub{
    my($self, $cfg) = @_;
    
    my %db_attr;
    $db_attr{mysql_enable_utf8} = 1 if $Flapp::UTF8;
    $cfg->{DB} = {
        Default => {
            allow_from => [qw/localhost %/],
            dsn => [
                ['dbi:mysql:MyProject;host=localhost', 'root', '', \%db_attr],
            ],
        },
    };
    $cfg->{Mailer}{filter} = undef;
    $cfg->{Mailer}{spool_dir} = $self->project_root.'/tmp/mail';
    $cfg;
}

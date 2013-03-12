use MyProject qw/-m -s -w/;

sub{
    my $self = shift;
    my $cfg = {
        log_dir => $self->project_root.'/log',
        Mailer => {sendmail => '/usr/lib/sendmail'},
        App => {
            Cmd => {
                allow_db_truncate => 1,
            },
            Web => {
                static_root => {
                    http  => '/static',
                    https => '/static',
                },
                #static_root_rev => '.svn',
            },
        },
        apps => {},
    };
    $cfg;
}

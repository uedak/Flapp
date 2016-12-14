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
    my $m = $cfg->{Mailer} ||= {};
    $m->{filter} = undef;
    $m->{spool_dir} = $self->project_root.'/tmp/mail';
    #$m->{sendmail} = '/usr/lib/sendmail';
    #$m->{smtp} = ['localhost'];
    
    $cfg;
}

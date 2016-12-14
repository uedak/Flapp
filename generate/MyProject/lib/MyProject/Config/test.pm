use MyProject qw/-m -s -w/;

sub{
    my($self, $cfg) = @_;
    my $tmp = $self->project_root.'/tmp';
    
    my %db_attr;
    $db_attr{mysql_enable_utf8} = 1 if $Flapp::UTF8;
    $cfg->{DB} = {
        Default => {
            allow_from => [qw/localhost %/],
            dsn => [
                ['dbi:mysql:MyProjectTest;host=localhost', 'root', '', \%db_attr],
            ],
        },
    };
    my $m = $cfg->{Mailer} ||= {};
    $m->{filter} = undef;
    $m->{spool_dir} = "$tmp/mail";
    
    $cfg->{log_dir} = "$tmp/log";
    
    $cfg;
}

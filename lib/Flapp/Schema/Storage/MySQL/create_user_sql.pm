use Flapp qw/-m -s -w/;

sub{
    my $self = shift;
    my $dbn = $self->dbname;
    my $un = $self->user;
    my $pw = $self->password;
    $pw = " IDENTIFIED BY '$pw'" if $pw ne '';
    
    my $sql = '';
    foreach(@{$self->config->allow_from}){
        $sql .= "GRANT ALL PRIVILEGES ON $dbn.* TO '$un'\@'$_'$pw WITH GRANT OPTION;\n";
    }
    $sql;
};

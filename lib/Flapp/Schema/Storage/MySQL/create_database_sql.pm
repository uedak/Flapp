use Flapp qw/-m -s -w/;

sub{
    my $dbn = shift->dbname;
    "CREATE DATABASE $dbn DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;\n";
};

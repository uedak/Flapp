use Flapp qw/-m -s -w/;

my $n;
sub{
    my($util, $char) = (shift, shift || '-');
    $n ||= (-f '/usr/bin/tput' && $util->OS->qx('tput cols') =~ /([0-9]+)/ && $1) || 80;
    ($char x $n)."\n";
};

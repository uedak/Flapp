use Flapp qw/-m -s -w/;

sub{ CORE::symlink $_[0]->ensure_path($_[1]), $_[0]->ensure_path($_[2]) };

use Flapp qw/-m -s -w/;

sub{ CORE::rmdir(shift->ensure_path(shift)) };

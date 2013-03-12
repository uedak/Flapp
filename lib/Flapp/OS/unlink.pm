use Flapp qw/-m -s -w/;

sub{ CORE::unlink(shift->ensure_path(shift)) };

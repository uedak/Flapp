use Flapp qw/-m -s -w/;

sub{ CORE::chdir(shift->ensure_path(@_)) };

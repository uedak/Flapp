use Flapp qw/-m -s -w/;

sub{ CORE::mkdir(shift->ensure_path(shift), @_ ? shift : 0777 - umask) };

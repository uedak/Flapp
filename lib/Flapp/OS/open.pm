use Flapp qw/-m -s -w/;

sub{
    my $os = shift;
    my($op, $enc) = $_[1] =~ /^(<|>>?)(:[0-9A-Za-z\(\)\-]+)?\z/ && splice(@_, 1, 1) ? ($1, $2) : ('', '');
    $enc = ':utf8' if !$enc && $Flapp::UTF8;
    my $path = $os->ensure_path_or_safecmd(@_[1 .. $#_]);
    local $::ENV{PATH} = $::ENV{PATH} =~ /(.+)/ && $1 if $os->in_taint_mode;
    my $st = CORE::open($_[0], $op.$path);
    binmode $_[0], $enc if $st && $enc && $enc ne ':raw';
    $st;
};

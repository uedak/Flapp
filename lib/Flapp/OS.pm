package Flapp::OS;
use Flapp qw/-b Flapp::Object -m -r -s -w/;
our $IN_TAINT_MODE;

sub in_taint_mode {
    $IN_TAINT_MODE = !eval{ ``; 1; } || 0 if !defined $IN_TAINT_MODE;
    $IN_TAINT_MODE;
}

sub is_eml { shift->project->Validator->is_eml(@_) }

sub is_path {
    defined($_[1]) && index($_[1], '..') < 0 && index($_[1], '//') < 0 && $_[1] =~ m%^
        (?:[A-Z]:)? #Drive Letter
        [./0-9A-Za-z_] #No first '-'
        (?:[\-./0-9A-Za-z_]*(?:[/0-9A-Za-z_]|@[\-\.0-9A-Za-z]+\.log))?
    \z%x && 1;
}

1;

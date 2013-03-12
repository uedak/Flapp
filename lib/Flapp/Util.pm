package Flapp::Util;
use Flapp qw/-b Flapp::Object -m -r -s -w/;

our $DUMP_INDENT;

our $TSV_ESC = do{
    my %esc = ("\t" => '\\t', "\n" => '\\n', "\r" => '\\r', '"' => '\\"', '\\' => '\\\\');
    +{%esc, reverse %esc};
};

1;

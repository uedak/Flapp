package Flapp::Template::Directive::Process;
use Flapp qw/-b Flapp::Template::Directive -s -w/;

sub begin {
    my($dtv, $doc, $ft) = @_;
    my $v = $dtv->{code}->($doc);
    my($_doc, $_dtv) = $v && ref($v) eq 'ARRAY' ? @$v : ();
    die 'No BLOCK' if ref $_doc ne $ft->Document;
    
    my $block = {};
    if(my $dl = $dtv->{local}){
        $block->{local}{$_} = $dl->{$_}->($doc) for keys %$dl;
    }
    
    $_doc = $_doc->clone;
    $_doc->{block} = [];
    $_doc->{tmp} = {};
    push @{$ft->{doc}}, $_doc;
    $_doc->{idx} = $_doc->block($_dtv, $block);
    $dtv->{id};
}

sub parse { shift->_parse_include(@_) }

1;

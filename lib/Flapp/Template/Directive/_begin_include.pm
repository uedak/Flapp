use Flapp qw/-m -s -w/;

sub {
    my($dtv, $doc, $ft) = @_;
    my $src = $dtv->{code}->($doc) || die 'No src';
    $doc->rel2abs(\$src) if substr($src, 0, 1) ne '/';
    my $_doc = $doc->{tmp}{$dtv->{id}}{$src} ||= $ft->parser->create_document($ft->locate($src));
    $_doc = $_doc->clone->init($ft);
    if(my $dl = $dtv->{local}){
        $_doc->{my}{$_} = $dl->{$_}->($doc) for keys %$dl;
    }
    push @{$ft->{doc}}, $_doc;
    $dtv->{id};
};

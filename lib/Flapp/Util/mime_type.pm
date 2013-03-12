use Flapp qw/-m -s -w/;
(my $M = eval{ require Plack::MIME } && $Plack::MIME::MIME_TYPES)
 || warn 'No $Plack::MIME::MIME_TYPES';

sub{
    my $util = shift;
    my $r = ref $_[0] ? shift : do{ \(my $s = shift) };
    #if(my $m = $os->qx('file -bi %path', $$r)){
    #    $m =~ tr/\n\r//d;
    #    return $m;
    #}
    $M && $$r =~ /(\.[0-9a-z]+)\z/ && $M->{$1} || undef;
};

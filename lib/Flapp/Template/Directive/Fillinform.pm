package Flapp::Template::Directive::Fillinform;
use Flapp qw/-b Flapp::Template::Directive -s -w/;
use constant HAS_END => 1;

sub begin {
    my($dtv, $doc, $ft) = @_;
    my $p = $dtv->{code}->($doc) || die 'No data for [% FILLINFORM %]';
    my %opt;
    if(my $dl = $dtv->{local}){
        $opt{$_} = $dl->{$_}->($doc) for keys %$dl;
    }
    
    push @{$ft->{tmp}{Fillinform} ||= []}, [$p, \%opt, 0];
    push @{$ft->{buf}}, \(my $buf = '');
    
    $dtv->{id} + 1
}

my $begin = "<\0FILLINFORM\0>";
my $bl = length $begin;
my $end = "<\0/FILLINFORM\0>";
my $el = length $end;

sub end {
    my($dtv, $doc, $ft) = @_;
    my $tmp = $ft->{tmp}{Fillinform} || die;
    my($p, $opt, $nest) = @{pop @$tmp || die};
    my $buf = pop @{$ft->{buf}};
    
    ++$tmp->[-1][2] && $ft->write($begin) if @$tmp;
    my $i = 0;
    while(--$nest >= 0){
        die if (my $j = index($$buf, $begin, $i)) < 0;
        my $s = substr($$buf, $i, $j - $i);
        $ft->context->fillinform(\$s, $p, $opt) if $s ne '' && %$p;
        $ft->write($s);
        die if ($i = index($$buf, $end, $j += $bl)) < 0;
        $ft->write(substr($$buf, $j, $i - $j));
        $i += $el;
    }
    substr($$buf, 0, $i) = '' if $i;
    $ft->context->fillinform($buf, $p, $opt) if $$buf ne '' && %$p;
    $ft->write($$buf);
    $ft->write($end) if @$tmp;
    
    $dtv->{id} + 1
}

sub parse { shift->_parse_include(@_) }

1;

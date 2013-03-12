package Flapp::Template::Directive;
use Flapp qw/-b Flapp::Object -m -r -s -w/;
use constant BELONGS_TO => undef;
use constant HAS_END => 0;

sub begin { $_[0]->{id} + 1 }

sub chain {
    my($dtv, $b2, $end) = @_;
    
    foreach(@$b2, $end){
        ($dtv->{next_id}, $_->{prev_id}) = ($_->{id}, $dtv->{id});
        $dtv = $_;
    }
}

sub end { $_[0]->{id} + 1 }

sub head { $_[0]->{src} =~ /^[\t ]*([^\t\n\r \w]+)[\t\n\r ]*([^\t\n\r ]+)/ && "$1 $2 " }

sub ln { $_[0]->{ln} ||= $_[0]->_ln($_[1], $_[0]->{id} - 1) }

sub _ln {
    my($self, $body, $id) = @_;
    $id = $#$body if !defined $id;
    my $ln = 0;
    for(my $i = $id; $i >= 0; $i--){
        my $r = $body->[$i];
        my $dtv = ref($r) ne 'SCALAR' && $r;
        $r = \($r->{src}) if $dtv;
        $ln++ while $$r =~ /\r\n?|\n/g;
        return $dtv->ln($body) + $ln if $dtv;
    }
    $ln + 1;
}

sub name {
    my $n = $_[0]->_class_;
    uc(substr($n, rindex($n, '::') + 2));
}

sub new {
    my($class, $d, $sr, $p) = @_;
    my $dtv = bless $d, $class;
    
    if($dtv->HAS_END){
        push @{$p->{stack}}, [$dtv];
    }elsif(my $b2 = $dtv->BELONGS_TO){
        my $s = $p->{stack}[-1];
        $p->raise(qq{No directive "$b2"}, $dtv) if !$s->[0] || $s->[0]->name ne $b2;
        push @$s, $dtv;
    }
    
    $p->error(undef);
    $dtv->parse($sr, $p) && $$sr =~ /^[\t\n\r ]*(?:#.*)?\z/ || $p->raise(
        $p->error || ('Syntax error'.($$sr ne '' && " near `$$sr`")),
        $dtv,
    );
    $dtv;
}

sub parse { $_[0]->{code} = $_[2]->compile($_[1]) }

1;

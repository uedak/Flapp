package Flapp::Validator;
use Flapp qw/-b Flapp::Object -m -s -w/;

sub is_eml {
    my($self, $eml) = @_;
    defined $eml && $eml =~ m%^[0-9A-Za-z_\-][\+\-./0-9A-Za-z_^\?]*\@([0-9a-z\-]+\.)+[a-z]{2,}\z%;
}

sub chr {
    my($self, $vr, $opt) = @_;
    die 'No option' if !defined $opt || $opt eq '';
    return if !defined $$vr || $$vr eq '';
    
    my @opt;
    push @opt, [$1, $2] while $opt =~ s/([\+\-])([0-9A-Za-z_]+)\z//;
    push @opt, ['+', $opt] if $opt ne '';
    $_->[2] = $self->_global_->{chr}{$_->[1]} ||= $self->_chr($_->[1]) for @opt;
    
    my(%chr, @chr);
    $self->Util->each_chr_do($vr, sub{
        my $ng = $opt[0]->[0] eq '+';
        foreach(@opt){
            if(exists $_->[2]{$_[0]}){
                return 1 if $_->[0] eq '+';
                $ng = 1;
                last;# if $_->[0] eq '-';
            }
        }
        return 1 if !$ng;
        push @chr, $_[0] if !$chr{$_[0]}++;
        @chr <= 3;
    }, {force => 1, stop_if_false => 1});
    return if !@chr;
    
    $self->project->Errors->_found_invalid_characters(\@chr);
}

sub _chr {
    my($self, $chrs) = @_;
    return {"\n" => 1} if $chrs eq 'LF';
    my $txt = $self->_search_inc_by_method_('chr', "chr/$chrs.txt") || die qq{No "$chrs.txt"};
    my $util = $self->Util;
    my %chrs;
    $self->OS->open(my $H, $txt) || die "$!($txt)";
    local $/ = "\n";
    while(my $line = <$H>){
        chomp $line;
        $util->each_chr_do(\$line, sub{ $chrs{$_[0]} = 1 });
    }
    close($H);
    \%chrs;
}

sub date {
    my($self, $vr, $opt) = @_;
    my $d;
    return if !defined $$vr || $$vr eq '' || ($d = $self->project->Date->parse($$vr)) && $d->is_valid;
    102;
}

sub eml {
    my($self, $vr, $opt) = @_;
    return if !defined $$vr || $$vr eq '' || $self->is_eml($$vr);
    103;
}

sub enum {
    my($self, $vr, $opt) = @_;
    $vr = $$vr if ref $vr eq 'SCALAR';
    (my @cd = $self->Util->cd2str($vr, $opt, {validate => 1})) || return;
    @cd = (@cd[0, 1, 2], '...') if @cd > 3;
    [104, join(', ', @cd)];
}

sub hms {
    my($self, $vr, $opt) = @_;
    return if !defined $$vr || $$vr eq '' || (
        $$vr =~ /^([0-9]{2})([0-9]{2})([0-9]{2})\z/
     && $self->project->Time->new("2001-01-01T$1:$2:$3+0000")->is_valid
    );
    105;
}

sub int {
    my($self, $vr) = @_;
    return if !defined $$vr || $$vr eq '' || $$vr =~ /^-?[0-9]+\z/;
    106;
}

sub nn {
    my($self, $vr, $opt) = @_;
    return if ref $vr ne 'SCALAR';
    return 107 if !defined $$vr || $$vr eq '';
    my $ws = $self->project->Errors->WHITESPACE;
    return if !$self->Util->each_chr_do($vr, sub{ exists $ws->{$_[0]} },
        {force => 1, stop_if_false => 1});
    107;
}

sub range {
    my($self, $vr, $opt) = @_;
    my($min, $x, $max) = ($opt =~ /^([\+\-]?[0-9]+(?:\.[0-9]+)?)?(<=)([\+\-]?[0-9]+(?:\.[0-9]+)?)?\z/);
    die qq{Invalid option "$opt"} if !$x;
    return if !defined $$vr || $$vr eq '';
    $$vr !~ /^[\+\-]?[0-9]+(?:\.[0-9]+)?\z/ ? 108 :
    defined $min && $$vr < $min ? [109, $min] :
    defined $max && $$vr > $max ? [110, $max] :
    return;
}

sub sel {
    my($self, $vr) = @_;
    return 111 if(
        ref $vr eq 'SCALAR' ? !defined $$vr || $$vr eq '' :
        ref $vr eq 'ARRAY'  ? !@$vr :
        die 'Invalid ref: '.$self->dump($vr)
    );
    return;
}

sub size {
    my($self, $vr, $opt) = @_;
    my($min, $x, $max) = $opt =~ /^([0-9]+)\z/ ? ($1, '=') : ($opt =~ /^([0-9]+)?(<=)([0-9]+)?\z/);
    die qq{Invalid option "$opt"} if !$x;
    return if !defined $$vr || $$vr eq '';
    my $s = 0;
    $self->Util->each_chr_do($vr, sub{ ++$s }, {force => 1}) if defined $$vr;
    if($x eq '='){
        return [112, $min] if $s != $min;
    }else{
        return [113, $min] if defined $min && $s < $min;
        return [114, $max] if defined $max && $s > $max
    }
    return;
}

sub tel {
    my($self, $vr) = @_;
    return if !defined $$vr || $$vr eq '' || $$vr =~ /^[0-9]{2,6}\-[0-9]{1,5}\-[0-9]{3,4}\z/;
    115;
}

sub time {
    my($self, $vr, $opt) = @_;
    my $t;
    return if !defined $$vr || $$vr eq '' || ($t = $self->project->Time->parse($$vr)) && $t->is_valid;
    116;
}

sub url {
    my($self, $vr) = @_;
    return if !defined $$vr || $$vr eq '';
    $$vr =~ m%^https?://[^?=&#]+(?:\?[^?#]*)?(?:#[^?#]*)?\z% ? $self->chr($vr, 'url') :
    117;
}

sub ymd {
    my($self, $vr) = @_;
    return if !defined $$vr || $$vr eq '' || (
        $$vr =~ /^([0-9]{4})([0-9]{2})([0-9]{2})\z/
     && $self->project->Date->new("$1-$2-$3")->is_valid
    );
    102;
}

sub zip {
    my($self, $vr) = @_;
    return if !defined $$vr || $$vr eq '' || $$vr =~ /^[0-9]{3}\-[0-9]{4}\z/;
    118;
}

1;

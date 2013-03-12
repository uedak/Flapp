package Flapp::Template;
use Flapp qw/-b Flapp::Object -m -r -s -w/;
use constant INIT_OPTIONS => [qw/auto_filter context stash/];
__PACKAGE__->_mk_accessors_(qw/filter_output parser/);

sub INTERPOLATE_TRACE {
    my($self, $sig, $r) = @_;
    my $at = '';
    foreach my $doc (reverse @{$self->{doc}}){
        my $dtv = $doc->{body}[$doc->{idx}];
        $at .= "\n at ".$dtv->head.'('.$doc->path.' '.$dtv->ln($doc->{body}).')';
    }
    $$r =~ s/(\n at .+?::Template::process\(.+)/$at$1/;
}

sub close {
    my $self = shift;
    $_->init for @{$self->{doc} || []};
    %$self = (parser => $self->{parser}, doc => [$self->{doc}[0]], eof => 1);
    1;
}

sub context { shift->{context} || die 'No context' }

sub getline {
    my $self = shift;
    return if $self->{eof};
    my $b0 = $self->{buf}[0];
    my $i;
    
    if(ref $/){
        $self->process if $$b0 eq '';
        $i = length($$b0);
        $i = ${$/} if $i > ${$/};
    }elsif(defined $/){
        local $/ = "\n\n" if $/ eq '';
        1 while ($i = index($$b0, $/)) < 0 && $self->process;
        $i = $i >= 0 ? $i + length($/) : length($$b0);
    }else{
        $self->process;
        $i = length($$b0);
    }
    
    my $ln = substr($$b0, 0, $i);
    substr($$b0, 0, $i) = '';
    $self->{filter_output}->($ln) if $self->{filter_output};
    Encode::_utf8_off($ln) if $Flapp::UTF8;
    $ln;
}

sub init {
    my($self, $opt) = @_;
    if($opt){
        $self->{$_} = $opt->{$_} for @{$self->INIT_OPTIONS};
    }
    delete $self->{eof};
    $self->{buf} = [\(my $buf = '')];
    $self->{our} = {};
    $self->{doc} = [$self->{doc}[0]->init($self)];
    $self->{tmp} = {};
    $self;
}

sub locate {
    my $self = shift;
    my $c = $self->{context};
    return $c->locate_view($_[0], $c->ua->view_suffix) || die qq{Can't locate "$_[0]"} if $c;
    [$self->{doc}[0]{location}[0], $_[0]];
}

sub new { shift->_new_({parser => shift, doc => [shift]}) }

sub path { shift->{doc}[0]->path }

our $INPUT_RECORD_SEPARATOR = $/;
sub process {
    my $self = shift;
    die "Not initialized: $self" if !$self->{our};
    return if $self->{eof};
    my($b0, $b0l);
    $b0l = length ${$b0 = $self->{buf}[0]} if defined $/;
    my $opt = $self->project->trace_option;
    local $opt->{interpolator} = $self if $opt;
    local $/ = $INPUT_RECORD_SEPARATOR;
    
    while(1){
        my $doc = $self->{doc}[-1] || die 'No doc';
        my $e = $doc->{body}[$doc->{idx}];
        
        if(!$e){
            return $self->{eof} = 1 if @{$self->{doc}} == 1;
            (pop @{$self->{doc}})->init; #for mem leak
            $doc = $self->{doc}[-1];
            $e = $doc->{body}[$doc->{idx}];
            $e = $doc->{body}[$e->{next_id}] while $e->{next_id};
            $doc->{idx} = $e->{id} + 1;
        }elsif(ref $e eq 'SCALAR'){
            $self->write($$e);
            $doc->{idx}++;
        }else{
            $doc->{idx} = $e->begin($doc, $self);
        }
        my $block;
        $doc->block_end while ($block = $doc->{block}[-1]) && $block->{end} <= $doc->{idx};
        return 1 if $b0 && length($$b0) != $b0l;
    }
}

sub render {
    my $self = shift;
    local $self->{buf}[0] = shift if @_;
    local $/;
    eval{ $self->process };
    die $@ if $@ && $self->close;
    defined wantarray ? ${$self->{buf}[0]} : 1;
}

sub write { ${shift->{buf}[-1]} .= shift if defined $_[1] && $_[1] ne '' }

1;

package Flapp::Logger;
use Flapp qw/-b Flapp::Object -m -s -w/;
use IO::Handle;
our $DEBUG;

sub close {
    my $self = shift;
    delete($self->{H})->close if $self->{H};
    $self;
}

sub new {
    my $class = shift;
    my $proj = $class->project;
    my $self = bless {
        dir    => $proj->config->log_dir,
        suffix => "$_[0]@".$proj->hostname,
        ymd    => '',
    }, $class;
    $self->now;
    $self;
}

sub now {
    my $self = shift;
    my $now = $self->project->now;
    if($now->ymd ne $self->{ymd}){
        $self->close;
        $self->{ymd} = $now->ymd;
    }
    $now;
}

sub open {
    my $self = shift;
    my $path = $self->path;
    if(!-f $path){
        (my $dir = $path) =~ s%/[^/]+\z%% || die $path;
        $self->OS->mkdir_p($dir) if !-d $dir;
    }
    $self->OS->open($self->{H}, '>>', $path) || die "$!($path)";
    $self->{H}->autoflush;
    $self;
}

sub path { "$_[0]->{dir}/$_[0]->{ymd}_$_[0]->{suffix}.log" }

sub print {
    my $self = shift;
    $self->project->debug_with_trace(
        join(",\n", map{ $self->dump($_) } @_)."\n >> ".$self->path
    ) if $DEBUG && $::ENV{FLAPP_DEBUG};
    $self->open if !$self->{H};
    $self->{H}->print(@_);
}

sub write {
    my $self = shift;
    $self->print($self->Util->ary2tsv($self->now->hms, @_)."\n");
}

1;

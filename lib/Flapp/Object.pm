package Flapp::Object;
use Flapp::Core qw/-s -w/;
use Flapp::Core::Include;
use Cwd;
our $OVERLOAD = 1;

sub DESTROY { local $OVERLOAD; delete $Flapp::OBJECT{$_[0]} }

sub _class_ { ref $_[0] || $_[0] }

sub _code_ {
    no strict 'refs';
    *{$_[0]->_class_.'::'.$_[1]}{CODE}
}

sub _data_ { local $OVERLOAD; $Flapp::OBJECT{$_[0]} ||= {} }

sub _define_method_ {
    no strict 'refs';
    *{$_[0]->_class_.'::'.$_[1]} = $_[2];
    $_[0];
}

sub dump {
    my $self = shift;
    Flapp->Util->dump(@_ ? shift : $self);
}

sub _dump_ {
    my $self = shift;
    local $Flapp::Util::DUMP_INDENT = 1;
    Flapp->Util->dump(@_ ? shift : $self);
}

sub _global_ { $Flapp::G{ref $_[0] || $_[0]} ||= {} }

sub _isweak_ { require Scalar::Util; Scalar::Util::isweak($_[1]) }

sub _mk_accessors_ {
    my $class = shift->_class_;
    foreach(@_){
        my $k = $_;
        my $code = sub{
            return $_[0]->{$k} if @_ == 1;
            $_[0]->{$k} = $_[1];
            $_[0];
        };
        no strict 'refs';
        *{$class."::$_"} = $code;
    }
}

sub _new_ {
    my $obj = bless $_[1], ref $_[0] || $_[0];
    local $OVERLOAD;
    $Flapp::OBJECT{$obj} = undef;
    $obj;
}

sub OS { shift->project->OS }

sub project_root { $Flapp::G{$_[0]->project}->{project_root} ||= $_[0]->project->root_dir }

sub _search_inc_by_method_ {
    my($class, $method, $path) = @_;
    my $f;
    
    while(1){
        my $isa = &Flapp::Core::Include::isa_of($class, my $inc = []);
        foreach($class, reverse @$inc){
            (my $pm = "$_.pm") =~ s%::%/%g;
            $::INC{$pm} =~ m%^(.+)\.pm\z% || die $pm;
            return $f if -e ($f = "$1/$path");
        }
        $_->can($method) && ($class = $_) && next for @$isa;
        return;
    }
}

sub _symbol_ { \($Flapp::G{symbol}{$_[1]} ||= $_[1]) }

sub Util { shift->project->Util }

sub _weaken_ { require Scalar::Util; Scalar::Util::weaken($_[1]) }

1;

package Flapp::Config;
use Flapp qw/-b Flapp::Object -m -s -w/;

use constant RECURSIVE_DO_OPTIONS => {
    scalar => sub{ Internals::SvREADONLY($_[0], 1) },
    array_ref => sub{
        my($next, $ref, $path) = @_;
        $next->($ref, $path);
        Internals::SvREADONLY(@$ref, 1);
    },
    hash_ref => sub{
        my($next, $ref, $path) = @_;
        $next->($ref, $path);
        bless $ref, 'Flapp::Config::Hash';
        $Flapp::G{config_path}->{int $ref} = join('', @$path);
        #Internals::SvREADONLY(%$ref, 1);
        tie %$ref, 'Flapp::Config::Hash::Ro', $ref;
    },
    unexpected_ref => sub{ 1 },
    sort_keys => 0,
    with_path => 1,
};

sub load {
    my($pkg, $env) = @_;
    my $cfg = $pkg->can('begin') ? $pkg->Util->deep_copy($pkg->begin) : {};
    $cfg = $pkg->$env($cfg);
    $cfg = $pkg->end($cfg) if $pkg->can('end');
    $pkg->_new($cfg);
}

sub new { $_[0]->_new($_[0]->Util->deep_copy($_[1])) }

sub _new {
    my($pkg, $cfg) = @_;
    $pkg->Util->recursive_do($pkg->RECURSIVE_DO_OPTIONS, $cfg);
    $cfg;
}

sub src {
    my $pkg = shift;
    my $src = $pkg->Util->deep_copy(shift);
    $pkg->Util->recursive_do({
        scalar => sub{ Internals::SvREADONLY($_[0], 0) },
        array_ref => sub{
            my($next, $ref) = @_;
            Internals::SvREADONLY(@$ref, 0);
            $next->($ref);
        },
        hash_ref => sub{
            my($next, $ref) = @_;
            $next->($_[1] = {%$ref});
        },
        unexpected_ref => sub{ 1 },
    }, $src);
    $src;
}

package Flapp::Config::Hash;
use Flapp qw/-s -w/;

sub AUTOLOAD {
    my $h = tied %{$_[0]} || die;
    my $k = @_ > 1 ? $_[1] : do{
        no strict 'refs';
        substr(${'AUTOLOAD'}, rindex(${'AUTOLOAD'}, '::') + 2);
    };
    return $h->{$k} if exists $h->{$k};
    require Carp;
    my $path = $Flapp::G{config_path}->{int $_[0]};
    Carp::croak "No config(->$path\{$k})";
}

sub DESTROY { delete $Flapp::G{config_path}->{int $_[0]} }

sub TO_JSON { +{%{tied %{$_[0]}}} }

sub can {
    @_ == 1 ? shift->AUTOLOAD('can') :
    !ref $_[0] ? 1 : #case in [% project.config.foo. %]
    exists((tied %{$_[0]} || die)->{$_[1]});
}

package Flapp::Config::Hash::Ro;
use Flapp qw/-s -w/;
use Carp;

sub EXISTS { exists $_[0]->{$_[1]} }

sub FETCH { $_[0]->{$_[1]} }

sub FIRSTKEY { keys %{$_[0]}; each %{$_[0]} }

sub NEXTKEY { each %{$_[0]} }

sub SCALAR { scalar %{$_[0]} }

sub TIEHASH { bless {%{$_[1]}}, $_[0] }

*CLEAR = *DELETE = *STORE = *UNTIE = sub { croak 'Modification of a read-only value attempted' };

1;

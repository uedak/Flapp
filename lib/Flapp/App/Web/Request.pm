package Flapp::App::Web::Request;
use Flapp qw/-b Flapp::Object -i Plack::Request -m -r -s -w/;
use File::Temp;
use HTTP::Body;

# Hash::MultiValue problems
#
# - Can't filter_input recursive by inside-out.
# - Hash-ref blessed object should not be used while hash-ref interface updating is wrong.
# - For perceiving, "ARRAY(0xXXXXXXXXX)" is better than the last value.
#
# So, use Flapp::App::Web::Request::MultiValueHash for compatibility.

our $FILE_TMP_NEW = \&File::Temp::new;
our $FILE_TMP_NEW_WITH_VALID_SUFFIX = sub{
    my $i = 1;
    while($i < $#_){
        ($i += 2) && next if $_[$i] ne 'SUFFIX';
        splice @_, $i, 2 if $_[$i + 1] !~ /^(\.[0-9A-Za-z]+)+\z/;
        last;
    }
    $FILE_TMP_NEW->(@_);
};
our $HTTP_BODY_NEW = \&HTTP::Body::new;
our $HTTP_BODY = sub{
    my($sub, $self) = (shift, shift);
    return $sub->($self, @_) if $self->env->{'flapp.request.http.body'};
    
    no warnings 'redefine';
    local *File::Temp::new = $FILE_TMP_NEW_WITH_VALID_SUFFIX;
    local *Hash::MultiValue::from_mixed = sub{ shift; $self->MultiValueHash->from_mixed(@_) };
    local *Hash::MultiValue::new = sub{ shift; $self->MultiValueHash->new(@_) };
    local *HTTP::Body::new = sub{
        my $body = $self->env->{'flapp.request.http.body'} = $HTTP_BODY_NEW->(@_);
        $body->{tmpdir} = $self->c->upload_dir;
        $body;
    };
    $sub->($self, @_);
};

sub body_parameters {
    my $self = shift;
    $self->env->{'flapp.request.body'} ||= $self->filter_input(
        $HTTP_BODY->(\&Plack::Request::body_parameters => $self, @_)
    );
}
*body_params = \&body_parameters;

sub content { $HTTP_BODY->(\&Plack::Request::content => @_) }

sub context { shift->{context} || die 'No context' }
*c = \&context;

sub filter_input {
    my($self, $p) = @_;
    my $c = $self->c;
    my $f = $c->ua->filter_input;
    $c->Util->recursive_do({
        scalar => $f,
        hash_ref => sub{
            my($next, $ref) = @_;
            foreach(sort keys %$ref){
                $f->(my $k = $_);
                $ref->{$k} = delete $ref->{$_} if $k ne $_;
            }
            $next->($ref);
        },
        sort_keys => 0,
    }, $p);
    $p;
}

use constant FINALIZE_KEYS =>
    [map{ ("plack.request.$_", "flapp.request.$_") } qw/query body merged upload/];

sub finalize {
    my $self = shift;
    @{$self->env}{@{$self->FINALIZE_KEYS}} = ();
}

sub new {
    my($class, $env, $c) = @_;
    my $req = $class->SUPER::new($env);
    $c->_weaken_($req->{context} = $c);
    $req;
}

sub parameters {
    my $self = shift;
    $self->env->{'flapp.request.merged'} ||= do{
        no warnings 'redefine';
        local *Hash::MultiValue::new = sub{ shift; $self->MultiValueHash->new(@_) };
        $self->SUPER::parameters(@_);
    };
}
*params = \&parameters;

sub query_parameters {
    my $self = shift;
    $self->env->{'flapp.request.query'} ||= $self->filter_input(do{
        no warnings 'redefine';
        local *Hash::MultiValue::new = sub{ shift; $self->MultiValueHash->new(@_) };
        my $q = $self->SUPER::query_parameters(@_);
        my($c, $s);
        ($s = $c->session)->state->load_sid_from_query($s, $q) if ($c = $self->c)->session_enabled;
        $q;
    });
}
*query_params = \&query_parameters;

sub uploads {
    my $self = shift;
    $self->env->{'flapp.request.upload'} ||= $self->filter_input(
        $HTTP_BODY->(\&Plack::Request::uploads => $self, @_)
    );
}

1;

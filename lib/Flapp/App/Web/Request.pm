package Flapp::App::Web::Request;
use Flapp qw/-b Flapp::Object -i Plack::Request -m -r -s -w/;
use File::Temp;
use HTTP::Entity::Parser::MultiPart;

# Hash::MultiValue problems
#
# - Can't filter_input recursive by inside-out.
# - Hash-ref blessed object should not be used while hash-ref interface updating is wrong.
# - For perceiving, "ARRAY(0xXXXXXXXXX)" is better than the last value.
#
# So, use Flapp::App::Web::Request::MultiValueHash for compatibility.

sub DESTROY {
    my $self = shift;
    close($_->[0]) && unlink($_->[1]) for @{$self->{_uploads} || []};
    $self->SUPER::DESTROY(@_);
}

our $TEMPFILE = \&File::Temp::tempfile;
sub _parse_request_body {
    my $self = shift;
    no warnings 'redefine';
    local *Hash::MultiValue::new = sub{ shift; $self->MultiValueHash->new(@_) };
    local *HTTP::Entity::Parser::MultiPart::tempfile = sub{
        my @r = $TEMPFILE->(DIR => $self->c->upload_dir);
        push @{$self->{_uploads} ||= []}, \@r;
        @r;
    };
    my $r = $self->SUPER::_parse_request_body(@_);
    $self->env->{'plack.request.upload'} = $self->filter_input($self->env->{'plack.request.upload'});
    $r;
}

sub body_parameters {
    my $self = shift;
    $self->env->{'plack.request.body'} ||=
        $self->filter_input($self->MultiValueHash->new(@{$self->_body_parameters}));
}
*body_params = \&body_parameters;

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

use constant FINALIZE_KEYS => [map{ "plack.request.$_" } qw/query body merged upload/];

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
    $self->env->{'plack.request.merged'} ||= $self->MultiValueHash->new
        ->merge_mixed(%{$self->query_params})
        ->merge_mixed(%{$self->body_params});
}
*params = \&parameters;

sub query_parameters {
    my $self = shift;
    $self->env->{'plack.request.query'} ||= $self->filter_input(do{
        my $q = $self->MultiValueHash->new(@{$self->_query_parameters});
        my($c, $s);
        ($s = $c->session)->state->load_sid_from_query($s, $q) if ($c = $self->c)->session_enabled;
        $q;
    });
}
*query_params = \&query_parameters;

1;

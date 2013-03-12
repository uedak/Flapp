package Flapp::App::Web::Session::State::Url;
use Flapp qw/-b Flapp::App::Web::Session::State -m -s -w/;

sub _add_sid {
    my($self, $ses) = (shift, shift);
    my $r = ref $_[0] ? shift : do{ \(my $s = shift) };
    my $_as = $self->{_add_sid} ||= [{$ses->key, $ses->id}];
    my $h = $_as->[0];
    my $q = $_as->[1] ||= $ses->c->Util->uri_escape($h);
    
    my $u;
    $$r =~ s{\?([^#]*)}{'?'.join('&', (grep{ /^([^%+]+)=/ ? !exists $h->{$1} : (
        !/^([^=]+)/ || !exists $h->{($u ||= $ses->c->Util)->uri_unescape($1)}
    ) } split /&/, $1), $q)}e || ($$r =~ s/#/?$q#/) || ($$r .= "?$q");
    $$r;
}

sub _is_inner {
    my($self, $ses) = (shift, shift);
    ((my $d) = $_[0] =~ m%^(?:https?:)?//([\-.0-9A-Za-z]*)%)
     || return $_[0] !~ m%^#|^[0-9A-Za-z]*:%;
    
    $d =~ ($self->{domain_regexp} ||=
        $self->{domain} ? qr/^[\-.0-9A-Za-z]*\b\Q$self->{domain}\E\z/ :
        $ses->c->req->base =~ m%^https?://([\-.0-9A-Za-z]+)% ? qr/^\Q$1\E\z/ :
        die $ses->c->req->base
    );
}

sub finalize {
    my($self, $ses) = @_;
    my $c = $ses->c;
    my $res = $c->res;
    
    if(my $url = $res->location){
        $res->location($self->_add_sid($ses, \$url)) if $self->_is_inner($ses, $url);
    }elsif(defined($res->{body}) && !ref($res->{body})){
        my($bp, $pos, $htm) = (\($res->{body}), 0);
        while($$bp =~ m%<(a|form|meta|!--)%ig){
            $$bp =~ /-->/gc ? next : last if $1 eq '!--';
            my $tnm = lc $1;
            my $p = pos($$bp) - length($1) - 1;
            my $tag = $c->Tag->new($c, $tnm, $bp) || next;
            
            if($tnm eq 'a'){
                my $url = $tag->attr('href');
                next if !defined $url || !$self->_is_inner($ses, $url);
                $tag = $tag->attr(href => $self->_add_sid($ses, \$url))->to_s;
            }elsif($tnm eq 'form'){
                my $url = $tag->attr('action');
                $url = '' if !defined $url;
                next if !$self->_is_inner($ses, $url);
                if(($tag->attr('method') || '') =~ /^post\z/i){
                    $tag = $tag->attr(action => $self->_add_sid($ses, \$url))->to_s;
                }else{
                    $tag = $tag->to_s.sprintf(
                        '<input type="hidden" name="%s" value="%s" />',
                        map{ $c->html_attr($_) } ($ses->key, $ses->id)
                    );
                }
            }elsif($tnm eq 'meta'){
                next if ($tag->attr('http-equiv') || '') !~ /^refresh\z/i
                 || ($tag->attr('content') || '') !~ /^([0-9]+);[ \t\r\n]*url=(.+)/i;
                my($sec, $url) = ($1, $2);
                next if !$self->_is_inner($ses, $url);
                $tag = $tag->attr(content => "$sec;url=".$self->_add_sid($ses, \$url))->to_s;
            }else{
                die $tnm;
            }
            $htm .= substr($$bp, $pos, $p - $pos) if $p > $pos;
            $htm .= $tag;
            $pos = pos $$bp;
        }
        $res->body($htm.substr($$bp, $pos)) if defined $htm;
    }else{
        warn 'session finalize failed';
    }
}

my $key = 'flapp.session.state.url.id';

sub load_sid {
    my $c = $_[1]->c;
    my $e = $c->req->env;
    $c->req->query_parameters if !exists $e->{$key};
    $e->{$key};
}

sub load_sid_from_query {
    my($self, $ses, $q) = @_;
    $ses->c->req->env->{$key} = delete $q->{$ses->key};
}

1;

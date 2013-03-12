package Flapp::App::Web::Response;

BEGIN{ # Old Plack::Response isa Class::Accessor::Fast ...
    use Plack::Response;
    $Flapp::G{module}->{"Plack/Response.pm"} = 1 if $Plack::Response::VERSION eq '0.01';
}

use Flapp qw/-b Flapp::Object -i Plack::Response -m -s -w/;

sub redirect { shift->SUPER::redirect(@_) && !1 }

1;

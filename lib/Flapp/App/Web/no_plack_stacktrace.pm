use Flapp qw/-m -s -w/;

no warnings 'redefine';
*Plack::Middleware::StackTrace::call = sub{ $_[0]->app->($_[1]) };

sub{};

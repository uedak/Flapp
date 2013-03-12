#!/usr/bin/perl

use Plack::Handler::CGI;
use Plack::Util;
use strict;
use warnings;

(my $psgi = __FILE__) =~ s/\.cgi\z/.psgi/;
Plack::Handler::CGI->new->run(Plack::Util::load_psgi $psgi);

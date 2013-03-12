#!/usr/bin/perl

use Plack::Handler::FCGI;
use Plack::Util;
use strict;
use warnings;

(my $psgi = __FILE__) =~ s/\.fcgi\z/.psgi/;
Plack::Handler::FCGI->new->run(Plack::Util::load_psgi $psgi);

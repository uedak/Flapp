use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use strict;
use warnings;

use MyProject;
ok my $proj = 'MyProject';
is $proj->Errors, 'MyProject::Errors';

$proj->begin;
my %fe = %{Flapp::Errors->ERRORS};
is_deeply $proj->Errors->ERRORS, \%fe;

$proj->Errors->define_errors(201 => 'Foo');
is_deeply Flapp::Errors->ERRORS, \%fe;
is_deeply $proj->Errors->ERRORS, {%fe, 201 => 'Foo'};

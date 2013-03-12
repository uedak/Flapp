use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use strict;
use warnings;

use MyProject;
my $proj = 'MyProject';
is my $u = $proj->Util, 'MyProject::Util';

my @ary = ("\t\n\r\"\\", '', undef);
my $tsv = join("\t", '\\t\\n\\r\\"\\\\', '""', '');

is $u->ary2tsv(@ary), $tsv;
is_deeply [$u->tsv2ary($tsv)], \@ary;

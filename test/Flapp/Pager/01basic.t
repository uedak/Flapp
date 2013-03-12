use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use strict;
use warnings;

use MyProject;
my $proj = 'MyProject';
my $p = $proj->Pager;

{
    ok my $p = $proj->Pager->new(100, 10, 2);
    is $p->entries_on_this_page, 10;
    is $p->entries_per_page, 10;
    is $p->first, 11;
    is $p->first_page, 1;
    is $p->last, 20;
    is $p->last_page, 10;
    is $p->next_page, 3;
    is $p->prev_page, 1;
    
    $p->entries_per_page(20);
    is $p->current_page, 1;
    is $p->next_page, 2;
    is $p->prev_page, undef;
}

{
    my $p = $proj->Pager->new(200, 10, 1);
    is_deeply $p->pages(10), [1 .. 10];
    is_deeply $p->pages(9),  [1 .. 9];
    
    $p->current_page(2);
    is_deeply $p->pages(10), [1 .. 10];
    is_deeply $p->pages(9),  [1 .. 9];
    
    $p->current_page(4);
    is_deeply $p->pages(10), [1 .. 10];
    is_deeply $p->pages(9),  [1 .. 9];
    
    $p->current_page(5);
    is_deeply $p->pages(10), [1 .. 10];
    is_deeply $p->pages(9),  [1 .. 9];
    
    $p->current_page(6);
    is_deeply $p->pages(10), [2 .. 11];
    is_deeply $p->pages(9),  [2 .. 10];
    
    
    
    $p->current_page(20);
    is_deeply $p->pages(10), [11 .. 20];
    is_deeply $p->pages(9),  [12 .. 20];
    
    $p->current_page(19);
    is_deeply $p->pages(10), [11 .. 20];
    is_deeply $p->pages(9),  [12 .. 20];
    
    $p->current_page(16);
    is_deeply $p->pages(10), [11 .. 20];
    is_deeply $p->pages(9),  [12 .. 20];
    
    $p->current_page(15);
    is_deeply $p->pages(10), [11 .. 20];
    is_deeply $p->pages(9),  [11 .. 19];
    
    $p->current_page(14);
    is_deeply $p->pages(10), [10 .. 19];
    is_deeply $p->pages(9),  [10 .. 18];
}

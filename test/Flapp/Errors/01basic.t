use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use strict;
use warnings;
use MyProject;

#add / get / has_error
{
    my $e = MyProject->Errors->new;
    my $e2 = MyProject->Errors->new->add(foo => 108);
    
    $e->add(foo => 107)
        ->add(foo => 107)
        ->add(bar => [101, 'x'])
        ->add(foo => {cd => 999, msg => 'FOO'})
        ->add(bar => $e2);
    
    is_deeply $e->get('foo'), [{cd => 107,msg => "入力されていません"}, {cd => 999, msg => 'FOO'}];
    is_deeply $e->get('bar'), [{cd => 101,msg => "x は使用できません"}];
    is_deeply $e->get('bar', 0), $e2;
    #is_deeply $e->TO_JSON, {details => [], messages => []};
    
    ok $e->has_error(foo => 999);
    ok $e->has_error(bar => 101);
    ok !$e->has_error(bar => 108);
}

#clear
{
    my $e = MyProject->Errors->new->add(foo => 107);
    is_deeply $e->get('foo'), [{cd => 107,msg => "入力されていません"}];
    $e->clear;
    is_deeply $e->get('foo'), undef;
}

#count
{
    my $e = MyProject->Errors->new;
    my $e2 = MyProject->Errors->new->add(foo => 107);
    is $e->count, 0;
    
    $e->add(foo => 107);
    is $e->count, 1;
    
    $e->add(foo => $e2);
    is $e->count, 2;
    
    $e2->add(foo => 108);
    is $e->count, 3;
    
    $e->add(bar => MyProject->Errors->new);
    is $e->count, 3;
}

#details
{
    my $e = MyProject->Errors->new->add(foo => 107);
    my $e2 = MyProject->Errors->new;
    my $e3 = MyProject->Errors->new->add(baz => 107);
    $e->add(foo => MyProject->Errors->new, $e2->add(bar => $e3));
    is_deeply $e->details, [
        {name => "foo", errors => [{cd => 107, msg => "入力されていません"}], children => [
            undef,
            [{name => "bar", children => [
                [{name => "baz", errors => [{cd => 107, msg => "入力されていません"}]}]
            ]}],
        ]}
    ];
    $e2->label({bar => 'バー'});
    is_deeply $e->details, [
        {name => "foo", errors => [{cd => 107, msg => "入力されていません"}], children => [
            undef,
            [{name => "bar", label => 'バー', children => [
                [{name => "baz", errors => [{cd => 107, msg => "入力されていません"}]}]
            ]}],
        ]}
    ];
}

#merge
{
    my $e = MyProject->Errors->new->add(foo => 107);
    my $e2 = MyProject->Errors->new(foo => 107)->add(bar => 107);
    is_deeply $e->merge($e2)->details, [
        {errors => [{cd => 107,msg => "入力されていません"}],name => "foo"},
        {errors => [{cd => 107,msg => "入力されていません"}],name => "bar"},
    ];
}

#messages
{
    my $e = MyProject->Errors->new;
    my $e2 = MyProject->Errors->new;
    my $e3 = MyProject->Errors->new;
    $e->add(foo => $e2, $e3);
    is_deeply $e->messages, [];
    
    $e3->add('' => 107)->add(bar => 107);
    is_deeply $e->messages, ['[foo(2)] 入力されていません', '[foo(2) bar] 入力されていません'];
    
    $e->label({foo => 'フー'});
    $e3->label({bar => 'バー'});
    is_deeply $e->messages, ['[フー(2)] 入力されていません', '[フー(2) バー] 入力されていません'];
}

#is_empty
{
    my $e = MyProject->Errors->new;
    my $e2 = MyProject->Errors->new;
    $e->add(foo => $e2);
    ok $e->is_empty;
    $e2->add(bar => 107);
    ok !$e->is_empty;
}

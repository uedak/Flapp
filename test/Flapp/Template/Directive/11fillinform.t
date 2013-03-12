use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
use strict;
use warnings;

if(!eval{ require Plack }){
    $::INC{'Plack/Request.pm'} = $::INC{'Plack/Response.pm'} = $::INC{'HTTP/Body.pm'} = 1;
    no warnings;
    *Plack::Request::new = *Plack::Response::new = sub{};
}

use MyProject;
ok my $p = MyProject->Template->Parser->new;
MyProject->begin;
my %opt = (context => MyProject->app('MyWebApp')->new({}), auto_filter => [qw/html/]);

{
    my $form = <<_END_;
<input name = "t" />
<input name="t" type="text" />
<input name="t" type="hidden" />
<input name="t" type="password" />

<input type="checkbox" name="c" value="&amp;1" checked />
<input type="checkbox" name="c" value="&amp;2" checked />

<input type="radio" name="r" value="&amp;1" checked />
<input type="radio" type="checkbox" name="r" value="&amp;2" checked />

<select name="sel">
    <option> &amp;1 </option>
    <option value="&amp;2"></option>
</select>

<textarea name="ta"></textarea>
_END_
    
    my $htm = <<_END_;
TEST
[%- FILLINFORM (params || {}) #TEST -%]
$form
[%- END -%]
_END_
    
    is $p->open(\$htm)->init(\%opt)->render, "TEST\n$form\n";
    
    
    is $p->open(\$htm)->init({stash => {params => {
        t => "<T>\n",
        c => ['&1', '&2'],
        r => '&2',
        sel => ['&1', '&2'],
        ta => "<TA>\n",
    }}, %opt})->render, <<_END_;
TEST
<input name = "t" value="&lt;T&gt;
" />
<input name="t" type="text" value="&lt;T&gt;
" />
<input name="t" type="hidden" value="&lt;T&gt;
" />
<input name="t" type="password" />

<input type="checkbox" name="c" value="&amp;1" checked="checked" />
<input type="checkbox" name="c" value="&amp;2" checked="checked" />

<input type="radio" name="r" value="&amp;1" />
<input type="radio" name="r" value="&amp;2" checked="checked" />

<select name="sel">
    <option selected="selected"> &amp;1 </option>
    <option value="&amp;2" selected="selected"></option>
</select>

<textarea name="ta">&lt;TA&gt;
</textarea>

_END_
}

{
    my $htm = <<_END_;
[%- FILLINFORM params -%]
<input name="ex" value="EX" />
<input name="nex" value="NEX" />
[%- END -%]
_END_
    
    is $p->open(\$htm)->init({stash => {params => {ex => ''}}, %opt})->render,
        qq{<input name="ex" value="" />\n<input name="nex" value="NEX" />\n};
}

{
    my $htm = <<_END_;
[%- FILLINFORM params password=1 -%]
<input name="p" type="password" />
[%- END -%]
_END_
    
    is $p->open(\$htm)->init({stash => {params => {p => '***'}}, %opt})->render,
        qq{<input name="p" type="password" value="***" />\n};
    
}

{ #NESTED
    my $htm = <<_END_;
[%- FILLINFORM p1 -%]
 <input name="i" />
 [%- FILLINFORM p2 -%]
  <input name="i" />
 [%- END -%]
 [%- FILLINFORM p3 -%]
  <input name="i" />
 [%- END -%]
 <input name="i" />
[%- END -%]
_END_
    is $p->open(\$htm)->init({stash => {
        p1 => {i => 1},
        p2 => {i => 2},
        p3 => {i => 3},
    }, %opt})->render,
        ' <input name="i" value="1" />
  <input name="i" value="2" />
  <input name="i" value="3" />
 <input name="i" value="1" />
';
}

{ #INFLATE
    my $htm = <<_END_;
[%- FILLINFORM p inflate=1 -%]
<input name="x[0][txt]" value="0" />
<input name="x[0][chk]" type="checkbox" value="1" checked />
<input name="x[0][chk][]" type="checkbox" value="2" checked />
<input name="x[1][txt]" value="t1" />
<input name="x[1][chk]" type="checkbox" value="1" checked />
<input name="x[1][chk][]" type="checkbox" value="2" checked />
<input name="x[2][txt]" value="t2" />
<input name="x[2][chk]" type="checkbox" value="1" checked />
<input name="x[2][chk][]" type="checkbox" value="2" checked />
[%- END -%]
_END_
    is $p->open(\$htm)->init({stash => {p => {
        x => [
            {txt => 't0', chk => [1, 2]},
            {chk => 1},
        ],
    }}, %opt})->render, <<_END_;
<input name="x[0][txt]" value="t0" />
<input name="x[0][chk]" type="checkbox" value="1" checked="checked" />
<input name="x[0][chk][]" type="checkbox" value="2" checked="checked" />
<input name="x[1][txt]" value="t1" />
<input name="x[1][chk]" type="checkbox" value="1" checked="checked" />
<input name="x[1][chk][]" type="checkbox" value="2" />
<input name="x[2][txt]" value="t2" />
<input name="x[2][chk]" type="checkbox" value="1" checked />
<input name="x[2][chk][]" type="checkbox" value="2" checked />
_END_
}

{ #INVALID TEXTAREA
    my $htm = <<_END_;
[%- FILLINFORM p -%]
<textarea name=ok></textarea>
<textarea name=ng></txtarea>
[% p.ok %] / [% p.ng %]
[%- END -%]
_END_
    is $p->open(\$htm)->init({stash => {p => {
        ok => 'ok', ng => 'ng'
    }}, %opt})->render, <<_END_;
<textarea name=ok>ok</textarea>
<textarea name=ng></txtarea>
ok / ng
_END_
}

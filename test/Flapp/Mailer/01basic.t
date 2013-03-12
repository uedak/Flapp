use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use strict;
use warnings;

use MyProject;
is (MyProject->Mailer, 'MyProject::Mailer');
my $EML = <<'_END_';
To: ＴＯ <to@te.st>, to2@te.st
Cc: Ｃｃ <cc@te.st>, cc2@te.st
Bcc: Ｂｃｃ <bcc@te.st>, bcc2@te.st
From: Ｆｒｏｍ <from@te.st>
Return-Path: Ｒｅｔｕｒｎ－Ｐａｔｈ <return-path@te.st>
Reply-To: Ｒｅｐｌｙ－Ｔｏ <reply-to@te.st>
Subject: Ｓｕｂｊｅｃｔ

Ｈｅｌｌｏ　Ｗｏｒｌｄ！
_END_

{
    ok my $m1 = MyProject->Mailer->new($EML);
    ok !eval{ $m1->filter([]) };
    like $@, qr/^Invalid filter: \[\]/;
    
    ok my $m2 = MyProject->Mailer->new($EML);
    is_deeply $m2->filter([['*' => '*']]), $m1;
    is_deeply $m2->filter([[qr/./ => '*']]), $m1;
    
    my $body = <<'_END_';
Ｈｅｌｌｏ　Ｗｏｒｌｄ！

==== original header ====
Bcc: Ｂｃｃ <bcc@te.st>, bcc2@te.st
Cc: Ｃｃ <cc@te.st>, cc2@te.st
From: Ｆｒｏｍ <from@te.st>
Reply-To: Ｒｅｐｌｙ－Ｔｏ <reply-to@te.st>
Return-Path: Ｒｅｔｕｒｎ－Ｐａｔｈ <return-path@te.st>
_END_
    
    $m1 = MyProject->Mailer->new($EML);
    is_deeply $m1->filter([['*' => 'test@te.st']]), {
        header => {
            To => 'test@te.st',
            Cc => 'test@te.st',
            Bcc => 'test@te.st',
            From => 'test@te.st',
            'Return-Path' => 'test@te.st',
            'Reply-To' => 'test@te.st',
            Subject => 'Ｓｕｂｊｅｃｔ',
            'MIME-Version' => '1.0',
        },
        body => \"${body}To: ＴＯ <to\@te.st>, to2\@te.st\n",
    };
    
    $m1 = MyProject->Mailer->new($EML);
    is_deeply $m1->filter([['to@te.st' => 'to@te.st'], ['*' => 'test@te.st']]), {
        header => {
            To => 'ＴＯ <to@te.st>, test@te.st',
            Cc => 'test@te.st',
            Bcc => 'test@te.st',
            From => 'test@te.st',
            'Return-Path' => 'test@te.st',
            'Reply-To' => 'test@te.st',
            Subject => 'Ｓｕｂｊｅｃｔ',
            'MIME-Version' => '1.0',
        },
        body => \"${body}To: ＴＯ <to\@te.st>, to2\@te.st\n",
    };
    
    $m2 = MyProject->Mailer->new($EML);
    is_deeply $m2->filter([['to@te.st' => '*'], ['*' => 'test@te.st']]), $m1;
    
    $m1 = MyProject->Mailer->new($EML);
    is_deeply $m1->filter([[qr/^to.*\@te\.st/ => '*'], ['*' => 'test@te.st']]), {
        header => {
            To => 'ＴＯ <to@te.st>, to2@te.st',
            Cc => 'test@te.st',
            Bcc => 'test@te.st',
            From => 'test@te.st',
            'Return-Path' => 'test@te.st',
            'Reply-To' => 'test@te.st',
            Subject => 'Ｓｕｂｊｅｃｔ',
            'MIME-Version' => '1.0',
        },
        body => \$body,
    };
    
    $m1 = MyProject->Mailer->new($EML);
    is_deeply $m1->filter([['*' => 'test1@te.st, test2@te.st']]), {
        header => {
            To => 'test1@te.st, test2@te.st',
            Cc => 'test1@te.st, test2@te.st',
            Bcc => 'test1@te.st, test2@te.st',
            From => 'test1@te.st',
            'Return-Path' => 'test1@te.st',
            'Reply-To' => 'test1@te.st',
            Subject => 'Ｓｕｂｊｅｃｔ',
            'MIME-Version' => '1.0',
        },
        body => \"${body}To: ＴＯ <to\@te.st>, to2\@te.st\n",
    };
}

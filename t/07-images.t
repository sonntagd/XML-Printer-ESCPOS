#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;
use lib 't/lib';
use Mock::Printer::ESCPOS;

plan skip_all => 'image tests must be rewritten, add sample image files to work with';

my $mockprinter = Mock::Printer::ESCPOS->new();
my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

my $ret = $parser->parse(
    q#
            <escpos>
              <image filename="header.gif" />
            </escpos>
        #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
my $calls = $mockprinter->{calls};
ok( (          ref $calls eq 'ARRAY'
            or @$calls == 1
            or ref $calls->[0] eq 'ARRAY'
            or @{ $calls->[0] } == 2
            or $calls->[0]->[1] eq 'image'
            or ref $calls->[0]->[2] eq 'GD::Image'
    ),
    'XML translated correctly'
);

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
              <image>header.gif</image>
            </escpos>
        #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls}, [ [ image => 'header.gif' ] ], 'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
              <image size="23">header.gif</image>
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong image tag usage', 'correct error message';

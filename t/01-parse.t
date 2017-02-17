#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;

{

    package Mock::Printer::ESCPOS;

    our $AUTOLOAD;

    sub new {
        return bless { calls => [], }, 'Mock::Printer::ESCPOS';
    }

    sub AUTOLOAD {
        my ( $self, @params ) = @_;
        my $method = $AUTOLOAD;
        $method =~ s/^.*:://;
        push @{ $self->{calls} } => [ $method => @params ];
    }
}

subtest 'Simple parsing' => sub {
    plan tests => 3;

    my $mockprinter = Mock::Printer::ESCPOS->new();
    my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    my $ret = $parser->parse(
        q#
            <escpos>
              <bold>bold text</bold>
              <underline>underlined text</underline>
              <bold>
                <underline>bold AND <bold> underlinded</bold> text</underline>
                <doubleStrike>you <invert>can not</invert> read this</doubleStrike>
              </bold>
              <lf />
              <color>
                <bold>This is printed with the second color (if supported)</bold>
              </color>
              <lf lines="3" />
              <text> with whitespaces </text>
              <tab /><text>go on</text>
              <upsideDown>some additional text</upsideDown>
              <rot90>rotated text </rot90>
            </escpos>
        #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls},
        [
        [ bold         => 1 ],
        [ text         => 'bold text' ],
        [ bold         => 0 ],
        [ underline    => 1 ],
        [ text         => 'underlined text' ],
        [ underline    => 0 ],
        [ bold         => 1 ],
        [ underline    => 1 ],
        [ text         => 'bold AND' ],
        [ text         => 'underlinded' ],
        [ text         => 'text' ],
        [ underline    => 0 ],
        [ doubleStrike => 1 ],
        [ text         => 'you' ],
        [ invert       => 1 ],
        [ text         => 'can not' ],
        [ invert       => 0 ],
        [ text         => 'read this' ],
        [ doubleStrike => 0 ],
        [ bold         => 0 ],
        [ lf           => ],
        [ color        => 1 ],
        [ bold         => 1 ],
        [ text         => 'This is printed with the second color (if supported)' ],
        [ bold         => 0 ],
        [ color        => 0 ],
        [ lf           => ],
        [ lf           => ],
        [ lf           => ],
        [ text         => ' with whitespaces ' ],
        [ tab          => ],
        [ text         => 'go on' ],
        [ upsideDown   => 1 ],
        [ text         => 'some additional text' ],
        [ upsideDown   => 0 ],
        [ rot90        => 1 ],
        [ text         => 'rotated text' ],
        [ rot90        => 0 ],
        ],
        'XML translated correctly';
};

subtest 'undefined tags' => sub {
    plan tests => 2;

    my $mockprinter = Mock::Printer::ESCPOS->new();
    my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    my $ret = $parser->parse(
        q#
            <escpos>
              <pold>bold text</pold>
              <underline>underlined text</underline>
            </escpos>
        #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'tag pold is not allowed', 'correct error message';
};

subtest 'QR codes' => sub {
    plan tests => 6;

    my $mockprinter = Mock::Printer::ESCPOS->new();
    my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    my $ret = $parser->parse(
        q#
        <escpos>
            <qr>Simple QR code</qr>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls}, [ [ qr => 'Simple QR code' ], ], 'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <qr version="4" moduleSize="4">Dont panic!</qr>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls}, [ [ qr => 'Dont panic!', 'L', 4, 4 ], ], 'XML translated correctly';
};

subtest 'utf8ImagedText' => sub {
    plan tests => 9;

    my $mockprinter = Mock::Printer::ESCPOS->new();
    my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    my $ret = $parser->parse(
        q#
        <escpos>
            <utf8ImagedText>advanced TeXT</utf8ImagedText>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls}, [ [ utf8ImagedText => 'advanced TeXT' ], ], 'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
            >Dont panic!</utf8ImagedText>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls},
        [
        [   utf8ImagedText => "Dont panic!",
            fontFamily     => "Rubik",
        ],
        ],
        'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
                fontStyle = "Normal"
                lineHeight ="40"
            >Dont panic!</utf8ImagedText>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls},
        [
        [   utf8ImagedText => "Dont panic!",
            fontFamily     => "Rubik",
            fontStyle      => "Normal",
            lineHeight     => 40,
        ],
        ],
        'XML translated correctly';
};

subtest 'barcodes' => sub {
    plan tests => 9;

    my $mockprinter = Mock::Printer::ESCPOS->new();
    my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    my $ret = $parser->parse(
        q#
        <escpos>
            <barcode>advanced TeXT</barcode>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls}, [ [ barcode => barcode => 'advanced TeXT' ], ], 'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <barcode
                system="CODABAR"
            >Dont panic!</barcode>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls},
        [
        [   barcode => barcode => "Dont panic!",
            system  => "CODABAR",
        ],
        ],
        'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <barcode
                HRIPosition="below"
                font = "b"
                lineHeight ="37"
            >Dont panic!</barcode>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls},
        [
        [   barcode     => barcode => "Dont panic!",
            HRIPosition => "below",
            font        => "b",
            lineHeight  => 37,
        ],
        ],
        'XML translated correctly';
};

subtest 'linefeed' => sub {

    plan tests => 11;

    my $mockprinter = Mock::Printer::ESCPOS->new();
    my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    my $ret = $parser->parse(
        q#
            <escpos>
              <bold>bold<lf /> text</bold>
            </escpos>
        #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls},
        [ [ bold => 1 ], [ text => "bold" ], [ lf => ], [ text => "text" ], [ bold => 0 ], ],
        'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
            <escpos>
              <bold>bold<lf>error</lf> text</bold>
            </escpos>
        #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong lf tag usage', 'correct error message';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
            <escpos>
              <bold>bold<lf lines="0" /> text</bold>
            </escpos>
        #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong lf tag usage: lines attribute must be a positive integer', 'correct error message';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
            <escpos>
              <bold>bold<lf lines="3.17" /> text</bold>
            </escpos>
        #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong lf tag usage: lines attribute must be a positive integer', 'correct error message';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
            <escpos>
              <bold>bold<lf lines="asd" /> text</bold>
            </escpos>
        #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong lf tag usage: lines attribute must be a positive integer', 'correct error message';
};

subtest 'images' => sub {

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
};

subtest 'printAreaWidth' => sub {

    plan tests => 8;

    my $mockprinter = Mock::Printer::ESCPOS->new();
    my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    my $ret = $parser->parse(
        q#
            <escpos>
              <printAreaWidth width="507" />
            </escpos>
        #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls}, [ [ printAreaWidth => 507 ] ], 'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
            <escpos>
              <printAreaWidth>501</printAreaWidth>
            </escpos>
        #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls}, [ [ printAreaWidth => 501 ] ], 'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
            <escpos>
              <printAreaWidth override="1">512</printAreaWidth>
            </escpos>
        #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong printAreaWidth tag usage', 'correct error message';
};

subtest 'utf8ImagedText word wrap' => sub {
    plan tests => 21;

    my $mockprinter = Mock::Printer::ESCPOS->new();
    my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    my $ret = $parser->parse(
        q#
        <escpos>
            <utf8ImagedText wordwrap="10">advanced TeXT</utf8ImagedText>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls}, [ [ utf8ImagedText => 'advanced' ], [ utf8ImagedText => 'TeXT' ], ],
        'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
                wordwrap="b"
            >Lorem ipsum dolor sit amet,</utf8ImagedText>
        </escpos>
    #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong utf8ImagedText tag usage: wordwrap attribute must be a positive integer',
        'correct error message';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(

        q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
                wordwrap="13.9"
            >Lorem ipsum dolor sit amet,</utf8ImagedText>
        </escpos>
    #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong utf8ImagedText tag usage: wordwrap attribute must be a positive integer',
        'correct error message';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
                wordwrap="0"
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore </utf8ImagedText>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls},
        [
        [ 'utf8ImagedText', 'Lorem ipsum dolor sit amet, consetetur sadipscing', 'fontFamily', 'Rubik' ],
        [ 'utf8ImagedText', 'elitr, sed diam nonumy eirmod tempor invidunt ut',  'fontFamily', 'Rubik' ],
        [ 'utf8ImagedText', 'labore',                                            'fontFamily', 'Rubik' ]
        ],
        'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <utf8ImagedText
                wordwrap=""
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.</utf8ImagedText>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls},
        [
        [ utf8ImagedText => 'Lorem ipsum dolor sit amet, consetetur sadipscing' ],
        [ utf8ImagedText => 'elitr, sed diam nonumy eirmod tempor invidunt ut' ],
        [ utf8ImagedText => 'labore et dolore magna aliquyam erat, sed diam' ],
        [ utf8ImagedText => 'voluptua. At vero eos et accusam et justo duo' ],
        [ utf8ImagedText => 'dolores et ea rebum. Stet clita kasd gubergren,' ],
        [ utf8ImagedText => 'no sea takimata sanctus est Lorem ipsum dolor sit' ],
        [ utf8ImagedText => 'amet. Lorem ipsum dolor sit amet, consetetur' ],
        [ utf8ImagedText => 'sadipscing elitr, sed diam nonumy eirmod tempor' ],
        [ utf8ImagedText => 'invidunt ut labore et dolore magna aliquyam erat,' ],
        [ utf8ImagedText => 'sed diam voluptua. At vero eos et accusam et' ],
        [ utf8ImagedText => 'justo duo dolores et ea rebum. Stet clita kasd' ],
        [ utf8ImagedText => 'gubergren, no sea takimata sanctus est Lorem' ],
        [ utf8ImagedText => 'ipsum dolor sit amet.' ]
        ],
        'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
                wordwrap="00"
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.</utf8ImagedText>
        </escpos>
    #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong utf8ImagedText tag usage: wordwrap attribute must be a positive integer',
        'correct error message';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
                wordwrap="39"
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.</utf8ImagedText>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls},
        [
        [ utf8ImagedText => 'Lorem ipsum dolor sit amet, consetetur',  'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'sadipscing elitr, sed diam nonumy',       'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'eirmod tempor invidunt ut labore et',     'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'dolore magna aliquyam erat, sed diam',    'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'voluptua. At vero eos et accusam et',     'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'justo duo dolores et ea rebum. Stet',     'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'clita kasd gubergren, no sea takimata',   'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'sanctus est Lorem ipsum dolor sit amet.', 'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'Lorem ipsum dolor sit amet, consetetur',  'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'sadipscing elitr, sed diam nonumy',       'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'eirmod tempor invidunt ut labore et',     'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'dolore magna aliquyam erat, sed diam',    'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'voluptua. At vero eos et accusam et',     'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'justo duo dolores et ea rebum. Stet',     'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'clita kasd gubergren, no sea takimata',   'fontFamily', 'Rubik' ],
        [ utf8ImagedText => 'sanctus est Lorem ipsum dolor sit amet.', 'fontFamily', 'Rubik' ]
        ],
        'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
                fontStyle = "Normal"
                lineHeight ="40"
                wordwrap="60"
                bodystart="   "
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus</utf8ImagedText>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls},
        [
        [   utf8ImagedText => 'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed',
            'fontFamily', 'Rubik', 'fontStyle', 'Normal', 'lineHeight', '40'
        ],
        [   utf8ImagedText => '   diam nonumy eirmod tempor invidunt ut labore et dolore',
            'fontFamily', 'Rubik', 'fontStyle', 'Normal', 'lineHeight', '40'
        ],
        [   utf8ImagedText => '   magna aliquyam erat, sed diam voluptua. At vero eos et',
            'fontFamily', 'Rubik', 'fontStyle', 'Normal', 'lineHeight', '40'
        ],
        [   utf8ImagedText => '   accusam et justo duo dolores et ea rebum. Stet clita kasd',
            'fontFamily', 'Rubik', 'fontStyle', 'Normal', 'lineHeight', '40'
        ],
        [   utf8ImagedText => '   gubergren, no sea takimata sanctus',
            'fontFamily', 'Rubik', 'fontStyle', 'Normal', 'lineHeight', '40'
        ],
        ],
        'XML translated correctly';
};

subtest 'text word wrap' => sub {
    plan tests => 15;

    my $mockprinter = Mock::Printer::ESCPOS->new();
    my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    my $ret = $parser->parse(
        q#
        <escpos>
            <text wordwrap="10">advanced TeXT</text>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls}, [ [ text => 'advanced' ], [ text => 'TeXT' ], ], 'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <text wordwrap="39"
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.</text>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls},
        [
        [ text => 'Lorem ipsum dolor sit amet, consetetur', ],
        [ text => 'sadipscing elitr, sed diam nonumy', ],
        [ text => 'eirmod tempor invidunt ut labore et', ],
        [ text => 'dolore magna aliquyam erat, sed diam', ],
        [ text => 'voluptua. At vero eos et accusam et', ],
        [ text => 'justo duo dolores et ea rebum. Stet', ],
        [ text => 'clita kasd gubergren, no sea takimata', ],
        [ text => 'sanctus est Lorem ipsum dolor sit amet.', ],
        [ text => 'Lorem ipsum dolor sit amet, consetetur', ],
        [ text => 'sadipscing elitr, sed diam nonumy', ],
        [ text => 'eirmod tempor invidunt ut labore et', ],
        [ text => 'dolore magna aliquyam erat, sed diam', ],
        [ text => 'voluptua. At vero eos et accusam et', ],
        [ text => 'justo duo dolores et ea rebum. Stet', ],
        [ text => 'clita kasd gubergren, no sea takimata', ],
        [ text => 'sanctus est Lorem ipsum dolor sit amet.', ]
        ],
        'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <text
                wordwrap="60"
                bodystart="   "
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus</text>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls},
        [
        [ text => 'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed' ],
        [ text => '   diam nonumy eirmod tempor invidunt ut labore et dolore' ],
        [ text => '   magna aliquyam erat, sed diam voluptua. At vero eos et' ],
        [ text => '   accusam et justo duo dolores et ea rebum. Stet clita kasd' ],
        [ text => '   gubergren, no sea takimata sanctus' ],
        ],
        'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <text
                wordwrap="cx"
                bodystart="   "
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus</text>
        </escpos>
    #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong text tag usage: wordwrap attribute must be a positive integer',
        'correct error message';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <text
                wordwrap="37.9"
                bodystart="   "
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus</text>
        </escpos>
    #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong text tag usage: wordwrap attribute must be a positive integer',
        'correct error message';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
        <escpos>
            <text
                wordwrap="00"
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus</text>
        </escpos>
    #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong text tag usage: wordwrap attribute must be a positive integer',
        'correct error message';
};

subtest 'reset error message on parsing start' => sub {
    plan tests => 4;

    my $mockprinter = Mock::Printer::ESCPOS->new();
    my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    my $ret = $parser->parse(
        q#
            <escpos>
              <pold>bold text</pold>
              <underline>underlined text</underline>
            </escpos>
        #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'tag pold is not allowed', 'correct error message';

    $ret = $parser->parse(
        q#
        <escpos>
            <qr>Simple QR code</qr>
        </escpos>
    #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
};

subtest 'tabpositions' => sub {
    plan tests => 18;

    my $mockprinter = Mock::Printer::ESCPOS->new();
    my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    my $ret = $parser->parse(
        q#
          <escpos>
            <tabpositions>
              <tabposition>5</tabposition>
              <tabposition>9</tabposition>
              <tabposition>13</tabposition>
            </tabpositions>
          </escpos>
        #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls}, [ [ tabPositions => 5, 9, 13 ], ], 'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
          <escpos>
            <tabpositions>
              <tabposition>5</tabposition>
              <tabposition>9</tabposition>
              <tabposition>13</tabposition>
              <tabposition>17</tabposition>
              <tabposition>19</tabposition>
              <tabposition>24</tabposition>
              <tabposition>37</tabposition>
              <tabposition>49</tabposition>
            </tabpositions>
          </escpos>
        #
    );
    ok $ret => 'parsing successful';
    is $parser->errormessage(), undef, 'errormessage is empty';
    is_deeply $mockprinter->{calls}, [ [ tabPositions => 5, 9, 13, 17, 19, 24, 37, 49 ], ], 'XML translated correctly';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
          <escpos>
            <tabpositions>
            </tabpositions>
          </escpos>
        #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong tabpositions tag usage: must contain at least one tabposition tag as child',
        'correct error message';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
          <escpos>
            <tabpositions>
              <bold>123</bold>
              <tabposition>39</tabposition>
            </tabpositions>
          </escpos>
        #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong tabpositions tag usage: must not contain anything else than tabposition tags',
        'correct error message';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
          <escpos>
            <tabpositions>
              <tabposition>bdb</tabposition>
              <tabposition>39</tabposition>
            </tabpositions>
          </escpos>
        #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong tabposition tag usage: value must be a positive integer',
        'correct error message';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
          <escpos>
            <tabpositions>
              <tabposition>0</tabposition>
            </tabpositions>
          </escpos>
        #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong tabposition tag usage: value must be a positive integer',
        'correct error message';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
          <escpos>
            <tabpositions>
              <tabposition>
                <bold>
                  123
                </bold>
              </tabposition>
            </tabpositions>
          </escpos>
        #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong tabposition tag usage: value must be a positive integer',
        'correct error message';

    $mockprinter = Mock::Printer::ESCPOS->new();
    $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

    $ret = $parser->parse(
        q#
          <escpos>
            <tabpositions>127
              <tabposition>123</tabposition>
            </tabpositions>
          </escpos>
        #
    );
    is $ret, undef, 'parsing stopped';
    is $parser->errormessage() => 'wrong tabpositions tag usage: must not contain anything else than tabposition tags',
        'correct error message';

};

done_testing();

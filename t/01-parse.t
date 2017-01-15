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

    plan tests => 5;

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
};

subtest 'images' => sub {

    plan tests => 8;

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
    is_deeply $mockprinter->{calls}, [ [ image => 'header.gif' ] ], 'XML translated correctly';

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

done_testing();

#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;

{

    package MockPrinter;

    our $AUTOLOAD;

    sub new {
        return bless { calls => [], }, 'MockPrinter';
    }

    sub AUTOLOAD {
        my ( $self, @params ) = @_;
        my $method = $AUTOLOAD;
        $method =~ s/^.*?:://;
        push @{ $self->{calls} } => [ $method => @params ];
    }
}

subtest 'Simple parsing' => sub {
    plan tests => 3;

    my $mockprinter = MockPrinter->new();
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
              <color>
                <bold>This is printed with the second color (if supported)</bold>
              </color>
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
        [ color        => 1 ],
        [ bold         => 1 ],
        [ text         => 'This is printed with the second color (if supported)' ],
        [ bold         => 0 ],
        [ color        => 0 ],
        ],
        'XML translated correctly';
};

subtest 'undefined tags' => sub {
    plan tests => 2;

    my $mockprinter = MockPrinter->new();
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

    my $mockprinter = MockPrinter->new();
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

    $mockprinter = MockPrinter->new();
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

    my $mockprinter = MockPrinter->new();
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

    $mockprinter = MockPrinter->new();
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

    $mockprinter = MockPrinter->new();
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

subtest 'linefeed' => sub {

    #plan tests => 6;

    my $mockprinter = MockPrinter->new();
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

    $mockprinter = MockPrinter->new();
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

done_testing();

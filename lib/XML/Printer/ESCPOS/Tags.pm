package XML::Printer::ESCPOS::Tags;

use strict;
use warnings;

our $VERSION = '0.01';

=head2 new

Constructs a tags object.

=cut

sub new {
    my ( $class, %options ) = @_;
    return if not exists $options{printer} or not ref $options{printer};
    return if not exists $options{caller}  or not ref $options{caller};
    return bless {%options}, $class;
}

=head2 tag_allowed

Returns true if the given tag is defined.

=cut

sub tag_allowed {
    my ( $self, $method ) = @_;
    return !!grep { $method eq $_ } qw/
        0
        text
        bold
        underline
        qr
        utf8ImagedText
        lf
        doubleStrike
        invert
        color
        image
        printAreaWidth
        tab
        upsideDown
        rot90
        /;
}

=head2 parse( $element )

Method for recursive parsing of tags.

=cut

sub parse {
    my ( $self, $tags ) = @_;
    my @elements = @$tags;
    my $hashref  = shift @elements;
    if ( ref $hashref ne 'HASH' or %$hashref ) {
        return $self->{caller}->_set_error_message('first element should be an empty hashref ({})');
    }

    while (@elements) {
        my $tag  = shift @elements;
        my $data = shift @elements;
        return $self->{caller}->_set_error_message("tag $tag is not allowed") if not $self->tag_allowed($tag);
        my $method = '_' . $tag;
        $self->$method($data) or return;
    }
    return 1;
}

=head2 simple_switch

Helper method for simple 0/1 switches.

=cut

sub simple_switch {
    my ( $self, $method, $tags ) = @_;
    $self->{states}->{$method} //= 0;
    $self->{states}->{$method}++;
    $self->{printer}->$method(1) if $self->{states}->{$method} == 1;

    $self->parse($tags) or return;

    $self->{printer}->$method(0) if $self->{states}->{$method} == 1;
    $self->{states}->{$method}--;
    return 1;
}

=head2 _0

Prints plain text and strips out leading and trailing whitespaces.

=cut

sub _0 {
    my ( $self, $text ) = @_;
    $text =~ s/^\s+//gm;
    $text =~ s/\s+$//gm;
    $self->{printer}->text($text) if $text =~ /\S/;
    return 1;
}

=head2 _text

Prints plain text.

=cut

sub _text {
    my ( $self, $params ) = @_;
    return $self->{caller}->_set_error_message("wrong text tag usage") if @$params != 3;
    return $self->{caller}->_set_error_message("wrong text tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong text tag usage") if $params->[1] != 0;
    $self->{printer}->text( $params->[2] );
    return 1;
}

=head2 _bold

Sets text to be printed bold.

=cut

sub _bold {
    my $self = shift;
    return $self->simple_switch( 'bold', @_ );
}

=head2 _doubleStrike

Sets text to be printed double striked.

=cut

sub _doubleStrike {
    my $self = shift;
    return $self->simple_switch( 'doubleStrike', @_ );
}

=head2 _invert

Sets text to be printed inverted.

=cut

sub _invert {
    my $self = shift;
    return $self->simple_switch( 'invert', @_ );
}

=head2 _underline

Sets text to be printed underlined.

=cut

sub _underline {
    my $self = shift;
    return $self->simple_switch( 'underline', @_ );
}

=head2 _upsideDown

Sets Upside Down Printing.

=cut

sub _upsideDown {
    my $self = shift;
    return $self->simple_switch( 'upsideDown', @_ );
}

=head2 _color

Use this tag to use the second color (if support by your printer).

=cut

sub _color {
    my $self = shift;
    return $self->simple_switch( 'color', @_ );
}

=head2 _rot90

Use this tag to use the second color (if support by your printer).

=cut

sub _rot90 {
    my $self = shift;
    return $self->simple_switch( 'rot90', @_ );
}

=head2 _qr

Prints a QR code. Possible attributes:

=head3 ecc

=head3 version

=head3 moduleSize

=cut

sub _qr {
    my ( $self, $params ) = @_;
    return $self->{caller}->_set_error_message("wrong QR code tag usage") if @$params != 3;
    return $self->{caller}->_set_error_message("wrong QR code tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong QR code tag usage") if $params->[1] != 0;
    my $options = $params->[0];
    if (%$options) {
        $self->{printer}->qr( $params->[2], $options->{ecc} || 'L', $options->{version} || 5, $options->{moduleSize} || 3 );
    }
    else {
        $self->{printer}->qr( $params->[2] );
    }
    return 1;
}

=head2 _utf8ImagedText

Can print text with special styling.

=cut

sub _utf8ImagedText {
    my ( $self, $params ) = @_;
    return $self->{caller}->_set_error_message("wrong utf8ImagedText tag usage") if @$params != 3;
    return $self->{caller}->_set_error_message("wrong utf8ImagedText tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong utf8ImagedText tag usage") if $params->[1] != 0;
    my $options = $params->[0];
    if (%$options) {
        $self->{printer}->utf8ImagedText( $params->[2], map { $_ => $options->{$_} } sort keys %$options );
    }
    else {
        $self->{printer}->utf8ImagedText( $params->[2] );
    }
    return 1;
}

=head2 _lf

Moves to the next line.

=cut

sub _lf {
    my ( $self, $params ) = @_;
    return $self->{caller}->_set_error_message("wrong lf tag usage") if @$params != 1;
    return $self->{caller}->_set_error_message("wrong lf tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong lf tag usage") if %{ $params->[0] };
    $self->{printer}->lf();
    return 1;
}

=head2 _tab

Moves the cursor to next horizontal tab position.

=cut

sub _tab {
    my ( $self, $params ) = @_;
    return $self->{caller}->_set_error_message("wrong tab tag usage") if @$params != 1;
    return $self->{caller}->_set_error_message("wrong tab tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong tab tag usage") if %{ $params->[0] };
    $self->{printer}->tab();
    return 1;
}

=head2 _image

Print image from named file.

=cut

sub _image {
    my ( $self, $params ) = @_;

    # single tag form <image filename="image.jpg" />
    if ( @$params == 1 ) {
        return $self->{caller}->_set_error_message("wrong image tag usage") if ref $params->[0] ne 'HASH';
        return $self->{caller}->_set_error_message("wrong image tag usage") if scalar keys %{ $params->[0] } != 1;
        return $self->{caller}->_set_error_message("wrong image tag usage") if not exists $params->[0]->{filename};
        $self->{printer}->image( $params->[0]->{filename} );
        return 1;
    }

    # content tag form <image>image.jpg</image>
    return $self->{caller}->_set_error_message("wrong image tag usage") if @$params != 3;
    return $self->{caller}->_set_error_message("wrong image tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong image tag usage") if %{ $params->[0] };
    return $self->{caller}->_set_error_message("wrong image tag usage") if $params->[1] ne '0';

    $self->{printer}->image( $params->[2] );
    return 1;
}

=head2 _printAreaWidth

Sets the print area width.

=cut

sub _printAreaWidth {
    my ( $self, $params ) = @_;

    # single tag form <printAreaWidth width="255" />
    if ( @$params == 1 ) {
        return $self->{caller}->_set_error_message("wrong printAreaWidth tag usage") if ref $params->[0] ne 'HASH';
        return $self->{caller}->_set_error_message("wrong printAreaWidth tag usage") if scalar keys %{ $params->[0] } != 1;
        return $self->{caller}->_set_error_message("wrong printAreaWidth tag usage") if not exists $params->[0]->{width};
        $self->{printer}->printAreaWidth( $params->[0]->{width} );
        return 1;
    }

    # content tag form <printAreaWidth>255</printAreaWidth>
    return $self->{caller}->_set_error_message("wrong printAreaWidth tag usage") if @$params != 3;
    return $self->{caller}->_set_error_message("wrong printAreaWidth tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("wrong printAreaWidth tag usage") if %{ $params->[0] };
    return $self->{caller}->_set_error_message("wrong printAreaWidth tag usage") if $params->[1] ne '0';

    $self->{printer}->printAreaWidth( $params->[2] );
    return 1;
}

1;

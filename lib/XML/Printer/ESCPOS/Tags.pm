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

=head2 simple_switch

Helper method for simple 0/1 switches.

=cut

sub simple_switch {
    my ( $self, $method, $tags ) = @_;
    $self->{states}->{$method} //= 0;
    $self->{states}->{$method}++;
    $self->{printer}->$method(1) if $self->{states}->{$method} == 1;

    $self->parse($tags);

    $self->{printer}->$method(0) if $self->{states}->{$method} == 1;
    $self->{states}->{$method}--;
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
        my $method = '_' . ( $tag || 'text' );
        $self->$method($data);
    }
    return 1;
}

=head2 tag_allowed

Returns true if the given tag is defined.

=cut

sub tag_allowed {
    my ( $self, $method ) = @_;
    return !!grep { $method eq $_ } qw/
        0
        bold
        underline
        qr
        /;
}

=head2 _text

Prints plain text.

=cut

sub _text {
    my ( $self, $text ) = @_;
    $self->{printer}->text($text) if $text =~ /\S/;
}

=head2 _bold

Sets text to be printed bold.

=cut

sub _bold {
    my $self = shift;
    $self->simple_switch( 'bold', @_ );
}

=head2 _underline

Sets text to be printed underlined.

=cut

sub _underline {
    my $self = shift;
    $self->simple_switch( 'underline', @_ );
}

=head2 _qr

Prints a QR code. Possible attributes:

=head3 ecc

=head3 version

=head3 moduleSize

=cut

sub _qr {
    my ( $self, $params ) = @_;
    return $self->{caller}->_set_error_message("Wrong QR code tag usage") if @$params != 3;
    return $self->{caller}->_set_error_message("Wrong QR code tag usage") if ref $params->[0] ne 'HASH';
    return $self->{caller}->_set_error_message("Wrong QR code tag usage") if $params->[1] != 0;
    my $options = $params->[0];
    if (%$options) {
        $self->{printer}->qr( $params->[2], $options->{ecc} || 'L', $options->{version} || 5, $options->{moduleSize} || 3 );
    }
    else {
        $self->{printer}->qr( $params->[2] );
    }
}

1;

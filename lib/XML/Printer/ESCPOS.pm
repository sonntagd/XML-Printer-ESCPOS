package XML::Printer::ESCPOS;

use 5.010;
use strict;
use warnings;
use XML::Parser;
use XML::Printer::ESCPOS::Tags;

=head1 NAME

XML::Printer::ESCPOS - An XML parser for generating ESCPOS output.

=head1 DESCRIPTION

This module provides a markup language that describes what your ESCPOS printer should do.
It works on top of the great and easy to use L<Printer::ESCPOS>. Now you can save your printer
output in an XML file and you can write templates to be processed by Template Toolkit or the
template engine of your choice.

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Printer::ESCPOS;
    use XML::Printer::ESCPOS;

    # connect to your printer, see Printer::ESCPOS for more examples
    my $printer_id = '192.168.0.10';
    my $port       = '9100';
    my $device = Printer::ESCPOS->new(
        driverType => 'Network',
        deviceIp   => $printer_ip,
        devicePort => $port,
    );

    my $parser = XML::Printer::ESCPOS->new(printer => $device->printer);
    $parser->parse(q#
    <escpos>
        <bold>bold text</bold>
        <underline>underlined text</underline>
    </escpos>
    #) or die "Error parsing ESCPOS XML file: ".$parser->errormessage;

=head1 METHODS

=head2 new(printer => $printer)

Constructs a new XML::Printer::ESCPOS object. You must provide a printer object you
get by C<Printer::ESCPOS->new(...)->printer>.

=cut

sub new {
    my ( $class, %options ) = @_;
    return if not exists $options{printer} or not ref $options{printer};
    return bless {%options}, $class;
}

=head2 parse($xml)

Parses the XML data given by C<$xml>. C<$xml> should contain the file content.
Returns 1 on success, undef otherwise. If parsing was unsuccessful, you can find the
errormessage by calling the C<errormessage> method.

=cut

sub parse {
    my ( $self, $xml ) = @_;
    my $printer = $self->{printer};

    my $xmlparser = XML::Parser->new( Style => 'Tree', );
    my $tree = $xmlparser->parse($xml);

    return _set_error_message('not document found')                                            if !@{$tree};
    return _set_error_message('more than one base tag found')                                  if @{$tree} > 2;
    return _set_error_message('document is not an ESCPOS doc (start document with <escpos>!)') if $tree->[0] ne 'escpos';

    my $tags = XML::Printer::ESCPOS::Tags->new(
        printer => $self->{printer},
        caller  => $self,
    );

    return $tags->parse( $tree->[1] );
}

=head2 errormessage

Returns the last error message.

=cut

sub errormessage {
    my $self = shift;
    return $self->{errormessage};
}

=head1 INTERNAL METHODS

=head2 _set_error_message( $message )

Internal method to set the error message in the object before the parser returns.

=cut

sub _set_error_message {
    my ( $self, $message ) = @_;
    $self->{errormessage} = $message;
    return;
}

=head1 AUTHOR

Dominic Sonntag, C<< <dominic at s5g.de> >>

=head1 BUGS

Please report any bugs or feature requests by opening an issue on Github:
L<https://github.com/sonntagd/XML-Printer-ESCPOS/issues>


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Dominic Sonntag.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;    # End of XML::Printer::ESCPOS

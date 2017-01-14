package XML::Printer::ESCPOS;

use 5.010;
use strict;
use warnings;
use XML::Parser;
use XML::Printer::ESCPOS::Tags;

=head1 NAME

XML::Printer::ESCPOS - An XML parser for generating ESCPOS output.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

You can define

Perhaps a little code snippet.

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

    my $printer = $device->printer();

    my $parser = XML::Printer::ESCPOS->new(printer => $printer);
    $parser->parse(<<DOCEND);
    <document>
        
    </document>
    DOCEND

=head1 METHODS

=head2 new

Constructs a new XML::Printer::ESCPOS object.

=cut

sub new {
    my ( $class, %options ) = @_;
    return if not exists $options{printer} or not ref $options{printer};
    return bless {%options}, $class;
}

=head2 parse

Parses the 

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

Please report any bugs or feature requests to C<bug-xml-printer-escpos at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Printer-ESCPOS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Printer::ESCPOS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Printer-ESCPOS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Printer-ESCPOS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Printer-ESCPOS>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Printer-ESCPOS/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Dominic Sonntag.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of XML::Printer::ESCPOS

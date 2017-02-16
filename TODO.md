# Improvement ideas for XML::Printer::ESCPOS

This document tries to summarize what needs to be done to make `XML::Printer::ESCPOS` a module that is easy to use.

## Implement Printer::ESCPOS methods

* font
* justify
* fontHeight
* fontWidth
* charSpacing
* lineSpacing
* selectDefaultLineSpacing
* printPosition
* leftMargin
* printNVImage
* printImage

The following methods could be implemented, but are not really content methods:

* cutPaper
* print

## Ideas for convenience functions

* Add special tag(s) for creating table-like prints. This could be useful for receipt printing, for example. It should contain automatic word wrapping or automatic cropping of long texts.
* Add horizontal line tag `<hr />`
* Add option to send calls to printer object only after the full document was parsed. This would allow to signal illegal document structure before sending anything to the printer object.
* Add repeat tag: `<repeat times="69"><text> </text></repeat>` would print a horizontal line. The repeat tag could contain everything and would parse the content n times.

## Documentation

Add documentation describing the XML structure to use. By now you can find examples in the test suite, especially in the file `t/01-parse.t`.

## SUPPORT AND BUGS

Please report any bugs or feature requests by opening an [issue on Github](https://github.com/sonntagd/XML-Printer-ESCPOS/issues).

## LICENSE AND COPYRIGHT

Copyright (C) 2017 Dominic Sonntag.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

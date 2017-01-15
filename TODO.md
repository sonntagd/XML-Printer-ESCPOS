# TODO - XML::Printer::ESCPOS

This document tries to summarize what needs to be done to make `XML::Printer::ESCPOS` a module that is easy to use.

## Implement Printer::ESCPOS methods

* tabPositions
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

## Ideas for convenience functions

* Add number of lines to `<lf />` like `<lf lines="3" />`

## SUPPORT AND BUGS

Please report any bugs or feature requests by opening an [issue on Github](https://github.com/sonntagd/XML-Printer-ESCPOS/issues).

## LICENSE AND COPYRIGHT

Copyright (C) 2017 Dominic Sonntag.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0
use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'XML::Printer::ESCPOS',
    AUTHOR             => q{Dominic Sonntag <dominic@s5g.de>},
    VERSION_FROM       => 'lib/XML/Printer/ESCPOS.pm',
    ABSTRACT_FROM      => 'lib/XML/Printer/ESCPOS.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.010,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => { 'Test::More' => 0, },
    PREREQ_PM          => { 'XML::Parser' => 0, },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'XML-Printer-ESCPOS-*' },
);

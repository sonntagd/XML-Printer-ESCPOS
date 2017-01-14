FROM perl:5.24

MAINTAINER Dominic Sonntag <dominic@s5g.de>

RUN cpanm XML::Parser
RUN cpanm Test::CheckManifest
RUN cpanm Test::Pod::Coverage
RUN cpanm Test::Pod
RUN cpanm DDP
RUN cpanm Moo

RUN mkdir /app

WORKDIR /app

COPY . /app/


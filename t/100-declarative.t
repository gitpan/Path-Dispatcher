#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;

my @calls;

do {
    package MyApp::Dispatcher;
    use Path::Dispatcher::Declarative -base;

    on qr/(b)(ar)(.*)/ => sub {
        push @calls, [$1, $2, $3];
    };

    rewrite quux => 'bar';
    rewrite qr/^quux-(.*)/ => sub { "bar:$1" };
};

ok(MyApp::Dispatcher->isa('Path::Dispatcher::Declarative'), "use Path::Dispatcher::Declarative sets up ISA");

can_ok('MyApp::Dispatcher' => qw/dispatcher dispatch run/);
MyApp::Dispatcher->run('foobarbaz');
is_deeply([splice @calls], [
    [ 'b', 'ar', 'baz' ],
]);

MyApp::Dispatcher->run('quux');
is_deeply([splice @calls], [
    [ 'b', 'ar', '' ],
]);

MyApp::Dispatcher->run('quux-hello');
is_deeply([splice @calls], [
    [ 'b', 'ar', ':hello' ],
]);


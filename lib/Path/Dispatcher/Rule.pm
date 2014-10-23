#!/usr/bin/env perl
package Path::Dispatcher::Rule;
use Moose;

use Path::Dispatcher::Stage;

has block => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

sub match {
    my $self = shift;
    my $path = shift;

    my $result = $self->_match($path);
    return unless $result;

    # make sure that the returned values are PLAIN STRINGS
    # later we will stick them into a regular expression to populate $1 etc
    # which will blow up later!

    if (ref($result) eq 'ARRAY') {
        for (@$result) {
            die "Invalid result '$_', results must be plain strings"
                if ref($_);
        }
    }

    return $result;
}

sub run {
    my $self = shift;

    $self->block->(@_);
}

__PACKAGE__->meta->make_immutable;
no Moose;

# don't require others to load our subclasses explicitly
require Path::Dispatcher::Rule::CodeRef;
require Path::Dispatcher::Rule::Regex;
require Path::Dispatcher::Rule::Tokens;

1;


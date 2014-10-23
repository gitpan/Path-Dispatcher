#!/usr/bin/env perl
package Path::Dispatcher::Dispatch;
use Moose;
use MooseX::AttributeHelpers;

use Path::Dispatcher::Dispatch::Match;

sub match_class { 'Path::Dispatcher::Dispatch::Match' }

has _matches => (
    metaclass => 'Collection::Array',
    is        => 'rw',
    isa       => 'ArrayRef[Path::Dispatcher::Dispatch::Match]',
    default   => sub { [] },
    provides  => {
        push     => '_add_match',
        elements => 'matches',
        count    => 'has_matches',
    },
);

sub add_redispatches {
    my $self       = shift;
    my @dispatches = @_;

    for my $dispatch (@dispatches) {
        for my $match ($dispatch->matches) {
            $self->add_match($match);
        }
    }
}

sub add_match {
    my $self = shift;

    my $match;

    # they pass in an already instantiated match..
    if (@_ == 1 && blessed($_[0])) {
        $match = shift;
    }
    # or they pass in args to create a match..
    else {
        $match = $self->match_class->new(@_);
    }

    $self->_add_match($match);
}

sub run {
    my $self = shift;
    my @args = @_;
    my @matches = $self->matches;

    while (my $match = shift @matches) {
        eval {
            local $SIG{__DIE__} = 'DEFAULT';

            $match->run(@args);

            die "Path::Dispatcher abort\n"
                if $match->ends_dispatch($self);
        };

        if ($@) {
            return if $@ =~ /^Path::Dispatcher abort\n/;
            next if $@ =~ /^Path::Dispatcher next rule\n/;

            die $@;
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;


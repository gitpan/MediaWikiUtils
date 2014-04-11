#
# This file is part of MediaWikiUtils
#
# This software is copyright (c) 2014 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MediaWikiUtils::Convert;
{
  $MediaWikiUtils::Convert::VERSION = '0.141011';
}

use strict;
use warnings;

use Moo;
use MooX::Cmd;
use MooX::Options;

use Carp;

use pQuery;
use Text::Unaccent::PurePerl qw(unac_string);

#ABSTRACT: A tools provide few method to convert MediaWiki to another wiki engine

option 'directory' => (
    is       => 'ro',
    format   => 's',
    default  => sub { '.' },
    doc      => 'The password to login on the mediawiki'
);

sub mediawiki2dokuwiki {
    my ( $self ) = @_;

    my $all_articles = $self->_mediawiki->list({
        action => 'query',
        list   => 'allpages'
    });

    foreach my $page (@{$all_articles}) {
        my $article = $self->_mediawiki->get_page({
            title => $page->{title}
        });

        my $title    = $page->{title};
        my $response = $self->_user_agent->post(
            'http://johbuc6.coconia.net/mediawiki2dokuwiki.php',
            [mediawiki => $article->{'*'}]
        );
        my $file = $self->_generate_file_name($title);

        if ( ! $response->is_success ) {
            carp "Request for $title failed: " . $response->status_line;
            next;
        }

        print 'Export the page ' . $page->{title} . " in the $file", "\n";
        pQuery($response->content)
            ->find('textarea[name=dokuwiki]')
            ->each(sub {
                my $count = shift;
                $self->_write_file($file, pQuery($_)->html());
        });
    }

    return;
}

sub _generate_file_name {
    my ( $self, $title ) = @_;

    $title =~  s/\s/_/g;
    $title =~  s/'/_/g;

    return unac_string($title) . '.txt';
}

sub _write_file {
    my ( $self, $file, $content ) = @_;

    my $path = $self->directory . '/' . $file;
    my $fh   = IO::File->new($path, "w");

    if ( defined($fh) ) {
        print $fh $content;

        undef $fh;
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MediaWikiUtils::Convert - A tools provide few method to convert MediaWiki to another wiki engine

=head1 VERSION

version 0.141011

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

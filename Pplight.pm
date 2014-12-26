package Pplight;

use strict;
use warnings;
use Exporter;

use File::Slurp;

our $VERSION     = 0.1;
our @ISA         = qw(Exporter);
our @EXPORT      = qw(pp_light pp_light_file);

my %default_opt =
    ( trigraphs => 0,
      bsnl => 1,
      strip_comments => 1,
      if0 => 0,
      strip_trailing => 1,
    );

sub pp_light_file {
    my $filename = shift;
    my $source = read_file($filename, {err_mode => 'quiet'});
    return undef unless defined $source;
    return pp_light($source);
}

sub pp_light {
    my $source = shift;
    my %opt = (%default_opt, %{shift // {}});

    $source = replace_trigraphs($source)
	if $opt{trigraphs};

    $source =~ s/\\\n//g
	if $opt{bsnl};

    $source = strip_comments($source)
	if $opt{strip_comments};

    $source =~ s/[ \t]*(?=\n)//g
	if $opt{strip_trailing};

    return $source;
}


sub replace_trigraphs {
    my %trigraphs = ( "??=" => '#', "??/" => '\\', "??'" => '^',
		      "??(" => '[', "??)" => ']', "??!" => '|',
		      "??<" => '{', "??>" => '}', "??-" => '~' );
    my $src = shift;
    $src =~ s/(\?\?[=\/'()!<>-])/$trigraphs{$1}/g;
    return $src;
}




sub strip_comments {
    my $src = shift;

    # http://stackoverflow.com/a/911583/722859
    $src =~ s{
		 /\*         ##  Start of /* ... */ comment
		 [^*]*\*+    ##  Non-* followed by 1-or-more *'s
		 (?:
		     [^/*][^*]*\*+
		 )*          ##  0-or-more things which don't start with /
		 ##    but do end with '*'
		 /           ##  End of /* ... */ comment

	     |
		 //     ## Start of // comment
		 [^\n]* ## Anything which is not a newline
		 (?=\n) ## End of // comment; use look-ahead to avoid consuming the newline

	     |         ##     OR  various things which aren't comments:

		 (
		     "           ##  Start of " ... " string
		     (?:
			 \\.           ##  Escaped char
		     |               ##    OR
			 [^"\\]        ##  Non "\
		     )*
		     "           ##  End of " ... " string

		 |         ##     OR

		     '           ##  Start of ' ... ' string
		     (
			 \\.           ##  Escaped char
		     |               ##    OR
			 [^'\\]        ##  Non '\
		     )*
		     '           ##  End of ' ... ' string

		 |         ##     OR

		     .           ##  Anything other char
		     [^/"'\\]*   ##  Chars which doesn't start a comment, string or escape
		 )
	 }{defined $1 ? $1 : " "}gxse;

    return $src;
}



1;

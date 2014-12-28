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
      if0 => 1,
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

    $source .= "\n" if ($source ne '' && substr($source, -1) ne "\n");

    $source = replace_trigraphs($source)
	if $opt{trigraphs};

    $source =~ s/\\\n//g
	if $opt{bsnl};

    $source .= "\n" if ($source ne '' && substr($source, -1) ne "\n");

    $source = strip_comments($source)
	if $opt{strip_comments};

    $source = remove_if0($source)
	if $opt{if0};

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


# elifs are simple: delete everything from the elif up to but not
# including the terminating elif, else or endif.
#
# ... #elif 0, xxx, #elif yyy, zzz ==> ... #elif yyy, zzz
# ... #elif 0, xxx, #endif         ==> ... #endif
# ... #elif 0, xxx, #else, yyy     ==> ... #else, yyy
#
# ifs are a little more complicated
#
# #if 0, xxx, #else, yyy  ==> #if 1, yyy
# #if 0, xxx, #elif yyy, zzz ==> #if yyy, zzz
# #if 0, xxx, #endif ==> (nothing)

sub remove_if0 {
    my $src = shift;
    return '' if ($src eq '');

    my @lines = split /\n/, $src;

    for (my $i = 0; $i < @lines; ++$i) {
	next unless ($lines[$i] =~ m/^\s*#\s*(el)?if\s+0\s*$/);
	my $elif = defined $1;
	my $nest = 0;
	my ($j, $end, $trail);

	for ($j = $i + 1; $j < @lines; ++$j) {
	    next unless $lines[$j] =~ m/^\s*#/;
	    if ($lines[$j] =~ m/^\s*#\s*if(?:n?def)?\s+/) {
		$nest++;
		next;
	    }
	    if ($nest > 0 && $lines[$j] =~ m/^\s*#\s*endif\b/) {
		$nest--;
		next;
	    }
	    next unless $nest == 0;
	    if ($lines[$j] =~ m/^\s*#\s*(else|elif|endif)\b(.*)$/) {
		$end = $1;
		$trail = $2;
		last;
	    }
	}
	if ($j >= @lines) {
	    printf STDERR "warning: unmatched #%s at line %d\n", $elif ? "elif" : "if", $i+1;
	    last;
	}
	if ($elif) {
	    splice @lines, $i, ($j-$i);
	} else {
	    if ($end eq 'else') {
		splice @lines, $i, (1+$j-$i), "#if 1";
	    } elsif ($end eq 'elif') {
		splice @lines, $i, (1+$j-$i), "#if$trail";
	    } else {
		splice @lines, $i, (1+$j-$i), "";
	    }
	}
	# We may have introduced a new #if 0, so check the same $i on the next iteration.
	--$i;
    }

    $src = join("\n", @lines) . "\n";
    return $src;
}


1;

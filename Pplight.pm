package Pplight;

use strict;
use warnings;
use Exporter;

use File::Slurp;

use overload
    '""' => sub { $_[0]->{src}; },
    '@{}' => sub { [split /^/, $_[0]->{src}]; };

our $VERSION     = 0.2;

my %default_opt =
    ( trigraphs => 0,
      bsnl => 1,
      strip_comments => 1,
      if0 => 1,
      strip_trailing => 1,
    );

sub new {
    my $class = shift;
    my $src = shift;
    my $opt = shift;

    if ($src ne '' && $src !~ m/\n/) {
	return file($class, $src, $opt);
    } else {
	return string($class, $src, $opt);
    }
}

sub file {
    my $class = shift;
    my $fn = shift;
    my $opt = shift;
    my $src = read_file($fn, {err_mode => 'quiet'});
    return undef unless defined $src;
    my $pp = { file => $fn, orig_src => $src };
    return do_pp_light($class, $pp, $opt);
}

sub string {
    my $class = shift;
    my $str = shift;
    my $opt = shift;
    my $pp = { file => "<string>", orig_src => $str };
    return do_pp_light($class, $pp, $opt);
}

sub do_pp_light {
    my $class = shift;
    my $self = shift;
    my %opt = (%default_opt, %{shift // {}});

    bless $self, $class;
    $self->{src} = $self->{orig_src};
    $self->{src} .= "\n" if ($self->{src} ne '' && substr($self->{src}, -1) ne "\n");

    $self->replace_trigraphs()
	if $opt{trigraphs};

    $self->bsnl()
	if $opt{bsnl};

    $self->{src} .= "\n" if ($self->{src} ne '' && substr($self->{src}, -1) ne "\n");

    $self->strip_comments()
	if $opt{strip_comments};

    $self->remove_if0()
	if $opt{if0};

    $self->strip_trailing()
	if $opt{strip_trailing};

    return $self;
}

sub replace_trigraphs {
    my $self = shift;
    my %trigraphs = ( "??=" => '#', "??/" => '\\', "??'" => '^',
		      "??(" => '[', "??)" => ']', "??!" => '|',
		      "??<" => '{', "??>" => '}', "??-" => '~' );
    $self->{src} =~ s/(\?\?[=\/'()!<>-])/$trigraphs{$1}/g;
    return $self;
}

sub bsnl {
    my $self = shift;
    $self->{src} =~ s/\\\n//g;
    return $self;
}

sub strip_comments {
    my $self = shift;

    # http://stackoverflow.com/a/911583/722859
    $self->{src} =~ s{
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

    return $self;
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
    my $self = shift;
    return $self if ($self->{src} eq '');

    my @lines = split /\n/, $self->{src};

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

    $self->{src} = join("\n", @lines) . "\n";
    return $self;
}

sub strip_trailing {
    my $self = shift;
    $self->{src} =~ s/[ \t]*(?=\n)//g;
    return $self;
}

1;

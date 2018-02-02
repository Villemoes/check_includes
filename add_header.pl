#!/usr/bin/perl
#
# Author: Rasmus Villemoes

use strict;
use warnings;

use File::Slurp;
use Getopt::Long;

my $header;
my @after;

GetOptions("header=s"  => \$header,
           "after=s"   => \@after,
	  ) or usage();

if (!$header) {
    $header = shift or usage();
}
my @unhandled;

sub add_header {
    my $txt = shift;
    return (0, undef) if $txt =~ m/^[ \t]*#[ \t]*include[ \t]+<$header>/m;

    # Preferably add the #include immediately after an #include of the
    # "parent" from which we wish to remove $header,
    # e.g. add linux/log2.h after linux/kernel.h.
    for (@after) {
	if ($txt =~ s/((?:^[ \t]*#[ \t]*include[ \t]+<$_>.*\n)+)/$1#include <$header>\n/m) {
	    return (1, $txt);
	}
    }
    # Otherwise, add the #include after the first block of includes of linux/*.
    if ($txt =~ s/((?:^[ \t]*#[ \t]*include[ \t]+<linux.*>.*\n)+)/$1#include <$header>\n/m) {
	return (1, $txt);
    }
    return (undef, undef);
}

for my $file (@ARGV) {
    1 while ($file =~ s@^\./@@);
    next if $file =~ m@^(Documentation|scripts|tools)/@;
    my $txt = read_file($file);
    my $result;

    ($result, $txt) = add_header($txt);

    if (!defined $result) {
	push @unhandled, $file;
    } elsif ($result) {
	write_file($file, $txt);
    }
}

if (@unhandled) {
    print "Unable to handle these files:\n";
    print "  $_\n" for (@unhandled);
}

sub usage {
    print "usage: $0 --header linux/foo.h [--after linux/kernel.h [...]]";
    exit(1);
}

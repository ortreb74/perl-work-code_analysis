#!/usr/bin/env perl

use strict;
use warnings;

my $program = "hulkliv";
my $inputFileName = "in/$program";

my $grepPattern = "makeblocs_v2.bal";

print "Lecture du fichier : $inputFileName\n";
open (my $inputFile, '<', $inputFileName) or die "Could not open file $inputFileName";

while (my $line = <$inputFile>) {	
	if (!($line =~ /^\s*#/)) {
		if ($line =~ /$grepPattern(.*)/) {
			print $1 . "\n";
		}	
	}
}
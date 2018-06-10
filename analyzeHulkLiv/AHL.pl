#!/usr/bin/env perl

use strict;
use warnings;

# egrep "^\w+:" bin/hulkliv

my $inputFileName = "StepOneAction.java";

my $outputFileName = "out.txt";

open (my $inputFile, '<', $inputFileName) or die "Could not open file $inputFileName";
open (my $outputFile, '>', $outputFileName) or die "Could not open file $outputFileName";

# il y a un premier bloc, jusqu'au premier mot clef "set"
# puis il y a un deuxième bloc jusqu'au premier arg et qui se termine à end 

my $step = 1;
my @words;
my $next = 0;

while (my $line = <$inputFile>) {	
	if ($line =~ /setDestination/) {
		print $outputFile $line;
		$next =  !($line =~ /\)/);			
	} elsif ($next) {
		print $outputFile $line;
		$next =  !($line =~ /\)/);			
	}
	
}

close ($inputFile);
close ($outputFile);

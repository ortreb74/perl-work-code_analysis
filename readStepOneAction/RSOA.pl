#!/usr/bin/env perl
# ReadStepOneAction

# deux parties dans le programme
# 1 

use strict;
use warnings;

my $inputFileName = "in/StepOneAction.java";
my $outputFileName = "out/out.txt";

print "Lecture du fichier : $inputFileName\n";
open (my $inputFile, '<', $inputFileName) or die "Could not open file $inputFileName";
print "Ecriture du fichier : $outputFileName\n";
open (my $outputFile, '>', $outputFileName) or die "Could not open file $outputFileName";

my $step = 1;
my @words;
my $next = 0;

while (my $line = <$inputFile>) {	
	# cette ligne ignore les commentaires
	if ($line =~ /\/\//) {
		next;
	}
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

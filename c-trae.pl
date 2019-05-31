#!/usr/bin/env perl

use strict;
use warnings;

# https://perldoc.perl.org/Term/ANSIColor.html
use Term::ANSIColor;

# in  : a three column analyzed table

# @indlede : liste des mots qui marquent l'ouverture d'un bloc
# @lukke : liste des mots qui marquent la fermeture d'un bloc

my %indlede = ( "{" => 1);
my %lukke = ( "}" => -1);
my @rake = ("else");
my @linet = ("else\.\*;\\s*\$");

# $dybde : profondeur déduite des deux précédents

my $dybde = 0;

# out : TBD ?

my $inputFileName = "out/analysis_table.txt";
my $outputFileName = "out/trae.txt";

print "Lecture du fichier : $inputFileName\n";
open (my $inputFile, '<', $inputFileName) or die "Could not open file $inputFileName";

print "Ecriture du fichier : $outputFileName\n";
open (my $outputFile, '>', $outputFileName) or die "Could not open file $outputFileName";

my $line = "";
while ($line = <$inputFile>) {	
	## lecture de la table
	
	my @columns = split("\t",$line);
	
	if ($#columns < 2) {
		print $line;
		next;
	}
	
	my $lineNumber = $columns[0];
	my $type = $columns[1];	
	
	my $code_line = "";	
	
	# il faut reconstituer la ligne de code qui à l'origine pouvait comporter des \t	
	for (my $i = 2 ; $i < $#columns ; $i++) {						
		$code_line .= "\t" . $columns[$i];
	}
	$code_line .= $columns[$#columns];
	
	## calcul de la profondeur
	my $delta_dybde = 0;	
	if ($type eq "code") {
		
		my $flag = 1;
		
		for (my $offset = 0 ; $offset < length($code_line); $offset++) {
			my $char = substr($code_line, $offset, 1);
			
			if ($char eq "{" && $flag) {
				$dybde += 1;
			}
			
			if ($char eq "}" && $flag) {
				$dybde -= 1;
			}
			
			$flag =  ! ($char eq "/");
		}			
	}	
	
	print $outputFile $lineNumber . "\t" . $type . "\t" . $dybde . "\t" . $code_line;		
	
	$dybde += $delta_dybde;
}

if ($dybde != 0) {
	print color('bold red');
	print "Profondeur finale : $dybde\n";
	print color('reset');
}
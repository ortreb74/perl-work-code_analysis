#!/usr/bin/env perl

use strict;
use warnings;

# https://perldoc.perl.org/Term/ANSIColor.html
use Term::ANSIColor;

# in  : a three column analyzed table

# @indlede : liste des mots qui marquent l'ouverture d'un bloc
# @lukke : liste des mots qui marquent la fermeture d'un bloc

my %indlede = ( "class" => 0, "def" => 0, "do" => 0, "case" => 0, "while" => 0);
my %lukke = ( "end" => -1);
my %rake = ();
my %leading_openings = ( "if" => 0 );

# $dybde : profondeur déduite des deux précédents

my $dybde = 0;

my $inputFileName = "var/qualified_code_first.txt";
my $outputFileName = "var/qualified_code_final.txt";

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
	# qui seront perdus par le split de la ligne 37
	for (my $i = 2 ; $i < $#columns ; $i++) {						
		$code_line .= "\t" . $columns[$i];
	}
	$code_line .= $columns[$#columns];

	## calcul de la profondeur
	my $delta_dybde = 0;
	
	if ($code_line =~ /^\s*if /) {
		$dybde += 1;
		goto REPORT;
	}
	

	if ($type eq "code") {
		my @words = split(" ",$code_line);	
		
		if (exists ($leading_openings{$words[0]})) {
			$dybde += 1;
			goto REPORT;
		} 
		
		foreach my $word (@words) {
			if (exists ($rake{$word})) {
				# le mot est ignoré quand il fait partie
				# d'un mot clef rateau
				last;
			}
			
			if (exists ($indlede{$word})) {
				$dybde += 1;
				last;
			}
			
			if (exists ($lukke{$word})) {
				$delta_dybde -= 1;
				last;
			}			
		}		
	}	
	
REPORT:
	print $outputFile $lineNumber . "\t" . $type . "\t" . $dybde . "\t" . $code_line;		
	
	$dybde += $delta_dybde;
}

if ($dybde != 0) {
	print color('bold red');
	print "Profondeur finale : $dybde\n";
	print color('reset');
}
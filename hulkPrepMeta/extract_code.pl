#!/usr/bin/env perl

use strict;
use warnings;

# in  : an table-analysis of the code
# out : an extraction of the code

# column 1 : # : line number of the source file
# column 2 : type of the column : comment / log (echo)  / code / internal function call / external function
# column 3 : function : context | code
# column 4 : bloc : this is an id that define a logical group of the script
# column 5 : value


my $script = "hulk_prepactuel";

my $inputFileName = "$script/out/analysis_table.txt";
my $outputFileName = "$script/out/extracted_code.txt";

print "Lecture du fichier : $inputFileName\n";
open (my $inputFile, '<', $inputFileName) or die "Could not open file $inputFileName";
print "Ecriture du fichier : $outputFileName\n";
open (my $outputFile, '>', $outputFileName) or die "Could not open file $outputFileName";

while (my $line = <$inputFile>) {		
	my @columns = split("\t",$line);
	
	if ($#columns < 4) {
		print $line;
		continue;
	}
	
	if ($columns[1] eq "code") {
		# il faut reconstituer la ligne de code
		# qui à l'origine pouvait comporter des \t
		my $code_line = "";
		
		for (my $i = 4 ; $i < $#columns ; $i++) {						
			$code_line .= "\t" . $columns[$i];
		}
		
		$code_line .= $columns[$#columns];

		print $outputFile $columns[0] . "\t" . $code_line;
		
	}
}
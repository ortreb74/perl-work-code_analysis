//------------------------------------------------------------------------------
// Auteur : Yann Truchot
// Date creation : 10/03/2003
//-------------------------------------------------------------------------------
// Ce programme constitue des fichiers SGML correspondants a des "blocs" de
// textes ou jurisprudences, ces textes et jrp etant classes au sein du bloc
// dans le meme ordre que celui utilise pour les index
//
// les blocs sont constitues par annee (+un bloc pour les "sans date")
//
// les fichiers utilises sont :
// $ELA_DATA/idxtxt/optj/dpxx_indtxt.optj.sgm
// $ELA_DATA/idxjrp/optj/dpxx_indjrp.optj.sgm
// $ELA_DATA/txt/optj/*.optj.sgm
// $ELA_DATA/jrp/optj/*.optj.sgm
//
// les blocs crees repondent aux DTD TXTBLOC-OPTJ et DECISBLOC-OPTJ
// et se trouvent dans :
// $ELA_DATA/txtblocs/dpxx_txtbloc_*.optj.sgm
// $ELA_DATA/jrpblocs/dpxx_jrpbloc_*.optj.sgm
//-------------------------------------------------------------------------------
// MODIF DU 06-12-2003 AHMED LAZREG
// 
// Ajout traitement du dp15
//
// Dans le main :
// sIdxfile = $ELA_DATA/comjrp/optj/comjrp.optj.sgm
// sDtdfile = $ELA_DTD/comjrp-optj.dtd
//
// fonction createBlocs :
// ajout parametre eladico
// ajout condition if eladico == "dp15"
//-------------------------------------------------------------------------------
// YTR 23/01/2004 : suppression automatique des blocs vides
//-------------------------------------------------------------------------------
// YTR 22/09/2004 : correction bug dans suppression automatique blocs vides
//-------------------------------------------------------------------------------
// YTR 24/12/2004 : dp01 : on vire les txt boi des blocs txt "normaux"
//-------------------------------------------------------------------------------
// YTR 27/12/2004 : dp01 : on gere la creation du bloc txt BOI (en test)
//-------------------------------------------------------------------------------
// YTR 27/06/2005 : creation de niveaux BLOCMOIS
//-------------------------------------------------------------------------------
// YTR 21/07/2005 : correction bug BLOCMOIS vide (arrivait si le bloc ne contenait
//                  en fait aucun texte, car uniquement références à ADIDX)
//-------------------------------------------------------------------------------
// YTR 10/02/2006 : gestion des blocs ELNET à partir des index optj des autres DP
//-------------------------------------------------------------------------------
// YTR 18/09/2007 : gestion des blocs ELNET à partir des maps dico_decis&dico_txt
//-------------------------------------------------------------------------------
// YTR 07/01/2008 : gestion des blocs ELNET à partir des maps maptxt.map et mapjrp.map
//-------------------------------------------------------------------------------
// YTR 30/07/2008 : gestion des blocs à partir de l'option "month" ("month" par défaut pour ELNET, "year" pour le reste)
//-------------------------------------------------------------------------------
// YTR 28/07/2010 : gestion des blocs jrp "EJP", ajout option "-ejp"
//-------------------------------------------------------------------------------
// MJE 22/11/2010 : gestion des blocs txt archivés "ANT", ajout option "-ant"
// avec la variable d'environnement DEBUGYTTESTVERSIONNING a ON c'est idem option "-ant"
//-------------------------------------------------------------------------------
// YTR 23/02/2011 : utilisation de pmap pour gestion EJP
//-------------------------------------------------------------------------------
// MB 28/03/2011 : fonction makeblocs pour la création de blocs uniformes : 
//					critères date complète + taille et nbre de jrp
// YTR 25/07/2011 : intégration du dév de MB dans $ELA_SRC_GEN + ajout test sur env DEBUGYTTESTNEWBLOCS=="ON"
// MB  08/08/2011 :	mise en place d'un nouvel algo (spécs YT) pour createBlocsEJPELNET_NEW 
//					appel syst à splitpath remplacé par une fct écrite en balise 
// MB  25/09/2012 : modif fonction createBlocsELNET pour Hulk :
//                                      livrer les jrps non fournies par Dz
//-------------------------------------------------------------------------------

#include "dico.var"
#include "lib/utils.lib"
#include "lib/docam.lib"
#include "lib/dates.lib"
#include "lib/pmap.lib"

//#include "lib/elcomm.lib"
//#include "elcomm.lib"

#define PROGNAME			"makeblocs"
#define CODEVERSION			"2.5"			// création incrémentale des blocs EJP 
#define CODEDATE			"25/09/2012"

#define DEFAULT_ERROR_FILENAME		PROGNAME+".err"

//#define CATALOG				"/usr/local/ela/trt/sgml/catalog"
//#define SEP				"/"

#define DEFAULT_TRACE_FILENAME		PROGNAME+"_traces.txt"
#define LINESEPARATOR			"\n--------------------------------------------------------------------------------\n"


// code erreurs
#define OK				0
#define BAD_COMMAND_LINE		1
#define CANNOT_CREATE_TRACE_FILE	2
#define CANNOT_LOAD_SGML_DOCUMENT	3
#define CANNOT_CREATE_OUTPUT_FILE	4
#define CANNOT_CREATE_DIROUT		5
#define CANNOT_CREATE_ERROR_FILE	6
#define ENVIRONMENT_NOT_LOADED		7
#define PARSE_OR_CODE_ERROR		8
#define CANNOT_CREATE_BLOC		9
#define INTERNAL_ERROR			99

//--- variables globales -------------------------------------------


// MB ajout des seuils pour les conditions de creation de blocs ----------
#define	LIMIT_NB_JRP	2000
#define LIMIT_TAILLE_BLOC	30000000
//------------------------------------------------------------------------

// MB : 05/08/2011 : ajout variables pour fct splitpath balise
var regExpTimeStamp = RegExp("[0-9]{8}_[0-9]{6}_[0-9]{4}");
/*
// deplaces dans utils.lib
var regExpAlpha1 	= RegExp("^(cetatext|juritext)[0-9]+");
var regExpNumParts 	= RegExp("^([0-9]{3})([0-9]{3})([0-9]{3})");
*/
//		pour extraire une arborescence de profondeur 3 pour cas sans timestamp
// deplacee dans utils.lib
//var regExp3NumParts = RegExp("^([0-9]{3})([0-9]{3})([0-9]{3})");
//		pour extraire une arborescence de profondeur 3 pour cas avec timestamp
// var regExpTime4StampParts = RegExp("^([^0-9]*)([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{4})");
// MB : 08/08/2011 : ajout regExp pour extraire liste blocs existants
var regExpBlocInterval = RegExp("^elnet_jrpbloc[^_]*_([0-9]{8}\\-[0-9]{8}).optj.sgm$");
var setAllExistingBlocs = Set();		// ens. des blocs actuels
var mapAllExistingBlocsDates = Map();	        // sauvegarder les dates des blocs existants pour les comparer au maplastupdate des jrp (éviter de le calculer à chaque fois)
var setAllNewJrpBlocs = Set();			// ens. des blocs qui devront exister
var listUpdateBlocs = List();			// liste des blocs à reconstruire 
var nbAppelCreationBlocs = 0;
var nbRebuild = 0, nbNew = 0;			// nombre des nouveaux blocs à créer et des anciens à reconstruire (pour affichage ds la fct principale) 
//		générer un fichier csv 
var logFile = "makeblocs.log";
/*
pour mettre en prod, modifier les lignes :
	2096 : sBlocfileRoot = "/home/mbaziz/documents/optimise_makeblocs/data/res/jrp/elnet_jrpblocEJP_";  ---> à commenter
	2208 : getSetAllExistingBlocs("/mac.public/mbaziz/documents/optimise_makeblocs/data/res/jrp");      ---> commenter et décommenter la ligne qui la précède
	2549: 	//sBlocfileRoot = "/home/mbaziz/documents/optimise_makeblocs/data/res/jrp/elnet_jrpbloc_"; 	 
*/
//


var ferror ;

var G_exitVal = OK ;
var G_sErrors = "";			// erreurs rencontrees pendant le traitement
var G_sBlocrule = "N/A";		//  regle de constitution des blocs
var G_sSourceType = "N/A";		// type de source txt/jrp
var G_sErrorFileName = "N/A";		// nom du fichier erreur
var G_zdp ;				// code du dp : Z1, Z2, Y2...

var G_bEJPmode = false ;		// mode "EJP" = spécifique elnet : on traite les jrp issues de l'EJP (Légifrance, etc.) sous forme de blocs distincts
var G_bANTmode = false ;		// mode "ANT" = spécifique elnet : on traite les txt issues du versionning (dans $ELA_DATACOMM/txt/versionning)
//  sous forme de blocs distincts
var G_sEJPlivRoot = "" ;		// path contenant les fichiers optj permettant de constituer les blocs

var G_maptxtboi = Map();	// map des txt identifiés comme BOI (dp01 uniquement)
var G_mapet = Map();		// map des appels txt/jrp dans les broches (dp33 uniquement)
var G_maptxtjrp = Map();	// map des txt ou jrp du fonds DPM (tout8) (elnet uniquement)

// pour gestion des txt antereiurs (cas du versionning)
var G_mapMDFversionning = Map();

// DEBUGYT :  à définir tant que pas dans dico.var
//type jrpinfo(annee,mois,jour,type,ancientype,pa,pb,date,requete,arret,pourvoi,juridic1,juridic2);

// --- YTR 15/06/2009 : on associe des poids au types principaux afin d'ordonner les txt/jrp dans les blocs
// ---                  ce qui a un impact sur l'ordre des txt/jrp dans les résultats de rech fulltext (blocs ELNET)
var G_mapNSWeight = Map( "D1", "00", "D1A", "00", "D1B", "00", "D1C", "00", "D1D", "00", "D1E", "00", "D1F", "00", "D1G", "00", "D2", "00",
"D3B", "01", "D5", "02", "D3A", "03",
"LOI", "01", "ORD", "02", "DEC", "03", "ARR", "04", "C", "05" ); 

var G_sYearBegin = "" ;		// date à partir de laquelle on crée les blocs
var G_sYearEnd = "" ;		// date jusqu'à laquelle on crée les blocs
var G_bINSTRYT ;	// booleen indiquant si on est dans un mode instrumenté (mesure de temps) positionné par var envir "INSTRYT" == "ON"

// 17/09/2012 MB : ajout set des jrp "exotiques"
// livraison pour Hulk
var G_setIdjrpToBuild = Set();
var exoticjrpFile = filePath(env("ELA_LIV"),"miscdata","HulkJrpToBuild.set");
var exoticjrpFileMat = filePath(env("ELA_LIV"),"miscdata","HulkJrpToBuildMat.set");

//Le 12/02/2014
//Mantis 4380
// Le set HulkTxtToBuild.set contient les TXT a traiter
// Se Set est utulise par le programme make_bloc
var G_txtToBuildFile = filePath(env("ELA_LIV"),"miscdata","HulkTxtToBuild.set");
var G_jrpToBuildFile = filePath(env("ELA_LIV"),"miscdata","HulkJrpToBuild.set");
var G_setIdtxtToBuild = Set();
var G_refDateTxtDepuis = "";
var G_bRefDateTxtDepuis = "";
var G_refDateJrpDepuis = "";
var G_bRefDateJrpDepuis = "";
// YE 03/06/2014 Mantis 7336
var G_EJPV2NonLivreDl = filePath(env("ELA_LIV"),"miscdata","HulkEJPV2NonLivreDalloz.set");
var G_setEJPV2NonLivreDl = Set();

var G_traceDirOutName = "";
var G_tracefile = "";  

// 18/09/2014 sfouzi
var G_dirAddTxtFiles = "";
var G_dirAddJrpFiles = "";

// fin 4380
/*--------------------------------------------------------------------
function usage : affiche les options de ligne de commande disponibles
--------------------------------------------------------------------*/
function usage() {
	cout << format("\n%1 V%2 - %3\n",PROGNAME,CODEVERSION, CODEDATE) ;
	cout << format( "\nSyntaxe : balise -src %1.bal -args txt|jrp [options]\n"+
	"          balise -load %1.bin -args txt|jrp [options]",PROGNAME) ;

	cout << format("\n\nOptions :\n\n"+
	"-blocrule year|month	: constitue les blocs en se basant sur l'annee/le mois (option par defaut=year sauf pour ELNET=mois)\n\n"+
	"-ejp			: passe en mode 'EJP' : on constitue des blocs speciques 'EJP' (jrp en provenance de Legifrance&co\n\n"+
	"-ant			: passe en mode 'ANT' : on constitue des blocs speciques 'ANT' (txt en provenance du versionning)\n\n"+
	"-from AAAA		: on créera les blocs [EJP] à partir de l'année AAAA\n\n"+
	"-to AAAA		: on créera les blocs [EJP] jusqu'à l'année AAAA\n\n"+
	"txtblochulk             : on creera les bloc TXT pour hulk MAJ apres la derniere Hulkliv\n\n"+
	"txtblochulk txtdepuis  dd/mm/aaaa : on creera les bloc TXT pour hulk apartir de la date indiquer\n\n"	
	);
}

/*Cette fonction permet de comparer deux date 
i-e:
Valeur de retour :
- supp : datejrp > dateref   ie a traiter
- less : datejrp < dateref	 ie a ne pas traiter 	
- equal : datejrp = dateref  ie a traiter
*/
function compareDate(dateref,datejrp){

	var dateref_day = dec(dateref.explode("/")[0]);
	var dateref_month = dec(dateref.explode("/")[1]);
	var dateref_year = dec(dateref.explode("/")[2]);
	var time1 = dateref.explode(" ")[1];	
	var time1_hour = time1.explode(":")[0];	
	var time1_minute = time1.explode(":")[1];			
	
	var datejrp_day = dec(datejrp.explode("/")[0]);
	var datejrp_month = dec(datejrp.explode("/")[1]);
	var datejrp_year = dec(datejrp.explode("/")[2]);
	var time2 = datejrp.explode(" ")[1];
	var time2_hour = time2.explode(":")[0];	
	var time2_minute = time2.explode(":")[1];

	if  datejrp_year > dateref_year return "supp" ;
	else if datejrp_year < dateref_year return "less" ;
	else {
		if datejrp_month > dateref_month return "supp" ;
		else if datejrp_month < dateref_month return "less" ;
		else {
			if datejrp_day > dateref_day return "supp" ;
			else if datejrp_day < dateref_day return "less" ;
			else{ //comparaison horaires
				if time2_hour > time1_hour return "supp" ;
				else if time2_hour < time1_hour return "less" ;
				else return "equal";				
			} 
		}
	}	
	
}


/*--------------------------------------------------------------------
function handleCommandLine : gere la ligne de commande
--------------------------------------------------------------------*/
function handleCommandLine() {

	var sNextArg = "" ;
	
	//YE 12/02/2014 Mantis 2596 nouveau type txtblochulk => pour construire les bloc txt dans le cas de hulk
	// 18/09/2014 sfouzi ajout nouveau type addtxtfiles => pour construire les blocs txt a partir de fichiers txt optj dans un dossier passe en parametre
	// 24/05/2017 alazreg ajout nouveau type addjrpfiles => pour construire les blocs jrp a partir de fichiers jrp optj dans un dossier passe en parametre
	var setValidSourcetypes = Set("txt","jrp","txtblochulk","jrpblochulk","addtxtfiles","addjrpfiles");
	var setValidBlocrules = Set("year","month");
	var bFirstArg = true ;

	// --- YTR 09/04/2009 : les blocs ELNET sont désormais créés par "mois" et non plus par "année"
	// ---                  pour les net permanent, on reste sur les blocs par année
	if G_zdp == "ELNET"	{
		if env("DEBUGYTTESTNEWBLOCS") == "ON"	G_sBlocrule = "day" ;
		else					G_sBlocrule = "month" ;
		
	}
	else			G_sBlocrule = "year" ;


	// --- YTR 31/07/2008 : en raison d'un pb d'impression des textes multi-UA, dont on ne sait pas s'il est lié ou non
	// ---                  à la constitution des blocs par mois, on désactive ce mécanisme temporairement et on laisse
	// ---                  le découpage par année par défaut pour tout le monde.
	// --- YTr 23/03/2009 : je réactive pour tests, car ça devient urgent!!!


	if Arguments.length() == 0 {
		usage();
		abort(BAD_COMMAND_LINE) ;
	}

	for arg in Arguments {

		if bFirstArg {
			if setValidSourcetypes.knows(arg)	G_sSourceType = arg ;		// jrp|txt|exoticjrp|exoticjrpmat
			else {
				cout << format("\n*** premier parametre '%1' incorrect!\n",arg) ;
				usage();
				abort(BAD_COMMAND_LINE) ;
			}
			bFirstArg = false ;
			continue;
		}

		// --- soit on attend un argument faisant suite a un precedent argument
		if sNextArg != "" {

			switch( sNextArg ) {
			case "blocrule" :
				if setValidBlocrules.knows(arg)	G_sBlocrule = arg ;
				else {
					cout << format("\n*** option %1 : parametre '%2' incorrect!\n",sNextArg,arg) ;
					usage();
					abort(BAD_COMMAND_LINE) ;
				}
				break ;

			case "yearbegin" :
				G_sYearBegin = arg ;
				break;

			case "yearend":
				G_sYearEnd = arg ;
				break;

			case "txtdepuis":				
				G_refDateTxtDepuis = arg;
				// Ajouter 00:00:00 a la date de reference pour demarer a mi-nuit
				G_refDateTxtDepuis = G_refDateTxtDepuis + " 00:00:00";
				G_bRefDateTxtDepuis = true;
				break;
			case "jrpdepuis":				
				G_refDateJrpDepuis = arg;
				// Ajouter 00:00:00 a la date de reference pour demarer a mi-nuit
				G_refDateJrpDepuis = G_refDateJrpDepuis + " 00:00:00";
				G_bRefDateJrpDepuis = true;
				break;
				// 18/09/2014 sfouzi
				// 24/05/2017 alazreg ajout addjrpfiles
			case "dirin":
				// G_dirAddTxtFiles = arg;
				if Arguments[0] == "addtxtfiles" G_dirAddTxtFiles = arg;
				if Arguments[0] == "addjrpfiles" G_dirAddJrpFiles = arg;
				break;
				default :
				cout << format("\n*** bug nextarg non traite dans handleCommandLine : '%1'\n",sNextArg) ;
				abort(INTERNAL_ERROR) ;
			}

			sNextArg = "" ;
			continue ;
		}

		// --- soit on traite un argument "standard"

		switch(arg) {
			
		case "-help" :
		case "help" :
		case "/help" :
		case "-h" :
		case "/h" : 
			usage();
			abort(OK) ;
			break;

		case "-ejp" :
			G_bEJPmode = true ;
			break;

		case "-ant" :
			G_bANTmode = true ;
			break;

		case "-from":
		case "--from":
			sNextArg = "yearbegin";
			break;

		case "-to":
		case "--to":
			sNextArg = "yearend";
			break;

		case "-blocrule" :
		case "-blocrules" :
		case "--blocrule" :
		case "--blocrules" :
			sNextArg = "blocrule" ;
			break;	
			// Mantis 4380
		case "-txtdepuis":
		case "txtdepuis":
			sNextArg = "txtdepuis";
			
			break;
		case "-jrpdepuis":
		case "jrpdepuis":
			sNextArg = "jrpdepuis";
			
			break;
			// 18/09/2014 sfouzi
		case "-dirin":
		case "dirin":
			sNextArg = "dirin";
			break;
			default : 
			cout << "\n*** argument invalide : "+arg+"\n" ;
			usage();
			abort(BAD_COMMAND_LINE) ;
		}
	}

	if sNextArg != "" {
		cout << format("\n*** parametre requis apres option %1\n",sNextArg) ;
		usage();
		abort(BAD_COMMAND_LINE) ;
	}
}


/*--------------------------------------------------------------------
// Cette fonction retourne une chaîne constituée à partir de la décomposition du nom de fichier
// passé en paramètre en une partie textuelle initiale puis des séries de 3 digits,
// chaque morceau étant séparé par des "/" afin de constituer un path
//
// Ceci vise à régler le problème d'un nombre trop important de fichiers dans
// un meme dossier en générant un ensemble de dossiers à partir du nom d'un fichier.
//
// Les règles sont de découper par groupe de 3 digits, en excluant la partie alphabétique initiale,
// car les fichiers que nous souhaitons traiter ont tous une partie numérique importante.
// un fichier comme "tototititata.sgm" ne donnera pas lieu à découpage.
// Ceci pourrait etre facilement adapté, en ne faisant pas d'exception sur
//
// ex: si j'ai les fichiers suivants :
// t123456.sgm
// arr20028.sgm
// CETA00002829.sgm
//
// la fonction splitPath va retourner (avec option true) :
// t/123/t123456.sgm
// arr/200/arr20028.sgm
// CETA/000/028/CETA00002829.sgm
//
// avec l'option false, on aurait :
// t12/345/t123456.sgm
// arr/200/arr20028/sgm
// CET/A00/002/CETA00002829.sgm
//
// l'idée est de ne pas créer de dossier avec plus de 1000 fichiers, tout en
// conservant une lecture a la fois intuitive et non ambigue pour les humains.
//
// Paramètres :
// #1 filename : le nom du fichier à "spliter"
// #2 bIgnoreLeadingLetters : un booleen indiquant s'il faut conserver la partie textuelle sans découpage (true) ou non (false)
--------------------------------------------------------------------*/
/*function getSplitPath(fileName,bIgnoreLeadingLetters) {

// YTR 17/02/2011 ------------------- ATTENTION ------
//
// la fonction splitpath n'est plus à jour des dernières modifications demandées à Léandre (pour la version C / dpmprod)
// en raison du nommage des fichiers Jurica avec un timestamp
//
// je court-circuite cette fonction et procède à un appel système pour invoquer l'exécutable développé par Léandre
// à voir si cela est plus long que de recoder l'algo dans balise
// ==> pas le temps pour le moment de jouer à ça
//

return fileName ;



var fdn = fileDirName(fileName);
var fbn = fileBaseName(fileName);
var c, cup ;
var nPart = 0 ; 	// --- compteur de "parties" dans le path généré
var nCpt = 0 ; 		// --- compteur de caractère pour chaque partie
var nCptMax = 3 ;	// --- pas plus de 3 caractères par nom de partie (=3 digits = 1000 fichiers max)
var s = "";		// --- chaine finale contenant le chemin splité
var stmp = "";		// --- chaine temporaire qui peut etre ajoutée à la chaine finale... ou pas


	// --- on évite de débuter un path par "." si les fichiers sont dans le répertoire courant
	if fdn == "." fdn = "";

	for i = 0 to fbn.length()-1 {

		c = asc(fbn[i]);

		// --- si on rencontre un point on stoppe tout
		if c == "." {
			break;
		}

		// --- tant qu'on est sur la première partie "textuelle", on conserve
		// --- tout caractère alphabétique
		if nPart==0 && bIgnoreLeadingLetters {

			cup = c.transcript(UpperCase);
			if cup >= "A" && cup <= "Z" {
				s << c ;
			}
			else {
				// --- si on passe sur autre chose que du alphabétique,
				// --- on attaque la deuxième partie
				nPart++;

				stmp = c ;
				nCpt = 1 ;
			}
		}
		else {
			// --- si on est déjà sur une partie autre que la première,
			// --- on fait des paquets de "nCptMax"
			if ++nCpt <= nCptMax {
			
				stmp << c ;
			}
			else {
				// --- si on dépasse la limite, on additionne le chemin temporaire au chemin définitif
				if s!="" s << SEP ;
				s << stmp ;
				stmp = c ;
				nCpt = 1;
				nPart++;
			}
		}
	}

	// --- si on n'a pas segmenté le nom avec des sous-dossiers on retourne la chaine intiale inchangée
	if nPart == 0 	s = fileName;
	else		s = filePath(fdn,s,fbn);

	return s ;

}*/









/*--------------------------------------------------------------------
createBlocs()
--------------------------------------------------------------------*/
function createBlocs(doc,sBlocfileRoot,sSourcedir,eladico) {

	var r=root(doc);
	var sBlocname, sBlocfilename, sRootTag, sRootID, sSourcefilename, sIdref ;
	var nodeIDAN, nodeID2, nodeIDJM ;
	var fbloc, fsrc ;
	var nodeBlocJrp; // utilise dans le cas du dp15
	var nbSrcIncluded ; // nombre de sources intégrées par bloc
	var sIDJM, sPrevIDJM, nBlocmois, lsttokIDJM, sPrevBlocname, sInsertBlocMois ;

	var bInsererBlocMois = true ;
	var bUnBlocParAnnee = true ;

	// --- init pour gestion blocmois
	sPrevBlocname = nothing ;

	cout << "\nCreation des blocs en cours...\n";


	// --- pour simplifier le code ci-dessous, étant donné la spécificité des blocs txt du 33, 
	// --- on positionne 2 booléens :
	if eladico == "dp33" &&  G_sSourceType == "txt" {
		bInsererBlocMois = false ;
		bUnBlocParAnnee = false ;
	}

	switch(G_sBlocrule) {
	case "year" :
		
		// --- creation des blocs par annee :

		/* ------------------------------------------------------------
		// Modif du 06-12-2003 Ahmed
		// La boucle for dessous fonctionne dans les cas autres que dp15
		// Le cas du dp15 est traite dans le if qui se trouve apres
		------------------------------------------------------------ */

		if eladico != "dp15"{


			// YTR 26/09/2005 : DP33 txt : un bloc "principal" est créé à partir de l'index txt
			//                  (sans distinction d'année)
			//                  les autres blocs seront créés par régime (cf plus bas)
			//
			if !bUnBlocParAnnee {
				sBlocname = "horsregime123";
				sBlocfilename = format("%1%2.optj.sgm",sBlocfileRoot,sBlocname);
				cout << format("\nCreation du bloc %1",fileBaseName(sBlocfilename));
				fbloc = FileStream(sBlocfilename,"w");
				if fbloc==nothing { error format("Impossible de creer %1",sBlocfilename); break; }
				fbloc << format("<%1 ID=\"%2\">","TXTBLOC-OPTJ",format("%1TXTBLOC%2",G_zdp,sBlocname.transcript(UpperCase))) ;
			}


			for nodeID1 in searchElemNodes(r,"ID1") {

				nodeIDAN = enclosed(nodeID1,"IDAN");
				if nodeIDAN == nothing { error "ID1 sans fils IDAN" ; continue ; }

				// --- constitution du nouveau bloc (sauf pour txt dp33)
				if bUnBlocParAnnee {
					sBlocname = content(nodeIDAN).transcript(Map(32,"")).transcript(LowerCase);
					sBlocfilename = format("%1%2.optj.sgm",sBlocfileRoot,sBlocname);
					cout << format("\nCreation du bloc %1",fileBaseName(sBlocfilename));
					fbloc = FileStream(sBlocfilename,"w");
					if fbloc==nothing { error format("Impossible de creer %1",sBlocfilename); continue; }
				}

				// --- init pour gestion blocmois
				if sBlocname != sPrevBlocname {
					nBlocmois = 1 ;
					sPrevIDJM = nothing ;
					sPrevBlocname = sBlocname ;
					sInsertBlocMois = "" ;
				}

				// --- choix et ouverture de l'element racine :
				switch(G_sSourceType) {
				case "txt" : sRootTag = "TXTBLOC-OPTJ" ; sRootID = format("%1TXTBLOC%2",G_zdp,sBlocname.transcript(UpperCase)); break;
				case "jrp" : sRootTag = "DECISBLOC-OPTJ" ; sRootID = format("%1DECISBLOC%2",G_zdp,sBlocname.transcript(UpperCase)); break; 
				}

				if bUnBlocParAnnee {
					fbloc << format("<%1 ID=\"%2\">",sRootTag,sRootID) ;
				}

				nbSrcIncluded=0;

				// --- concatenation dans le bloc des txt/jrp pour l'annee courante
				for nodeID3 in searchElemNodes(nodeID1,"ID3") {

					
					// --- 27/06/2005 YTR : on récupère le mois pour générer des éléments BLOCMOIS dans l'optj et dans les TOC
					if bInsererBlocMois && sBlocname != "sansdate" {
						nodeID2 = ancestor(nodeID3,"ID2");
						if nodeID2 != nothing {
							nodeIDJM = enclosed(nodeID2,"IDJM");
							if nodeIDJM != nothing {
								//cout << format("\n--- %1 / %2",sBlocname,content(nodeIDJM));
								lsttokIDJM = content(nodeIDJM).explode(" ");
								if lsttokIDJM.length()==3 {
									sIDJM = lsttokIDJM[1]; // on récupère le mois
									if sIDJM != sPrevIDJM {

										// YTR 21/07/2005 : on ne ferme un bloc précédent que si il a été effectivement rempli
										//                  (s'il n'y a rien eu, la chaine sInsertBlocMois est toujours renseignée)
										//                  (correction bug blocmois vide car textes uniquement de type adidx dedans)
										if sPrevIDJM != nothing && sInsertBlocMois == "" fbloc << "</BLOCMOIS>";
										sPrevIDJM = sIDJM ;
										sInsertBlocMois = format("<BLOCMOIS ID=\"%1-%2\" T=\"%3\">",sRootID,nBlocmois++,sIDJM);
									}
								}
								else error format("pb contenu IDJM='%1'",content(nodeIDJM));
							}
							else error "nodeIDJM non trouvé dans ID2";
						}
						else error "ID3 sans ancetre ID2!!!";
					}


					if !hasAttr(nodeID3,"IDREF") { error "ID3 sans IDREF" ; continue ; }
					
					sIdref = attr["IDREF",nodeID3].transcript(LowerCase) ;


					if eladico != "elnet" {

						sSourcefilename = format("%1%2.optj.sgm",sSourcedir,sIdref);

					}
					else {
						sSourcefilename = "" ;
						for dp in G_listElnetDP {
							sSourcedir = format("/usr/local/ela/cd-rom/%1/data/sgml/%2/optj/",dp,G_sSourceType);
							sSourcefilename = format("%1%2.optj.sgm",sSourcedir,sIdref);
							if fileAccess(sSourcefilename) {
								//cout << format("\nYES, j'ai trouvé %1 dans le dp %2",sIdref,dp);
								break;
							}
						}
					}

					fsrc = FileStream(sSourcefilename,"r");
					if fsrc==nothing {
						// avant de gueuler, on vérifie que l'IDREF n'est pas un IDREF
						// de type "ADIDX", comme par exemple Z4A-xxxx :
						if sIdref[2]==asc("a") && sIdref[3]==asc("-") {
							//cout  << format("\n/// fichier %1 non trouvé mais ignoré car idref='%2' (adidx)",
							//			fileBaseName(sSourcefilename), sIdref);
						}
						else error format("impossible d'acceder a %1",sSourcefilename);
						continue;
					}
					else {

						/**************************
A NE PAS FAIRE AVANT MIGRATION TOTALE DU PARC EN 2.0.10 ou supérieure
(intégration de la gestion du cfgindex.xml permettant de gérer les
index spéciaux et donc les index et blocs "BOI" en 2.0.10)

					// --- YTR 24/12/2004
					// --- on exclue des blocs "normaux" les txt identifiés comme BOI
					if eladico == "dp01" {
						if G_maptxtboi.knows(sIdref.transcript(UpperCase)) {
							//cout << format("\ndp01 : on exclu le txt 'BOI' %1 du bloc",sIdref);
							continue ;
						}
					}
***********************/

						// YTR 21/07/2005 : on cree un bloc uniquement s'il y a des textes qu'il faut conserver dedans...
						//                  (correction bug blocmois vide car textes uniquement de type adidx dedans)
						if bInsererBlocMois && sInsertBlocMois != "" {
							fbloc << sInsertBlocMois ;
							sInsertBlocMois = "" ;
						}

						fbloc << readAll(fsrc);
						nbSrcIncluded++;
						//cout << format("%1 ",sIdref);
						// cout << "."; flush(cout);
						close(fsrc);
					}
				}

				// --- fermeture du dernier element BLOCMOIS et de l'élément racine
				// YTR 21/07/2005 : on ne ferme un bloc précédent que si il a été effectivement rempli
				//                  (s'il n'y a rien eu, la chaine sInsertBlocMois est toujours renseignée)
				//                  (correction bug blocmois vide car textes uniquement de type adidx dedans)
				if bInsererBlocMois && sPrevIDJM != nothing && sInsertBlocMois == "" fbloc << "</BLOCMOIS>";


				// --- on ferme le bloc à chaque "fin d'année", sauf si on fait pas un seul "gros" bloc :)
				if bUnBlocParAnnee {

					fbloc << format("</%1>\n",sRootTag) ;
					close(fbloc);

					// --- si le bloc est vide, on le detruit
					if nbSrcIncluded==0 {
						if fileAccess(sBlocfilename) fileRemove(sBlocfilename);
						cout  << format("\n/// bloc %1 vide ==> supression de %2", sBlocname,sBlocfilename);
					}
				}

			}

			// --- on ferme le bloc à la fin de tous les txt/jrp, dans le cas où il n'y a qu'un seul "gros" bloc
			if !bUnBlocParAnnee {
				fbloc << format("</%1>\n",sRootTag) ;
				close(fbloc);
			}

		} // fin if eladico != dp15

		/* -------------------------
		// Modif du 06-12-2003 Ahmed
		// Traitement du dp15
		------------------------- */
		if eladico == "dp15"{
			for year in searchElemNodes(r,"YEAR"){
				// --- constitution du nouveau bloc
				sBlocname = attr["DATE",year];
				sBlocfilename = format("%1%2.optj.sgm",sBlocfileRoot,sBlocname);
				cout << format("\nCreation du bloc %1",fileBaseName(sBlocfilename));
				fbloc = FileStream(sBlocfilename,"w");
				if fbloc==nothing { error format("Impossible de creer %1",sBlocfilename); continue; }

				nodeBlocJrp = Node(doc,"DECISBLOC-OPTJ",false);
				for decis in searchElemNodes(year,"DECIS-OPTJ"){
					insertSubTree(nodeBlocJrp,-1,decis);
					// cout << "."; flush(cout);
				}

				dumpSubTreeSGMLwithRC(nodeBlocJrp,fbloc);
				close(fbloc);
			}
		}

		break;

		default :
		cout << format("\n*** createBlocs ne sait pas gerer la regle '%1'",G_sBlocrule);
		abort(INTERNAL_ERROR) ;

	} // switch
}


/*--------------------------------------------------------------------
createBlocBOI() : creation bloc BOI (dp01 uniquement)
--------------------------------------------------------------------*/
function createBlocBOI(sBlocfileRoot,sSourcedir,eladico) {

	var sBlocname, sBlocfilename, sRootTag, sSourcefilename, sIdref ;

	var annee, serie, division, codeboi, jour, datelong, tiboi, tiserie, tidivision;
	var anneecrt, seriecrt, divisioncrt ;

	var fbloc, fsrc ;
	var nbSrcIncluded ; // nombre de sources intégrées par bloc
	
	// --- constitution du nouveau bloc
	sBlocname = "boi";
	sBlocfilename = format("%1%2.optj.sgm",sBlocfileRoot,sBlocname);
	cout << format("\nCreation du bloc %1",fileBaseName(sBlocfilename));
	fbloc = FileStream(sBlocfilename,"w");
	if fbloc==nothing { error format("Impossible de creer %1",sBlocfilename); return CANNOT_CREATE_BLOC; }

	sRootTag = "TXTBLOC-OPTJ" ;
	fbloc << format("<%1>",sRootTag) ;
	nbSrcIncluded=0;

	anneecrt = "";
	seriecrt = "";
	divisioncrt = "";

	// --- concatenation dans le bloc des txt classés par annee décroissante, serie croissante,
	// --- division croissante, et enfin pour chaque BOI par codeBOI décroissant
	for idtxtboi in eSort(G_maptxtboi, function(i) {
		var annee = format("%1$04d",9999 - G_maptxtboi[i].annee);
		var serie = format("%1$02d",dec(G_maptxtboi[i].serie));
		var division = G_maptxtboi[i].division;
		//var moisjour = format("%1$02d%2$02d",99-G_maptxtboi[i].mois, 99-G_maptxtboi[i].jour);
		var codeboi = G_maptxtboi[i].code ;

		// --- on essaie de récupérer la partie finale du code boi si correctement formatée
		// --- ex: BOI 6 E-9-23 ==> on récupère : 00090023
		var regexpcodeboi = RegExp(format("%1 %2 %3[\\- ]*([0-9]+)[\\- ]*([0-9]+)",
		G_maptxtboi[i].nature,G_maptxtboi[i].serie,division));
		var matchescodeboi = codeboi.rsearch(0,regexpcodeboi);
		if matchescodeboi != nothing {
			codeboi = format("%1$04d%2$04d", dec(matchescodeboi[0].sub[0].value),
			dec(matchescodeboi[0].sub[1].value));
		}
		else error format("%1 : code BOI incomplet ou mal formé (pas grave mais tri a verifier) : '%2'",i,codeboi);

		codeboi = codeboi.transcript(map_trs_inverse);
		return annee+serie+division+codeboi;
	}) {
		
		sSourcefilename = format("%1%2.optj.sgm",sSourcedir,idtxtboi.transcript(LowerCase));
		fsrc = FileStream(sSourcefilename,"r");
		if fsrc==nothing {
			error format("impossible d'acceder a %1",sSourcefilename);
			continue;
		}
		else {

			annee = dec(G_maptxtboi[idtxtboi].annee);
			serie = G_maptxtboi[idtxtboi].serie ;
			division = G_maptxtboi[idtxtboi].division ;
			codeboi = G_maptxtboi[idtxtboi].code ;
			jour = G_maptxtboi[idtxtboi].jour ;
			datelong = format("%1 %2 %3",	(jour==1?"1er":dec(jour)),
			moisIntToString(G_maptxtboi[idtxtboi].mois),
			G_maptxtboi[idtxtboi].annee);
			tiboi = G_maptxtboi[idtxtboi].ti ;

			if G_mapSerieDiv.knows(serie) {

				tiserie = format("%1 %2 %3", serie, G_mapSerieDiv[serie].abrev, G_mapSerieDiv[serie].ti);

				if G_mapSerieDiv[serie].mapDiv.knows(division) {

					tidivision = format("%1 %2", division, G_mapSerieDiv[serie].mapDiv[division]);
				}
				else {
					error format("Serie %1 : Titre division %2 introuvable dans docam.lib",serie,division);
					tidivision = division ;
				}
			}
			else {
				error format("Titre serie %1 introuvable dans docam.lib",serie);
				tiserie = serie ;
			}

			// --- si nécessaire, creation niveau annee
			if anneecrt != annee {
				anneecrt = annee ;
				//cout << format("\n\n\n\n+ %1",annee);
			}

			// --- si nécessaire, creation niveau série
			if seriecrt != serie {
				seriecrt = serie ;
				//cout << format("\n\n+++ %1",tiserie);
			}

			// --- si nécessaire, creation niveau annee
			if divisioncrt != division {
				divisioncrt = division ;
				//cout << format("\n\n+++++ %1\n",tidivision);
			}


			//cout << format("\n      %1 du %2. %3  [%4]", codeboi, datelong, tiboi, idtxtboi);



			fbloc << readAll(fsrc);
			nbSrcIncluded++;
			//cout << format("%1 ",idtxtboi);
			//cout << "."; flush(cout);
			close(fsrc);
		}
	}

	// --- fermeture de l'element racine :
	fbloc << format("</%1>\n",sRootTag) ;

	close(fbloc);

}

/*--------------------------------------------------------------------
createBlocsTxtRegimes() : creation bloc régimes (txt dp33 uniquement)
--------------------------------------------------------------------*/
function createBlocsTxtRegimes(sBlocfileRoot,sSourcedir,eladico) {

	var sBlocname, sBlocfilename, sRootTag, sSourcefilename ;
	var fbloc, fsrc ;
	var nbSrcIncluded ; // nombre de sources intégrées par bloc
	var regexpIdJrp = RegExp("^A[0-9]+$");
	var mapRegimes = Map();

	//cout << format("\nDEBUGYT : createBlocsTxtRegimes - phase 1 : initialisations txt références / doublons / ... [G_mapet='%1']",G_mapet);
	for id in eSort(G_mapet, function(id) {
		//var idet = G_mapet[id].idet ;
		return format("%1",id) ;
	}) {

		//cout << format("\nDEBUGYT : id = '%1'",id);

		if id.search(regexpIdJrp) == 0 continue ;

		var maptxtet = G_mapet[id];
		var nbref =  maptxtet.length() ;

		var regime = "N/A" ;
		var bDoublon = false ;
		var sTxtRefForRegime = "N/A" ;

		// --- on vérifie si le texte courant est de référence pour le régime
		for r in G_mapDP33txtref if G_mapDP33txtref[r].knows(id) sTxtRefForRegime = r ;


		for ref in maptxtet {

			if regime == "N/A"	regime = ref.idet ;
			else {
				// --- si le meme id de texte se trouve dans 2 regimes differents
				// --- et qu'il ne s'agit pas d'un texte "principal" d'un des deux régimes,
				// --- on génère un warning, car il s'agit d'un doublon

				if regime != ref.idet && !G_mapDP33txtref[ref.idet].knows(id) && !G_mapDP33txtref[regime].knows(id) {

					cout << format("\n*** WARNING : %1 cité dans régime %2 *** DOUBLON! *** ==> vérifier comportement pour ce texte",id,ref.idet);
					bDoublon = true ;
				}
			}

			if !bDoublon {
				//cout << format("\n%1 cité dans régime %2 [%3]",id,ref.idet,ref.typdoc);
			}
			regime = ref.idet ;
			if regime == "" regime = "TXTAJT" ;

			// --- si le texte est un texte de référence pour un régime précis, il ne doit pas figurer
			// --- dans un autre bloc que celui de son régime, meme s'il est cité dans d' autres regimes.
			// --- exception pour le cas des txt cités uniquement dans le TXTAJT, cf plus bas.

			if sTxtRefForRegime != "N/A" && sTxtRefForRegime != regime && regime != "TXTAJT" {

				//cout << format("\nDEBUGYT : on ignore l'id %1 cité dans régime %2, car c'est un txt de référence pour le régime %3",
				//			id, regime, sTxtRefForRegime);
				continue ;
			}

			// --- cas particulier : si le texte n'est cité que dans le TXTAJT alors qu'il s'agit
			// --- d'un texte de référence pour le régime (si si ça arrive!!)
			// --- dans ce cas on force l'insertion dans le regime de référence :
			var regimeinsert = regime ;
			if regime == "TXTAJT" && sTxtRefForRegime != "N/A" regimeinsert = sTxtRefForRegime ;

			if !mapRegimes.knows(regimeinsert) mapRegimes[regimeinsert] = Set(id);
			else mapRegimes[regimeinsert] << id ;
			
			//cout << format("\nDEBUGYT : insertion %1 dans bloc regime %2",id,regimeinsert);
		}		
	}

	//cout << format("\nDEBUGYT : createBlocsTxtRegimes - phase 2 : création des blocs [mapRegimes = '%1']",mapRegimes);
	for regime in eSort(mapRegimes) {
		cout << format("DEBUG 23/10/2014 SF/MB : regime = %1\n",regime);
		if regime == "TXTAJT"	sBlocname = "autres";
		else			sBlocname = regime ;

		// --- constitution d'un nouveau bloc régime / année
		sBlocfilename = format("%1%2.optj.sgm",sBlocfileRoot,sBlocname);
		cout << format("\n\nCreation du bloc %1 ",fileBaseName(sBlocfilename));

		fbloc = FileStream(sBlocfilename,"w");
		if fbloc==nothing { error format("Impossible de creer %1",sBlocfilename); return CANNOT_CREATE_BLOC; }
		
		sRootTag = "TXTBLOC-OPTJ" ;
		// Modif MJ 21/10/2005 ajout ID
		fbloc << format("<%1 ID=\"%2TXTBLOC%3\">",sRootTag,G_zdp,sBlocname.transcript(UpperCase)) ;
		nbSrcIncluded=0;

		for id in eSort(mapRegimes[regime], function(id) {

			var txtfile = format("%1%2txt%2optj%2%3.optj.sgm",env("ELA_DATA"),SEP,id.transcript(LowerCase));
			var dtdfile = format("%1%2txt-optj.dtd",env("ELA_DTD"),SEP);
			var jma = "" ;
			var crittri = "" ;

			if fileAccess(txtfile) && fileAccess(dtdfile) {
				//cout << format("\nDEBUGYT : parsing %1...",txtfile); flush(cout);
				var pr = parseDocument(List(env("ELA_DEC"),dtdfile,txtfile),Map("cat",List(env("CATALOG"))));
				if pr.status == 0 {
					//cout << "Ok"; flush(cout);
					var r = root(pr.document);
					var firstJMAnode = enclosed(r,"JMA");
					if firstJMAnode != nothing jma = getAllCDATASDATA(firstJMAnode).replace(0,"&nbsp;"," ");
					if jma != "" {
						// on récupère la date au format JJ/MM/AAAA et on la "retourne" pour avoir AAAA/MM/JJ
						jma = formaterDate(jma);
						var lsttokjjmmaa = jma.explode("/");
						if lsttokjjmmaa.length() == 3 {
							var jj = dec(lsttokjjmmaa[0]);
							var mm = dec(lsttokjjmmaa[1]);
							var aa = dec(lsttokjjmmaa[2]);
							crittri = format("%1$04d%2$02d%3$02d", 9999-aa, 99-mm, 99-jj);
						}
					}
				}
				else {
					var msg = format("\n***ERREUR GRAVE : échec parsing %1",txtfile); flush(cout);
					cout << msg ; G_sErrors << msg ;
					G_exitVal=CANNOT_LOAD_SGML_DOCUMENT;
				}
			}

			if crittri == "" crittri = format("%1",id) ;
			//cout << format("\nDEBUGYT : crittri = %1 pour id %2",crittri,id);
			return crittri ;

		}) {

			sSourcefilename = format("%1%2.optj.sgm",sSourcedir,id.transcript(LowerCase));
			fsrc = FileStream(sSourcefilename,"r");
			if fsrc==nothing {
				error format("ERREUR GRAVE : impossible d'acceder a %1 - Ce texte sera absent du bloc %2",
				sSourcefilename,sBlocname);
				continue;
			}
			else {
				fbloc << readAll(fsrc);
				nbSrcIncluded++;
				//cout << format("%1 ",id);
				// cout << "."; flush(cout);
				close(fsrc);
			}
		}

		fbloc << format("</%1>\n",sRootTag) ;
		close(fbloc);

	}
	//cout << format("\nDEBUGYT : createBlocsTxtRegimes - fin");

	return G_exitVal ;
}

/*--------------------------------------------------------------------
--------------------------------------------------------------------*/
function mergeIdxDoc(doc1,doc2) {

	var r1, r2 ;

	if !isaDocument(doc1) {
		doc1 = newCoreDocument();
		r1 = Node(doc1,"IDX-OPTJ");
	}
	else r1 = root(doc1);

	r2 = root(doc2);

	var listNodesID1DOC1 = searchElemNodes(r1,"ID1");

	for nodeID1DOC2 in searchElemNodes(r2,"ID1") {
		var nodeIDANDOC2 = child(nodeID1DOC2, "IDAN");
		if nodeIDANDOC2 != nothing {

			var contentNodeIDANDOC2 = content(nodeIDANDOC2);
			var nodeSameYearID1DOC1 = nothing ;

			for nodeID1DOC1 in listNodesID1DOC1 {
				var nodeIDANDOC1 = child(nodeID1DOC1,"IDAN");
				if nodeIDANDOC1 != nothing {
					if contentNodeIDANDOC2 == content(nodeIDANDOC1) {
						nodeSameYearID1DOC1 = nodeID1DOC1 ;
						break;
					}
				}
			}
			// --- si pas d'ID1 existant pour cette année, on prend intégralement l'ID1 du DOC2 pour l'insérer dans DOC1
			if nodeSameYearID1DOC1 == nothing {
				//cout << format("\n%1 n'existe pas dans DOC1, on duplique tout l'ID1 de DOC2 dans DOC1", contentNodeIDANDOC2 );
				insertSubTree(r1,-1,nodeID1DOC2);
			}
			else {
				//cout << format("\n%1 existe déjà dans DOC1, on ne garde que les ID2(IDJM) nouveaux", contentNodeIDANDOC2 );	

				var listNodesID2DOC1 = searchElemNodes(nodeSameYearID1DOC1,"ID2");

				for nodeID2DOC2 in searchElemNodes(nodeID1DOC2,"ID2") {

					var nodeIDJMDOC2 = child(nodeID2DOC2,"IDJM");
					if nodeIDJMDOC2 != nothing {

						var contentNodeIDJMDOC2 = content(nodeIDJMDOC2);
						var nodeSameDateID2DOC1 = nothing ;

						for nodeID2DOC1 in listNodesID2DOC1 {
							var nodeIDJMDOC1 = child(nodeID2DOC1,"IDJM");
							if nodeIDJMDOC1 != nothing {
								if contentNodeIDJMDOC2 == content(nodeIDJMDOC1) {
									nodeSameDateID2DOC1 = nodeID2DOC1 ;
									break;
								}
							}
						}
						// --- si pas d'ID2 existant pour cette date, on prend intégralement l'ID2 du DOC2 pour l'insérer dans DOC1
						if nodeSameDateID2DOC1 == nothing {
							//cout << format("\n%1 n'existe pas dans l'année %2 de DOC1, on duplique tout "+
							//			"l'ID2 de DOC2 dans DOC1",
							//			contentNodeIDJMDOC2, contentNodeIDANDOC2 );
							insertSubTree(nodeSameYearID1DOC1,-1,nodeID2DOC2);
						}
						else {
							//cout << format("\n%1 existe déjà dans l'année %2 de DOC1, on ne garde que les ID3 nouveaux",
							//			contentNodeIDJMDOC2, contentNodeIDANDOC2 );	

							var listNodesID3DOC1 = searchElemNodes(nodeSameDateID2DOC1,"ID3");
							for nodeID3DOC2 in searchElemNodes(nodeID2DOC2, "ID3") {
								var nodeSameJrpID3DOC1 = nothing ;
								if hasAttr(nodeID3DOC2,"IDREF") {
									for nodeID3DOC1 in listNodesID3DOC1 {
										if hasAttr(nodeID3DOC1,"IDREF") &&
										attr["IDREF",nodeID3DOC1] == attr["IDREF",nodeID3DOC2] {
											nodeSameJrpID3DOC1 = nodeID3DOC1 ;
											break;
										}
									}
								}
								// --- si pas d'ID3 avec le meme IDREF, on duplique l'ID3 de DOC2 dans DOC1
								if nodeSameJrpID3DOC1 == nothing {
									//cout << format("\nl'IDREF %1 n'existe pas dans DOC1, on duplique l'ID3",
									//	attr["IDREF",nodeID3DOC2]); 
									insertSubTree(nodeSameDateID2DOC1,-1,nodeID3DOC2);
								}
								else {
									//cout << format("\nl'IDREF %1 existe déjà dans DOC1 : on ne fait rien", 
									//	attr["IDREF",nodeID3DOC2]);
								}
							}
						}
					}
				}			
			}
		}
	}

	return doc1 ;
}


/*
* 17/09/2012 MB : ajout fonction pour livraison
* des jrp dans Hulk
* function setJrptoBuildforHulk(fichier) : charge le fichier des jrp absentes de DZ 
* à livrer dans Hulk sous forme de blocs
*/
function chargerSetJrpToBuildForHulk(exoticjrpFile){
	// 23/07/2013 AL/MB : ajout option pour ne livrer que les jrp des docs traites : "exoticjrpmat"
	/*var setJrp = loadObjectFromFile(exoticjrpFile);
	return  setJrp;
*/
	var setJrp = loadObjectFromFile(exoticjrpFile);
	cout << format("debug AL/MB 23/07/2013 : set des jrp a livrer chargé : %1 \n",exoticjrpFile);
	if setJrp == nothing setJrp = Set();
	return  setJrp; 
}


// YE 19/02/2014 Mantis 4380
// Cette fonction permet de verifier si la jrp est a traiter ou pas
// function jrpToBuild(attribute,codeMatiere){	

// var dirjrp = "/usr/local/ela/cd-rom/elnet/data/sgml/jrp/optj/"; 		
// var attrLowerCase = attribute.transcript(LowerCase);
// var jrpfile = dirjrp + attrLowerCase + ".optj.sgm";
// var jrpfiledate = "";	
// var G_ela_liv = env("ELA_LIV");
// var dateLancementDir = format("%1/dateLancement/",G_ela_liv);
// var referenceDatefile = dateLancementDir+"hulkliv.txt";
// var referencefiledate = "";
// var matiere = "";
// if G_maptxtjrp.knows(attrLowerCase){

// if fileSize(jrpfile) > 0 {			
// referencefiledate = loadObjectFromFile(referenceDatefile);  //timeFormat(fileDate(referenceDatefile), "%d/%m/%Y %H:%M:%S");			
// jrpfiledate = timeFormat(fileDate(jrpfile), "%d/%m/%Y %H:%M:%S");
// if G_bRefDateJrpDepuis == true {				
// if compareDate(G_refDateJrpDepuis,jrpfiledate) == "supp" || compareDate(G_refDateJrpDepuis,jrpfiledate) == "equal" {
// return true;
// cout << format("on traite la jrp '%1'\n",jrpfile);
// }else return false;					
// }else{								
// if codeMatiere == "ELNET" referenceDatefile = dateLancementDir +"hulkliv.txt";
// else {
// matiere = getCodeProd(codeMatiere);
// referenceDatefile = format("%1%2.txt",dateLancementDir,matiere);
// }
// if fileSize(referenceDatefile) > 0 referencefiledate =  readAll(FileStream(referenceDatefile, "r")).explode("\n")[0];
// else{
// referencefiledate = timeFormat(timeCurrent(), "%d/%m/%Y %H:%M:%S ");
// cout << format("ERROR : Attention le fichier %1 introuvable\n",referenceDatefile);
// }

// if compareDate(referencefiledate,jrpfiledate) == "supp" || compareDate(referencefiledate,jrpfiledate) == "equal" {
// return true;					
// }else return false;			
// }										
// }
// else {
// cout << format("Le fichier %1 n'existe pas\n",jrpfile);
// return false;
// }	
// }else return false;	
// }






/*--------------------------------------------------------------------
createBlocsELNET() : creation bloc ELNET d'après map tout8
--------------------------------------------------------------------*/
function createBlocsELNET(sBlocfileRoot,sSourcedir) {


	cout << format("\n\n=====================> dans focntion : createBlocsELNET(%1, %2)\n",sBlocfileRoot,sSourcedir);

	var sBlocname, sBlocfilename, sRootTag, sRootID, sSourcefilename, sIdref ;
	var anneecrt, moiscrt, sMois, nBlocmois, sInsertBlocMois, bContentFoundInBLOCMOIS  ;
	var annee, mois, jour, dstr, dfmt, dlst ;

	var fbloc, fsrc ;
	var nbSrcIncluded ; // nombre de sources intégrées par bloc
	var nbTotSrcIncluded ; // nombre total de sources intégrées
	var lstSrcNotIncluded = List();
	
	var sEJP ;
	var sANT ;
	if G_bEJPmode	sEJP = "EJP" ;
	else if G_bANTmode{
		sANT = "ANT" ;
	}
	else sEJP = "";

	anneecrt = "";	     // pour gestion par bloc annee
	moiscrt = "" ;       // pour gestion par bloc annee+mois
	sInsertBlocMois = "" ;

	nbTotSrcIncluded = 0 ;

	// Traitement incremental des Jrp EL 
	// mantis7336
	// if G_sSourceType == "jrpblochulk"
	if (G_sSourceType == "jrpblochulk" || G_sSourceType == "addjrpfiles"){
		for idtxtjrp in G_maptxtjrp {
			
			if  not G_setIdjrpToBuild.knows(idtxtjrp.transcript(UpperCase)) { 
				G_maptxtjrp.remove(idtxtjrp);	    
			}
		} 
	}
	// YE 4380 Dans le cas des txt pour hulk, traiter que les txt qui figures dans le set HulkTxtTobuild.set
	if (G_sSourceType == "txtblochulk" || G_sSourceType == "addtxtfiles") && !G_bANTmode{	 
		
		for idtxtjrp in G_maptxtjrp {	     
			if  not G_setIdtxtToBuild.knows(idtxtjrp.transcript(UpperCase)) { 
				G_maptxtjrp.remove(idtxtjrp);	    
			}
		} 
		cout << format("Taille de la map apres Dans le cas de '%2' : %1\n",G_maptxtjrp.length(),G_sSourceType); 
	}

	// --- on boucle sur les ID de txt/jrp de tout8
	for idtxtjrp in eSort(G_maptxtjrp, function(i) {

		//cout << format("DEBUGAL idtxtjrp =%1\n",idtxtjrp);	 

		// tri chronologique inverse
		var annee, mois, jour, crit;
		var dstr, dfmt, dlst ;

		dstr = G_maptxtjrp[i].date ;
		//cout << format("dstr %1\n",dstr);

		//else dstr = G_maptxtjrp[i].mdfdate;
		if dstr != "" dfmt = formaterDate(dstr);
		else dfmt = "" ;

		//cout << format("dfmt %1\n",dfmt);

		if G_sSourceType == "jrp" || G_sSourceType == "jrpblochulk" {
			dlst = List(G_maptxtjrp[i].jour
			,G_maptxtjrp[i].mois
			,G_maptxtjrp[i].annee);
		}
		else dlst = dfmt.explode("/");

		if dlst.length() == 3 {
			jour = dlst[0];
			mois = dlst[1];
			annee = dlst[2];
			crit = annee+mois+jour ;
		}
		else {
			cout << format("\nDEBUGYT : pb date sur %1 : date = '%2'", i, dstr);
			crit = "" ;
		}

		// --- YTR 15/06/2009 : pour éviter que l'ordre des textes bouge dans les blocs, et que ces blocs soient retraités
		// ---                  il faut ajouter des critères de tri supplémentaires pour trier lorsque la date est égale
		// ---                  on va ajouter un poids, dépendant de la norme, puis un extrait du titre, puis l'id.

		//type jrpdata(annee,mois,jour,type,ancientype,parties,date,nmr,juridic1,juridic2);
		//type txtdata(date,typeDeTexte,typeDeDocument,contentHDx,contentORG,contentNO_NOR,contentHDG_HDLDO,dateTrspo,sgmlTrspo);
		var sTypeTxtJrp = "" ;
		switch( G_sSourceType ) {
		case "txt" : sTypeTxtJrp = G_maptxtjrp[i].typeDeDocument ; break;
		case "txtblochulk" : sTypeTxtJrp = G_maptxtjrp[i].typeDeDocument ; break;
			// 18/09/2014 sfouzi
		case "addtxtfiles" : sTypeTxtJrp = G_maptxtjrp[i].typeDeDocument ; break;
		case "jrp" : sTypeTxtJrp = G_maptxtjrp[i].type ; break;
		case "jrpblochulk" : sTypeTxtJrp = G_maptxtjrp[i].type ; break;
		case "addjrpfiles" : sTypeTxtJrp = G_maptxtjrp[i].type ; break;
			
		}
		if G_mapNSWeight.knows(sTypeTxtJrp)	crit << G_mapNSWeight[sTypeTxtJrp];
		else					crit << "99" ;

		switch( G_sSourceType ) {
		case "txt" : crit << trimBoth(G_maptxtjrp[i].contentHDG_HDLDO," ") + i ; break;
		case "txtblochulk" : crit << trimBoth(G_maptxtjrp[i].contentHDG_HDLDO," ") + i ; break;
			// 18/09/2014 sfouzi
		case "addtxtfiles" : crit << trimBoth(G_maptxtjrp[i].contentHDG_HDLDO," ") + i ; break;
		case "jrp" : crit << G_maptxtjrp[i].juridic1 + G_maptxtjrp[i].juridic2 + i ; break;
		case "jrpblochulk" : crit << G_maptxtjrp[i].juridic1 + G_maptxtjrp[i].juridic2 + i ; break;
		case "addjrpfiles" : crit << G_maptxtjrp[i].juridic1 + G_maptxtjrp[i].juridic2 + i ; break;
			
		}

		//cout << format("\nDEBUGYT sort key = '%1'", crit);


		// ancien code qui exploitait les maps dico_decis.clt et dico_txt.clt
		//mois = dec(G_maptxtjrp[i].cle2) ;
		//jour = dec(G_maptxtjrp[i].cle1) ;
		//if isaNumber(mois) && isaNumber(jour)	crit = G_maptxtjrp[i].cle3+PadStr(dec(12-mois),2,"0")+PadStr(dec(31-jour),2,"0");
		//else					crit = G_maptxtjrp[i].cle3+G_maptxtjrp[i].cle2+G_maptxtjrp[i].cle1;

		return crit ;
	}) {

		// MJE 11/01/2011 on ne traite que les txt anterieures qui seront accessibles
		// on ne met pas la version du texte anterieure qui correspond a celle de tout8
		// on la reconnait car c'est la version de tout8 qui a le dernier MDFCT de la map mapMDF.map
		// (la derniere position de MDFCT dans la map)
		var idxtxtjrptmp = "";
		if G_bANTmode{
			var pos = idtxtjrp.search(0,"-mdfct");
			var G_mapMDFduTexte;
			var lastpos = 0;
			if pos > 0{
				var idtmp = idtxtjrp.extract(0,pos);
				idtmp = idtmp.transcript(UpperCase);
				G_mapMDFduTexte = G_mapMDFversionning[idtmp];
				for key,value in G_mapMDFduTexte{
					if G_mapMDFduTexte[key].mdfpos >  lastpos lastpos = G_mapMDFduTexte[key].mdfpos;
				}
			}
			idxtxtjrptmp = idtxtjrp.replace(0, "mdfct", "");
			idxtxtjrptmp  = idxtxtjrptmp.transcript(UpperCase);
			if G_mapMDFduTexte[idxtxtjrptmp].mdfpos  == lastpos continue;
		}
		//if G_sSourceType == "exoticjrp" cout << format("exoticjrp : %1 inclue\n",idtxtjrp);		
		dstr = G_maptxtjrp[idtxtjrp].date ;
		//else dstr = G_maptxtjrp[idtxtjrp].mdfdate;
		//dstr = G_maptxtjrp[idtxtjrp].date ;
		if dstr != "" dfmt = formaterDate(dstr);
		else dfmt = "" ;
		//-- 08/12/2008 AL
		//-- Dans le cas des jrp nous avons 3 champs jour, mois, annee
		//-- Utiliser les champa au lieu de calculer la date
		if G_sSourceType == "jrp" || G_sSourceType == "jrpblochulk" {
			dlst = List(G_maptxtjrp[idtxtjrp].jour
			,G_maptxtjrp[idtxtjrp].mois
			,G_maptxtjrp[idtxtjrp].annee);
		}
		else dlst = dfmt.explode("/");
		if dlst.length() == 3 {
			jour = dlst[0];
			mois = dlst[1];
			annee = dlst[2];
		}
		else {
			jour = "99";
			mois = "99";
			annee = "9999";
		}
		// --- creation les cas échéant d'un nouveau bloc
		if (G_sBlocrule=="year" && anneecrt != annee) || (G_sBlocrule=="month" && (anneecrt != annee || moiscrt != mois)) {
			// --- avant de créer un nouveau bloc, on ferme le précédent s'il existe
			if anneecrt != "" {
				// --- si gestion par bloc année, il faut fermer au sein du bloc année l'élément blocmois
				if G_sBlocrule == "year" fbloc << format("</BLOCMOIS>");

				// --- fermeture de l'element racine :
				fbloc << format("</%1>\n",sRootTag) ;
				close(fbloc);
				if nbSrcIncluded == 0 { 
					if fileAccess(sBlocfilename) {
						fileRemove(sBlocfilename); cout << format("\nfichier %1 supprimé car vide!", sBlocfilename); 
					}
				}
				// cout << format("\nCreation du bloc %1 terminée : %2 sources intégrées",fileBaseName(sBlocfilename), nbSrcIncluded);
			}
			// --- l'année courante est réajustée
			anneecrt = annee ;
			// --- en mode "bloc année", il faut initialiser le blocmois pour qu'il génère ou non des niveaux "blocmois"
			if G_sBlocrule == "year" {
				moiscrt = "" ;
				bContentFoundInBLOCMOIS = false ;
				nBlocmois = 1 ;
			}
			// --- en mode "bloc année+mois", il faut le positionner au moiscourant de manière à nommer correctement le fichier bloc
			else {
				moiscrt = mois ;
			}
			// --- constitution du nouveau bloc
			if G_sBlocrule == "year"	sBlocname = anneecrt;
			else if G_sBlocrule == "month"	sBlocname = anneecrt+moiscrt;
			sBlocfilename = format("%1%2.optj.sgm",sBlocfileRoot,sBlocname);
			cout << format("\nCreation du bloc %1",fileBaseName(sBlocfilename));
			fbloc = FileStream(sBlocfilename,"w");
			if fbloc==nothing { error format("Impossible de creer %1",sBlocfilename); return CANNOT_CREATE_BLOC; }
			nbSrcIncluded = 0 ;

			// --- choix et ouverture de l'element racine :
			switch(G_sSourceType) {
			case "txt" : sRootTag = "TXTBLOC-OPTJ" ; sRootID = format("%1TXTBLOC%2",G_zdp,sBlocname.transcript(UpperCase)); 
				if G_bANTmode  sRootID = format("%1TXTANTBLOC%2",G_zdp,sBlocname.transcript(UpperCase));
				break;
			case "txtblochulk" :  //YE 12/02/20014 4380
			case "addtxtfiles" : // 18/09/2014 sfouzi
				sRootTag = "TXTBLOC-OPTJ" ; sRootID = format("%1TXTBLOC%2",G_zdp,sBlocname.transcript(UpperCase)); 
				if G_bANTmode  sRootID = format("%1TXTANTBLOC%2",G_zdp,sBlocname.transcript(UpperCase));
				break;
			case "jrp" : sRootTag = "DECISBLOC-OPTJ" ; sRootID = format("%1%3DECISBLOC%2",G_zdp,sBlocname.transcript(UpperCase),sEJP); break;
			case "jrpblochulk" :
			case "addjrpfiles" : // 24/05/2017 alazreg
				sRootTag = "DECISBLOC-OPTJ" ; sRootID = format("%1%3DECISBLOC%2",G_zdp,sBlocname.transcript(UpperCase),sEJP); break;
				
			}
			fbloc << format("<%1 MATIERE=\"ELNET\" ID=\"%2\">",sRootTag,sRootID) ;

		}

		// --- creation les cas échéant d'un niveau blocmois dans un bloc par année
		if G_sBlocrule == "year" && moiscrt != mois {

			// --- avant de créer un blocmois, on ferme le précédent si nécessaire : un blocmois ouvert + du contenu dedans !
			if bContentFoundInBLOCMOIS {
				fbloc << format("</BLOCMOIS\n>");
				bContentFoundInBLOCMOIS = false ;
			}

			// --- on calcule la chaine d'ouverture du blocmois, qu'il faudra insérer si on trouve effectivement du contenu
			moiscrt = mois;
			if MapIntMois.knows(moiscrt) sMois = MapIntMois[moiscrt]; else sMois = "";
			sInsertBlocMois = format("<BLOCMOIS ID=\"%1-%2\" T=\"%3\">",sRootID,nBlocmois++,sMois);
		}

		if !G_bEJPmode {
			sIdref = idtxtjrp.transcript(LowerCase) ;
			// YE 22/05/2014
			//cout << format("sIdref %1 - ",sIdref);
			sSourcefilename = format("%1%2.optj.sgm",sSourcedir,sIdref);
			//cout << format("sSourcefilename %1\n",sSourcefilename);
			/*
			17/09/2012 MB : important remplacer "exoticjrp" par "jrp" !
			*/
			sSourcefilename = sSourcefilename.replace(0, "jrpblochulk","jrp");
			//cout << format("\n\tsSourcefilename = %1\n",sSourcefilename);
		}
		else {
			sIdref = idtxtjrp ; // pas de passage en majuscule !

			// --- on récupère le nom de fichier "splitté" : racine du lot EJP traité + découpage "splitpath" + opt/optj + nom du fichier
			
			// Appel a la nouvelle fct Balise splitpath
			var sSplitFileName = "" ;
			sSplitFileName = splitPath_v2(format("%1.optj.sgm", sIdref.explode(".")[0] ),1);
			sSourcefilename = format("%1%2", sSourcedir, trimRight(sSplitFileName,"\n"));

			/*
			// var sSplitFileName = "" ;
			// var splitpathcmd = format("/mac.public/splitpath/dpmprod/splitpath_v2.exe %1.optj.sgm 1", sIdref.explode(".")[0] );
			
			// --- REMARQUE : on utilise un "pipe" pour lire le résultat de la commande iconv
			// ---            plutot que de faire un appel "system" redirigé dans un fichier
			// var splitpathoutput = FileStream( splitpathcmd + "|", "r");
			// if splitpathoutput != nothing {
				// cout << format("\n ==========> fichier source a lire = %1\n",splitpathoutput);
				// sSplitFileName << readAll(splitpathoutput);
				// close(splitpathoutput);
			// }
			// else cout << format("\nDEBUGYT : ERREUR splitpath : output vide : %1", splitpathcmd);

			// sSourcefilename = format("%1%2", G_sEJPlivRoot, sSplitFileName);
			//cout << format("\nDEBUGYT : splitPathName = '%1'", sSourcefilename);
					*/

		}
		fsrc = FileStream(sSourcefilename,"r");
		if fsrc==nothing {
			// avant de gueuler, on vérifie que l'IDREF n'est pas un IDREF
			// de type "ADIDX", comme par exemple Z4A-xxxx :
			if sIdref[2]==asc("a") && sIdref[3]==asc("-") {
				//cout  << format("\n/// fichier %1 non trouvé mais ignoré car idref='%2' (adidx)",
				//			fileBaseName(sSourcefilename), sIdref);
			}
			else {
				//error format("impossible d'acceder a %1",sSourcefilename);
				lstSrcNotIncluded << sIdref ;
			}
			continue;
		}
		else {
			// YTR 21/07/2005 : on cree un bloc uniquement s'il y a des textes qu'il faut conserver dedans...
			//                  (correction bug blocmois vide car textes uniquement de type adidx dedans)
			if sInsertBlocMois != "" {
				fbloc << sInsertBlocMois ;
				sInsertBlocMois = "" ;
				bContentFoundInBLOCMOIS = true ;
			}

			fbloc << readAll(fsrc);
			nbSrcIncluded++;
			nbTotSrcIncluded++;
			//cout << format("%1 ",sIdref);
			// cout << "."; flush(cout);
			close(fsrc);
		}
	}
	// --- fermeture de l'element BLOCMOIS (si blocs par année) :
	// 25/07/2013 MB : avec les jrpexoticmat, il peut arriver que la map soit vide ==> on ajoute un test sur le fbloc
	// if G_sBlocrule=="year" fbloc << format("</BLOCMOIS\n>");
	if G_sBlocrule=="year" {
		if isaStream(fbloc)  fbloc << format("</BLOCMOIS\n>");
	}

	// --- fermeture de l'element racine
	// 25/07/2013 MB : avec les jrpexoticmat, il peut arriver que la map soit vide ==> on ajoute un test sur le fbloc 
	// fbloc << format("</%1>\n",sRootTag) ;
	if isaStream(fbloc) fbloc << format("</%1>\n",sRootTag) ;
	if isaStream(fbloc) close(fbloc);
	// 26/02/2014 MB : fileAccess(path
	//if nbSrcIncluded == 0 fileRemove(sBlocfilename);
	
	if nbSrcIncluded == 0 {
		if (isaString(sBlocfilename) && fileAccess(sBlocfilename)) fileRemove(sBlocfilename);
	}

	if (nbTotSrcIncluded - G_maptxtjrp.length()) > 0 {
		cout << format("\n\nFin de la création : %1 sources intégrées", nbTotSrcIncluded );
		cout << format("\nATTENTION : %1 sources non trouvées ! (Ces sources sont référencées dans les maptxt/mapjrp alors qu'ils n'existent plus : il y a du ménage à faire semble-t-il...)\n", nbTotSrcIncluded - G_maptxtjrp.length());
		for id in lstSrcNotIncluded {
			cout << format("%1 ",id);
		}
	}
	cout << "\n\n";
}




/*--------------------------------------------------------------------
createBlocsEJPELNET() : creation bloc ELNET EJP d'après pmap + entrepot sgml EJP
			optionnel : si yearBegin et/ou yearEnd sont précisés,
									la fonction ne traitera que l'intervalle à partir de yearBegin
									(ou depuis le début si vide), et jusqu'à yearEnd (ou jusqu'à la fin si vide)
--------------------------------------------------------------------*/
function createBlocsEJPELNET(sBlocfileRoot,sSourcedir,sYearBegin,sYearEnd) {

	var sBlocname, sBlocfilename, sRootTag, sRootID, sSourcefilename, sIdref ;
	var anneecrt, moiscrt, sMois, nBlocmois, sInsertBlocMois, bContentFoundInBLOCMOIS  ;
	var fbloc, fsrc ;
	var nbSrcIncluded ; // nombre de sources intégrées par bloc
	var nbTotSrcIncluded ; // nombre total de sources intégrées
	var lstSrcNotIncluded = List();
	
	var lstEJPpmapSortedKeys = List();

	var pmapval, crit, sTypeTxtJrp;
	var pmapReadCpt, pmapCount ;

	var nYearBegin, nYearEnd, nYearCrt ;

	var sEJP ;
	var sANT ;
	if G_bEJPmode	sEJP = "EJP" ;
	else		sEJP = "";

	// --- YTR 23/02/2011 :on charge une pmap jrpinfoEJP dans $ELA_DATA/prodmaps
	var pmapname = "jrpinfoEJP" ;
	var pmapfilepath = format("%1%2prodmaps%2pmaps%2%3",env("ELA_DATA"),SEP, pmapname);

	var pmapjrpEJP = getPMap(pmapfilepath,pmapname) ;
	if pmapjrpEJP != nothing {			

		pmapCount =  pmapjrpEJP.pmCount() ;
		cout << format("\nOuverture de la pmap %1 effectué avec succès, il y a %2 enregistrements", pmapname, pmapCount);

		// --- pour permettre la création des blocs, il faut générer une liste ordonnée des identifiants à récupérer dans la pmap
		// --- pour cela, on va commencer à générer une map "allégée" contenant uniquement les id et une chaîne permettant de trier

		cout << format("\n\nAnalyse de la map en cours pour déterminer les critères de tri : 00%%"); flush(cout);


		G_maptxtjrp = Map();
		pmapReadCpt = 0 ;

		for key, value  in pmapjrpEJP {

			// --- les maps ne stockent que des types d'objets "simple" : number, boolean, string
			// --- donc pour récupérer la structure jrpdata, on converti en objet :
			pmapval = Object(value);

			// tri chronologique inverse
			crit = pmapval.annee+pmapval.mois+pmapval.jour ;

			// --- il faut ajouter des critères de tri supplémentaires pour trier lorsque la date est égale :
			// --- on va ajouter un poids, dépendant de la norme/juridiction, puis un extrait du titre, puis l'id.
			//type jrpdata(annee,mois,jour,type,ancientype,parties,date,nmr,juridic1,juridic2);
			//type txtdata(date,typeDeTexte,typeDeDocument,contentHDx,contentORG,contentNO_NOR,contentHDG_HDLDO,dateTrspo,sgmlTrspo);

			sTypeTxtJrp = "" ;
			switch( G_sSourceType ) {
			case "txt" : sTypeTxtJrp = pmapval.typeDeDocument ; break;
			case "jrp" : sTypeTxtJrp = pmapval.type ; break;
			}
			if G_mapNSWeight.knows(sTypeTxtJrp)	crit << G_mapNSWeight[sTypeTxtJrp];
			else					crit << "99" ;

			switch( G_sSourceType ) {
			case "txt" : crit << trimBoth(pmapval.contentHDG_HDLDO," ") + key ; break;
			case "jrp" : crit << pmapval.juridic1 + pmapval.juridic2 + key ; break;
			}

			G_maptxtjrp[key] = crit ;
			if (++pmapReadCpt % 100 == 0) { cout << format("%1$02d%%",100*pmapReadCpt/pmapCount); flush(cout); }
			//cout << format("\nDEBUGYT ajout G_maptxtjrp[%1] = '%2'", key, crit);
		}
		cout << format("100%%\n");

		// --- on tri la map pour récupérer les id de jrp EJP dans l'ordre souhaité
		cout << format("\n\nCréation de la liste triée des id EJP..."); flush(cout);
		lstEJPpmapSortedKeys = eSort(G_maptxtjrp, function(i) { return G_maptxtjrp[i]; });
		cout << format("Ok (la liste contient %1 ids)\n",lstEJPpmapSortedKeys.length());

		// --- on détruit la map désormais inutile pour libérer la mémoire 
		G_maptxtjrp = nothing ;

	}
	else {
		cout << format("\n\nERREUR FATALE : impossible d'ouvrir la pmap %1 avec le chemin %2\n\n", pmapname, pmapfilepath);
	}

	
	// --- définition de l'intervalle d'années qu'il faut traiter (en fonction des éventuels paramètres passés en ligne de commande)
	if sYearBegin != ""	{ nYearBegin = dec(sYearBegin) ; if !isaNumber(nYearBegin) nYearBegin=0; }
	else			nYearBegin = 0 ;

	if sYearEnd != ""	{ nYearEnd = dec(sYearEnd) ; if !isaNumber(nYearEnd) nYearEnd=999999; }
	else			nYearEnd = 999999 ;


	anneecrt = "";	     // pour gestion par bloc annee
	moiscrt = "" ;       // pour gestion par bloc annee+mois
	sInsertBlocMois = "" ;

	nbTotSrcIncluded = 0 ;

	// --- on boucle sur la liste contenant les id de jrp EJP, déjà triés dans l'ordre souhaité
	for idtxtjrp in lstEJPpmapSortedKeys {

		pmapval = Object(pmapjrpEJP.pmGet(idtxtjrp));

		// --- YTR 23/02/2011 : on prévoit de zapper les sources qui ne figurent pas dans un intervalle d'année précis
		// ---                  afin de permettre le travail sur des intervalles spécifiques, ainsi que la parallélisation
		// ---                  de la création des blocs jrp EJP (ex: de 1600 à 1900, de 1901 à 2000, et de 2001 à 2010 sur 3 processeurs)
		nYearCrt = dec(pmapval.annee);
		if nYearCrt < nYearBegin || nYearCrt > nYearEnd {
			continue ;
		}

		// --- creation les cas échéant d'un nouveau bloc
		if (G_sBlocrule=="year" && anneecrt != pmapval.annee) || (G_sBlocrule=="month" && (anneecrt != pmapval.annee || moiscrt != pmapval.mois)) {

			// --- avant de créer un nouveau bloc, on ferme le précédent s'il existe
			if anneecrt != "" {

				// --- si gestion par bloc année, il faut fermer au sein du bloc année l'élément blocmois
				if G_sBlocrule == "year" fbloc << format("</BLOCMOIS>");

				// --- fermeture de l'element racine :
				fbloc << format("</%1>\n",sRootTag) ;
				close(fbloc);
				if nbSrcIncluded == 0 { 
					if fileAccess(sBlocfilename) {
						fileRemove(sBlocfilename); cout << format("\nfichier %1 supprimé car vide!", sBlocfilename); 
					}
				}
				cout << format("%1$05d sources intégrées avec succès", nbSrcIncluded);
			}

			// --- l'année courante est réajustée
			anneecrt = pmapval.annee ;

			// --- en mode "bloc année", il faut initialiser le blocmois pour qu'il génère ou non des niveaux "blocmois"
			if G_sBlocrule == "year" {
				moiscrt = "" ;
				bContentFoundInBLOCMOIS = false ;
				nBlocmois = 1 ;
			}
			// --- en mode "bloc année+mois", il faut le positionner au moiscourant de manière à nommer correctement le fichier bloc
			else {
				moiscrt = pmapval.mois ;
			}

			// --- constitution du nouveau bloc
			if G_sBlocrule == "year"	sBlocname = anneecrt;
			else if G_sBlocrule == "month"	sBlocname = anneecrt+moiscrt;

			sBlocfilename = format("%1%2.optj.sgm",sBlocfileRoot,sBlocname);
			cout << format("\nIntégration de sources dans le bloc %1 : 00000",fileBaseName(sBlocfilename));
			fbloc = FileStream(sBlocfilename,"w");
			if fbloc==nothing { error format("Impossible de creer %1",sBlocfilename); return CANNOT_CREATE_BLOC; }
			nbSrcIncluded = 0 ;

			// --- choix et ouverture de l'element racine :
			switch(G_sSourceType) {
			case "txt" : sRootTag = "TXTBLOC-OPTJ" ; sRootID = format("%1TXTBLOC%2",G_zdp,sBlocname.transcript(UpperCase)); 
				if G_bANTmode  sRootID = format("%1TXTANTBLOC%2",G_zdp,sBlocname.transcript(UpperCase));
				break;
			case "jrp" : sRootTag = "DECISBLOC-OPTJ" ; sRootID = format("%1%3DECISBLOC%2",G_zdp,sBlocname.transcript(UpperCase),sEJP); break;
			}
			fbloc << format("<%1 MATIERE=\"ELNET\" ID=\"%2\">",sRootTag,sRootID) ;

		}

		// --- creation les cas échéant d'un niveau blocmois dans un bloc par année
		if G_sBlocrule == "year" && moiscrt != pmapval.mois {

			// --- avant de créer un blocmois, on ferme le précédent si nécessaire : un blocmois ouvert + du contenu dedans !
			if bContentFoundInBLOCMOIS {
				fbloc << format("</BLOCMOIS\n>");
				bContentFoundInBLOCMOIS = false ;
			}

			// --- on calcule la chaine d'ouverture du blocmois, qu'il faudra insérer si on trouve effectivement du contenu
			moiscrt = pmapval.mois;
			if MapIntMois.knows(moiscrt) sMois = MapIntMois[moiscrt]; else sMois = "";
			sInsertBlocMois = format("<BLOCMOIS ID=\"%1-%2\" T=\"%3\">",sRootID,nBlocmois++,sMois);
		}

		sIdref = idtxtjrp ; // pas de passage en majuscule !

		// --- on récupère le nom de fichier "splitté" : racine du lot EJP traité + découpage "splitpath" + opt/optj + nom du fichier
		
		//
		// YTR 17/02/2011 ------------------- ATTENTION ------
		//
		// la fonction splitpath n'est plus à jour des dernières modifications demandées à Léandre (pour la version C / dpmprod)
		// en raison du nommage des fichiers Jurica avec un timestamp
		//
		// je court-circuite cette fonction et procède à un appel système pour invoquer l'exécutable développé par Léandre
		// à voir si cela est plus long que de recoder l'algo dans balise
		// ==> pas le temps pour le moment de jouer à ça
		//
		//var sSplitFileName = getSplitPath(format("%1.optj.sgm",sIdref),true);


		var sSplitFileName = "" ;
		var splitpathcmd = format("/mac.public/splitpath/dpmprod/splitpath_v2.exe %1.optj.sgm 1", sIdref.explode(".")[0] );
		
		// --- REMARQUE : on utilise un "pipe" pour lire le résultat de la commande iconv
		// ---            plutot que de faire un appel "system" redirigé dans un fichier
		var splitpathoutput = FileStream( splitpathcmd + "|", "r");
		if splitpathoutput != nothing {
			sSplitFileName << readAll(splitpathoutput);
			close(splitpathoutput);
		}
		else cout << format("\nDEBUGYT : ERREUR splitpath : output vide : %1", splitpathcmd);

		sSourcefilename = format("%1%2", sSourcedir, trimRight(sSplitFileName,"\n"));
		//cout << format("\nDEBUGYT : splitPathName = '%1'", sSourcefilename);


		fsrc = FileStream(sSourcefilename,"r");
		if fsrc==nothing {
			error format("impossible d'acceder a %1",sSourcefilename);
			lstSrcNotIncluded << sIdref ;
			continue;
		}
		else {
			// --- on cree un bloc uniquement s'il y a des textes qu'il faut conserver dedans...
			if sInsertBlocMois != "" {
				fbloc << sInsertBlocMois ;
				sInsertBlocMois = "" ;
				bContentFoundInBLOCMOIS = true ;
			}

			fbloc << readAll(fsrc);
			nbSrcIncluded++;
			nbTotSrcIncluded++;
			//cout << format("%1 ",sIdref);
			if ( nbSrcIncluded % 100 == 0 ) cout << format("%1$05d",nbSrcIncluded); flush(cout);
			close(fsrc);
		}
	}

	if isaStream(fbloc) {

		// --- fermeture de l'element BLOCMOIS (si blocs par année) :
		if G_sBlocrule=="year" fbloc << format("</BLOCMOIS\n>");

		// --- fermeture de l'element racine
		fbloc << format("</%1>\n",sRootTag) ;
		close(fbloc);
		// 26/02/2014 MB : fileAccess(path
		//if nbSrcIncluded == 0 fileRemove(sBlocfilename);
		if nbSrcIncluded == 0 {
			if fileAccess(sBlocfilename) fileRemove(sBlocfilename);
		}
		//if nbSrcIncluded == 0 fileRemove(sBlocfilename);
		cout << format("%1$05d sources intégrées avec succès", nbSrcIncluded);
	}

	if (nbTotSrcIncluded - lstEJPpmapSortedKeys.length()) > 0 {
		cout << format("\n\nFin de la création : %1 sources intégrées", nbTotSrcIncluded );
		cout << format("\nATTENTION : %1 sources non trouvées ! (Ces sources sont référencées dans les maptxt/mapjrp alors qu'ils n'existent plus : il y a du ménage à faire semble-t-il...)\n", nbTotSrcIncluded - lstEJPpmapSortedKeys.length());
		for id in lstSrcNotIncluded {
			cout << format("%1 ",id);
		}
	}
	cout << "\n\n";


	// --- ne pas oublier de fermer la pmap EJP !
	closePMapStorage(pmapjrpEJP);

}




function getSplitPathTimeStamp(fileName, timeStamp) {
	// implémenté directement dans la fct principale (pour raison de perf)
}


/*
fonction splitPath_v2 : cette fonction est conforme au programme C splitPath_v2.exe (LV) 
						elle traite les cas avec ou sans timestamp
	param1 : nom du fichier (sans le path)
	param2 : bIgnoreLeadingLetters toujours à 1
	rmq. : 
			ex. d'appel sans timestamp :	splitPath_v2("cetatext0000007422409.optj.sgm", 1) --> "/cetatext/000/000/742/240/cetatext0000007422409.optj.sgm"		   
			ex. d'appel avec timestamp :
				cas1/ timestamp au début : splitPath_v2("20090904_070001_9613_ca_agen.optj.sgm", 1)   --> "/2009/09/04/0700/20090904_070001_9613_ca_agen.optj.sgm"
				cas1/ timestamp à la fin : splitPath_v2("ca_douai_20080314_004029_1896.optj.sgm", 1) --> "/ca/douai/2008/03/14/040/ca_douai_20080314_004029_1896.optj.sgm"
		
*/

/*
function splitPath_v2(fileName,bIgnoreLeadingLetters) {
	
	// transferée  dans utils.lib
*/

/*--------------------------------------------------------------------
getBlocForThisJrp : retourne le bloc de la jrp si celui-ci existe
					-1 si le bloc n'existe pas (est à construire)	
ex. de blocs : elnet_jrpblocEJP_20090122-20090126.optj.sgm, ...						
/*--------------------------------------------------------------------*/

function getBlocForThisJrp(jrp){
	// implémenté directement ds le programme
}

/*--------------------------------------------------------------------
nettoyerBlocsCaducs : supprime les fichiers de blocs caducs :
					qui sont ds mapAllExistingBlocs et absents de setAllNewJrpBlocs				
/*--------------------------------------------------------------------*/

function nettoyerBlocsCaducs(sBlocfileRoot){
	
	// AFFICHER LA LISTE DES BLOCS QUI DOIVENT EXISTER
	//cout << format("\tLISTE DES BLOCS QUI DOIVENT EXISTER :\n");
	//for b in setAllNewJrpBlocs cout << format("%s;",b);
	// AFFICHER LA LISTE DES BLOCS A (RE)CONSTRUIRE
	//cout << format("\n\tLISTE DES BLOCS A (RE)CONSTRUIRE :\n");
	//for b in listUpdateBlocs cout << format("%s;",b);
	cout << format("Suppression des blocs caducs...\n");
	var nbsupp = 0;
	// SUPPRIMER LES BLOCS CADUCS (présents ds setAllExistingBlocs et absents de setAllNewJrpBlocs)
	for bloc in mapAllExistingBlocsDates {
		if !setAllNewJrpBlocs.knows(bloc) {
			var blocFile = format("%1%2.optj.sgm",sBlocfileRoot,bloc);
			cout << format("\tsuppression bloc : %s-->%s\n",bloc,blocFile);
			if !fileRemove(blocFile){
				cout << format("Impossible de supprimer le fichier bloc : %s\n",blocFile);
			}
			else ++nbsupp;
		}
	}
	cout << format("\t%s bloc(s) supprimés\n",nbsupp);
}
/*--------------------------------------------------------------------
getSetAllExistingBlocs : calcule un Set des blocs existants dans le repertoire en paramètre
						à partir des fichiers présents dans : $ELA_DATA/jrpblocsEJP/*.optj.sgm
ex. de blocs : elnet_jrpblocEJP_20090122-20090126.optj.sgm, ...						
ex. de résultat : Set("20110629-20110630", "19730710-19740319", ...)
/*--------------------------------------------------------------------*/

function getSetAllExistingBlocs(dir){
	var files = fileReadDir(dir);
	var lstBlocs = List();
	if files == nothing return;
	//cout << format("\n ----> fonction getSetAllExistingBlocs\tdir = %s\n",dir);
	// initialiser 
	setAllExistingBlocs = Set();
	for blocfile in files {
		var matches = blocfile.rsearch(regExpBlocInterval);
		//cout << format("matches=%s\n",matches);
		if matches != nothing {			// l'ajouter comme bloc existant (son intervalle) 
			// renseigner sa date ici
			var time = fileDate(filePath(dir,blocfile));
			var date = "00000000";
			if time != nothing {
				date = timeFormat(time, "%Y%m%d");
			}
			mapAllExistingBlocsDates[matches[0].sub[0].value] = date;
		}
		else {
			//LOG << format("Warning : le bloc %1 est ignoré\n",blocfile);
			cout << format("Warning : le bloc %1 est ignoré\n",blocfile);
		}
	}
	//for b, d in mapAllExistingBlocsDates	cout << format("\t%s:%s;",b,d);
	cout << format("nbre de blocs trouvés=%s\n",mapAllExistingBlocsDates.length());
}

function creationNouveauBloc(pmapval, anneecrt, moiscrt, jourcrt, anneePrec, moisPrec, jourPrec, nbSrcIncluded, taillebloc, mode) forward;
/*--------------------------------------------------------------------
getSetAllNewJrpBlocs : crée un Set de tout les blocs qui devront exister 
					+ une liste des blocs à (re)construire : listUpdateBlocs
					cette fonction est une execution "à blanc" de la fct createBlocsEJPELNET_NEW()
					pour determiner la liste des blocs à reconstruire
/*--------------------------------------------------------------------*/

function getSetAllNewJrpBlocs(lstEJPpmapSortedKeys,sSourcedir,pmapjrpEJP,nYearBegin, nYearEnd, sBlocfileRoot){

	//cout << format("\n ----> fonction getSetAllNewJrpBlocs\nsBlocfileRoot=%s\n",sBlocfileRoot);
	var sBlocname, sBlocfilename, sSourcefilename, sIdref, pmapval, jrpLastUpdate, blocDate;
	var anneecrt, moiscrt, sMois,  jourcrt, sJours, nYearCrt, taillebloc; // taille du blocs
	var nbSrcIncluded ; 									// nombre de sources intégrées par bloc
	var nbTotSrcIncluded ; 									// nombre total de sources intégrées
	var lstSrcNotIncluded = List();
	var bCreateFirstBloc = true, blocEnCours = false; ;
	var anneePrec="00", moisPrec = "00", jourPrec="00";		// --- annee/mois/jour de l'element précédemment vu
	// --- on boucle sur la liste contenant les id de jrp EJP, déjà triés dans l'ordre souhaité
	var LOG = FileStream(logFile,"w");
	var idtxtjrp;
	nbRebuild = 0;
	nbNew = 0;
	for idtxtjrp in lstEJPpmapSortedKeys {
		pmapval = Object(pmapjrpEJP.pmGet(idtxtjrp));
		nYearCrt = dec(pmapval.annee);
		jrpLastUpdate = pmapval.maplastupdate;
		
		if nYearCrt < nYearBegin || nYearCrt > nYearEnd {
			continue ;
		}
		
		// MB 10/08/2011 : ajouté pour ignorer les dates erronées ==> pour ne pas perturber le nouvel algo....
		if nYearCrt < 1000 || nYearCrt > 2099 {	
			continue ;
		}
		
		// --- creation les cas échéant d'un nouveau bloc
		if (G_sBlocrule=="day" && (bCreateFirstBloc || 
					creationNouveauBloc(pmapval, anneecrt, moiscrt, jourcrt, anneePrec, moisPrec, jourPrec, nbSrcIncluded, taillebloc, 0))) 
		{ 
			if blocEnCours {
				blocEnCours = false;
				
				// RENOMMAGE
				var sBlocnameNew = format("%s-%s%s%s", sBlocname, anneePrec, moisPrec, jourPrec);
				// INSERER DS LE SET
				if nbSrcIncluded > 0	{
					setAllNewJrpBlocs << sBlocnameNew;
					if (mapAllExistingBlocsDates.knows(sBlocnameNew) && jrpLastUpdate > mapAllExistingBlocsDates[sBlocnameNew]){
						// si date maj + récente que bloc => ajouter ce blocs à la liste des blocs à reconstruire 
						listUpdateBlocs << sBlocnameNew;
						LOG << format("Detection d'un bloc à reconstruire %s : %s dernière maj jrp = %s jrp = %s\n", sBlocnameNew, mapAllExistingBlocsDates[sBlocnameNew],jrpLastUpdate, idtxtjrp);
						cout << format("\n\tDetection d'un bloc à reconstruire %s dernière maj jrp = %s jrp = %s\n", sBlocnameNew, mapAllExistingBlocsDates[sBlocnameNew],jrpLastUpdate, idtxtjrp);
						nbRebuild++;
					}			
					else if !mapAllExistingBlocsDates.knows(sBlocnameNew){
						// ajouter ce blocs à la liste des blocs à construire (même liste que pour reconstruire)
						listUpdateBlocs << sBlocnameNew;
						LOG << format("Detection d'un nouveau bloc à construire %s : pour jrp --> %s : %s\n", sBlocnameNew, jrpLastUpdate, idtxtjrp);
						cout << format("\n\tDetection d'un nouveau bloc à construire %s : pour jrp --> %s : %s", sBlocnameNew, jrpLastUpdate, idtxtjrp);
						nbNew++;
					}
				}			
			}
			bCreateFirstBloc = false ; // ca ne sert que la premiere fois pour arriver ici sur la premiere jrp... RIP :-)
			// --- Repositionner les dates pour le prochain bloc
			anneecrt = pmapval.annee;
			moiscrt = pmapval.mois;
			jourcrt = pmapval.jour;		
			// CREATION NOUVEAU BLOC
			sBlocname = format("%s%s%s", anneecrt, moiscrt, jourcrt);
			//cout << format("\nIntégration de sources dans le bloc : %1",sBlocname);
			// RAZ du compteur de sources et de la taille du bloc de sources
			nbSrcIncluded = 0 ;
			taillebloc = 0 ;
			blocEnCours = true;	
		}
		sIdref = idtxtjrp ;
		// Appel a la nouvelle fct Balise splitpath
		var sSplitFileName = "" ;
		sSplitFileName = splitPath_v2(format("%1.optj.sgm", sIdref.explode(".")[0] ),1);
		sSourcefilename = format("%1%2", sSourcedir, trimRight(sSplitFileName,"\n"));
		if fileAccess(sSourcefilename) {
			// On cree un bloc uniquement s'il y a des textes qu'il faut conserver dedans...
			nbSrcIncluded++;
			taillebloc += fileSize(sSourcefilename);
			nbTotSrcIncluded++;
		}
		else {
			//cout << format("Erreur ! fichier source inexistant ! %1\n",sSourcefilename);
			lstSrcNotIncluded << sIdref ;
		}
		anneePrec=pmapval.annee;
		moisPrec=pmapval.mois;
		jourPrec=pmapval.jour;
	}	
	// TRAITEMENT DU DERNIER BLOC  RENOMMAGE
	var sBlocnameNew = format("%s-%s%s%s", sBlocname, anneePrec, moisPrec, jourPrec);
	// INSERER DS LE SET
	if nbSrcIncluded > 0	{
		setAllNewJrpBlocs << sBlocnameNew;
		
		//LOG << format("%s\n",sBlocnameNew);
		// si bloc existant 
		//if (mapAllExistingBlocsDates.knows(sBlocnameNew))
		//LOG << format("jrp=%s\tsBlocnameNew=%s\tdate=%s\tjrpLastUpdate=%s\n",idtxtjrp,sBlocnameNew,mapAllExistingBlocsDates[sBlocnameNew],jrpLastUpdate);
		if (mapAllExistingBlocsDates.knows(sBlocnameNew) && jrpLastUpdate > mapAllExistingBlocsDates[sBlocnameNew]){
			// ajouter ce blocs à la liste des blocs à reconstruire 
			listUpdateBlocs << sBlocnameNew;
			LOG << format("\tBloc à reconstruire %s : %s pour jrp --> %s : %s\n", sBlocnameNew, jrpLastUpdate, idtxtjrp, mapAllExistingBlocsDates[sBlocnameNew]);
			cout << format("\tBloc à reconstruire %s : %s pour jrp --> %s : %s\n", sBlocnameNew, jrpLastUpdate, idtxtjrp, mapAllExistingBlocsDates[sBlocnameNew]);
			nbRebuild++;
		}			
		else if !mapAllExistingBlocsDates.knows(sBlocnameNew){
			// ajouter ce blocs à la liste des blocs à construire (même liste que pour reconstruire)
			listUpdateBlocs << sBlocnameNew;
			LOG << format("\tBloc à construire %s : pour jrp --> %s : %s\n", sBlocnameNew, jrpLastUpdate, idtxtjrp);
			cout << format("\tBloc à construire %s : pour jrp --> %s : %s\n", sBlocnameNew, jrpLastUpdate, idtxtjrp);
			nbNew++;
		}
	}
	cout << format("\n\t%s nouveau(x) bloc(s) à créer\n",nbNew);
	cout << format("\t%s ancien(s) bloc(s) à reconstruire\n",nbRebuild);
	close(LOG);	
}

/*--------------------------------------------------------------------
fonction jrpDansBlocAconstruire : teste si la date de dernière m-à-j de la jrp
				est ds l'intervale d'un bloc à reconstruire 
	retourne : 
			le bloc si oui
			nothing sinon
/*--------------------------------------------------------------------*/

function jrpDansBlocAconstruire(annee,mois,jour){
	// parcourt des blocs à reconstruire
	var datejrp = annee+mois+jour;
	for bloc in listUpdateBlocs {
		var intervalle = bloc.explode("-");
		if intervalle.length() != 2 {
			cerr << format("Erreur ! format bloc erroné.");
			abort;
		}
		else {
			//cout << format(" test %s =< %s <= %s ?\n",intervalle[0],datejrp,intervalle[1]);
			if (datejrp >= intervalle[0] && datejrp <= intervalle[1]){
				//cout << format("Bloc à reconstruire ==> maplastupdate(jrp) ds intervalle : %s\n",bloc);
				return bloc;
			}
		}
	}
	return nothing;
}

/*--------------------------------------------------------------------
creationNouveauBloc : déplacement de la condition de creation de blocs dans cette fct
	retourne : 
			vrai si la condition de création d'un nouveau bloc est remplie
			faux sinon
	condition de création d'un nouveau :
	// règle1 : j ou m ou a a changé 
	// règle2 : un des seuils taille ou nbre jrp atteints
	// règle3 : fichiers de même date dans un même bloc
/*--------------------------------------------------------------------*/

function creationNouveauBloc(pmapval, anneecrt, moiscrt, jourcrt, anneePrec, moisPrec, jourPrec, nbSrcIncluded, taillebloc, mode) {

	/*if ((pmapval.annee.length() < 4) || (pmapval.mois.length() < 2) || (pmapval.jour.length() < 2)) {
		cout << format("\n(((((((((((((((\npmapval=%s\n))))))))))))))\n",pmapval);
		abort;
	}*/
	nbAppelCreationBlocs++;
	/*****************************************************************************
	// ajout nouvelles règles (YT) : 
	//---------------------------------
	// règle-1 : si annee >= 1960  => changer de bloc seulement si annee change
	// règle-2 : si annee >= 2000 => changer de bloc seulement si mois change
	//---------------------------------*/
	/****************************************************************************
	// règle1 : j ou m ou a a changé 
	// règle2 : nbre jrp atteints
	// règle3 : même date sur un même bloc
	// taille < 0 : concerne la création du 1er bloc
	*****************************************************************************/
	
	// règle-1 : si annee >= 1960  => changer de bloc seulement si annee change
	if((dec(anneecrt) >= 1960) && (anneecrt != pmapval.annee) 
			// règle-2 : si annee >= 2000 => changer de bloc seulement si mois change
			|| (dec(anneecrt) >= 2000) && (moiscrt != pmapval.mois)) {
		
		if mode == 1 cout << format("\n\t\t=======>Regle creationNouveauBloc OK(annee >= 1960 ou >= 2000) : %s/%s/%s - %s/%s/%s\ttaille bloc = %s\tnbSrcIncluded=%s\n",anneecrt, moiscrt, jourcrt, anneePrec, moisPrec, jourPrec, taillebloc, nbSrcIncluded) ;
		return true;	
	}
	
	// sinon appliquer les anciennes règles
	
	else if (anneecrt != pmapval.annee || moiscrt != pmapval.mois || jourcrt != pmapval.jour)        // on crée un nouveau bloc si on change de jour et...
	&&  taillebloc >= LIMIT_TAILLE_BLOC						// nbSrcIncluded >= LIMIT_NB_JRP						 	// si on dépasse le nb jp limite
	&& (anneePrec != pmapval.annee || moisPrec != pmapval.mois || jourPrec != pmapval.jour) // on finit le jour en cours s'il a été commencé
	{
		if mode == 1 cout << format("\n\t\t=======>Regle creationNouveauBloc OK: %s/%s/%s - %s/%s/%s\ttaille bloc = %s\tnbSrcIncluded=%s\n",anneecrt, moiscrt, jourcrt, anneePrec, moisPrec, jourPrec, taillebloc, nbSrcIncluded) ;
		return true;
	}
	return false;
}



/*--------------------------------------------------------------------
createBlocsEJPELNET_NEW() : creation bloc ELNET EJP d'après pmap + entrepot sgml EJP
			optionnel : si yearBegin et/ou yearEnd sont précisés,
									la fonction ne traitera que l'intervalle à partir de yearBegin
									(ou depuis le début si vide), et jusqu'à yearEnd (ou jusqu'à la fin si vide)
			Nouvelles règles de créatuion des blocs:
				// règle1 : j ou m ou a a changé 
				// règle2 : un des seuils taille ou nbre jrp atteints
				// règle3 : même date sur un même bloc
// MB : rendre la création des blocs incrémentale ....
--------------------------------------------------------------------*/
function createBlocsEJPELNET_NEW(sBlocfileRoot,sSourcedir,sYearBegin,sYearEnd) {

	// ne pas toucher à la prod:
	//sBlocfileRoot = "/home/mbaziz/documents/optimise_makeblocs/data/res/jrp/elnet_jrpblocEJP_";
	cout << format("\nje suis dans createBlocsEJPELNET_NEW\n");
	cout << format("sBlocfileRoot = %1\tsSourcedir=%2\tsYearBegin=%3\tsYearEnd=%4\tG_sBlocrule=%5\n",sBlocfileRoot,sSourcedir,sYearBegin,sYearEnd,G_sBlocrule);
	

	var sBlocname, sBlocfilename, sRootTag, sRootID, sSourcefilename, sIdref ;
	var anneecrt, moiscrt, sMois, nBlocmois, sInsertBlocMois, bContentFoundInBLOCMOIS  ;
	var jourcrt, sJours;
	var fbloc, fsrc ;
	var nbSrcIncluded ; // nombre de sources intégrées par bloc
	var taillebloc ;	// taille du blocs
	var nbTotSrcIncluded ; // nombre total de sources intégrées
	var lstSrcNotIncluded = List();
	var lstEJPpmapSortedKeys = List();
	var pmapval, crit, sTypeTxtJrp;
	var pmapReadCpt, pmapCount ;
	var nYearBegin, nYearEnd, nYearCrt ;
	var sEJP ;
	var sANT ;
	var bCreateFirstBloc = true ;
	
	if G_bEJPmode	sEJP = "EJP" ;
	else		sEJP = "";

	var timeStart = timeCurrent();
	
	if G_bINSTRYT trace_function("func createBlocsEJPELNET_NEW init",D_TRACE_START); ////////////////////////////////////////

	// --- YTR 23/02/2011 :on charge une pmap jrpinfoEJP dans $ELA_DATA/prodmaps
	var pmapname = "jrpinfoEJP" ;
	var pmapfilepath = format("%1%2prodmaps%2pmaps%2%3",env("ELA_DATA"),SEP, pmapname);
	cout << "Chargement PMap("+ pmapfilepath +"," + pmapname + ")..."; flush(cout);
	
	var pmapjrpEJP = getPMap(pmapfilepath,pmapname) ;
	cout << "Ok\n";
	if pmapjrpEJP != nothing {			

		pmapCount =  pmapjrpEJP.pmCount() ;
		cout << format("Ouverture de la pmap %1 effectué avec succès, il y a %2 enregistrements\n", pmapname, pmapCount);

		// --- pour permettre la création des blocs, il faut générer une liste ordonnée des identifiants à récupérer dans la pmap
		// --- pour cela, on va commencer à générer une map "allégée" contenant uniquement les id et une chaîne permettant de trier

		cout << format("Analyse de la map en cours pour déterminer les critères de tri : 00%%"); flush(cout);
		G_maptxtjrp = Map();
		pmapReadCpt = 0 ;
		var precPourcent = 0;
		var anneePrec="00", moisPrec = "00", jourPrec="00";	// --- annee/mois/jour de l'element précédemment vu
		for key, value in pmapjrpEJP {
			pmapval = Object(value);
			/*// ajouté pour prévoir des erreur de saisie !
			while pmapval.annee.length() < 4
				pmapval.annee = "0" + pmapval.annee;
			while pmapval.mois.length() < 2
				pmapval.mois = "0" + pmapval.mois;
			while pmapval.jour.length() < 2
				pmapval.jour = "0" + pmapval.jour;
			////////////////////////////////////////*/
			crit = pmapval.annee+pmapval.mois+pmapval.jour ;
			sTypeTxtJrp = "" ;
			switch( G_sSourceType ) {
			case "txt" : sTypeTxtJrp = pmapval.typeDeDocument ; break;
			case "jrp" : sTypeTxtJrp = pmapval.type ; break;
			}
			if G_mapNSWeight.knows(sTypeTxtJrp)	crit << G_mapNSWeight[sTypeTxtJrp];
			else					crit << "99" ;

			switch( G_sSourceType ) {
			case "txt" : crit << trimBoth(pmapval.contentHDG_HDLDO," ") + key ; break;
			case "jrp" : crit << pmapval.juridic1 + pmapval.juridic2 + key ; break;
			}
			G_maptxtjrp[key] = crit ;
			var pourcent = 100*pmapReadCpt/pmapCount;
			if (++pmapReadCpt % 100 == 0) && (pourcent >= precPourcent +5) { cout << format("%1$02d%%",100*pmapReadCpt/pmapCount); precPourcent = pourcent; flush(cout); }
		}
		cout << format("100%%\n");

		if G_bINSTRYT trace_function("func createBlocsEJPELNET_NEW esort pmap",D_TRACE_START); ////////////////////////////////////////
		cout << format("Création de la liste triée des id EJP..."); flush(cout);
		lstEJPpmapSortedKeys = eSort(G_maptxtjrp, function(i) { return G_maptxtjrp[i]; });
		cout << format("Ok (la liste contient %1 ids)\n",lstEJPpmapSortedKeys.length());
		G_maptxtjrp = nothing ;
		if G_bINSTRYT trace_function("func createBlocsEJPELNET_NEW esort pmap",D_TRACE_END); ////////////////////////////////////////
	}
	else {
		cout << format("\n\nERREUR FATALE : impossible d'ouvrir la pmap %1 avec le chemin %2\n\n", pmapname, pmapfilepath);
	}

	if G_bINSTRYT trace_function("func createBlocsEJPELNET_NEW init",D_TRACE_END); ////////////////////////////////////////


	// --- définition de l'intervalle d'années qu'il faut traiter (en fonction des éventuels paramètres passés en ligne de commande)
	if sYearBegin != ""	{ nYearBegin = dec(sYearBegin) ; if !isaNumber(nYearBegin) nYearBegin=0; }
	else			nYearBegin = 0 ;

	if sYearEnd != ""	{ nYearEnd = dec(sYearEnd) ; if !isaNumber(nYearEnd) nYearEnd=999999; }
	else			nYearEnd = 999999 ;

	// MB : modif 11/08/2011
	//====================================================================================================
	// 1ère PASSE pour version incrémentale : 
	//				  1. créer un map des blocs qui devront exister avec leur date : mapAllExistingBlocsDates
	//				  2. créer une liste des blocs à (re)construire :  
	//				  3. nettoie les blocs caducs : absents de setAllNewJrpBlocs
	//====================================================================================================
	
	cout << format("\nInventaire blocs existants...");
	if G_bINSTRYT trace_function("func getSetAllExistingBlocs",D_TRACE_START); ////////////////////////////////////////
	// 1. créer un Set des blocs existants (pour version incrémentale)
	getSetAllExistingBlocs(filePath(env("ELA_DATA"),"jrpblocsEJP"));
	//getSetAllExistingBlocs("/mac.public/mbaziz/documents/optimise_makeblocs/data/res/jrp");
	if G_bINSTRYT trace_function("func getSetAllExistingBlocs",D_TRACE_END); ////////////////////////////////////////
	// le résultat de type bloc<->date est ds : mapAllExistingBlocs
	
	// 2. créer un set des blocs qui devront exister + une liste des blocs à (re)construire
	// trop long ==> mettre ds une fct
	cout << format("Analyse des blocs...");
	if G_bINSTRYT trace_function("func getSetAllNewJrpBlocs",D_TRACE_START); ////////////////////////////////////////
	getSetAllNewJrpBlocs(lstEJPpmapSortedKeys,sSourcedir,pmapjrpEJP,nYearBegin,nYearEnd,sBlocfileRoot);
	if G_bINSTRYT trace_function("func getSetAllNewJrpBlocs",D_TRACE_END); ////////////////////////////////////////
	
	// 3. nettoyage des blocs qui ne doivent plus exister ou qui sont à remplacer
	nettoyerBlocsCaducs(sBlocfileRoot);
	
	if (listUpdateBlocs.length() > 0)	cout << format("Création des nouveaux blocs :");
	
	//====================================================================================================
	// 2ème PASSE : 
	//				1. ignorer ttes les jrps qui ne se trouvent pas ds un bloc à (re)construire 	
	//				   anneemoisjour ds intervalle d'un bloc à (re)construire
	//				2. ancien traitement pour le reste 
	//====================================================================================================
	
	anneecrt = "";	     // pour gestion par bloc annee = année de début du bloc entamé
	moiscrt = "" ;       // pour gestion par bloc annee+mois = mois de début du bloc entamé
	jourcrt = "";	     // pour gestion par bloc annee+mois+jour = jour de début du bloc entamé
	sInsertBlocMois = "" ;
	nbTotSrcIncluded = 0 ;
	var blocEnCours=false;
	var nbjrpconstruites = 0, nbblocsconstruits = 0;
	// ---- PRISE EN COMPTE DATE PRECEDENTE
	var anneePrec="00", moisPrec = "00", jourPrec="00";	// --- annee/mois/jour de l'element précédemment vu
	var totalToCreate = nbRebuild + nbNew;
	if G_bINSTRYT trace_function("func createBlocsEJPELNET_NEW boucle",D_TRACE_START); ////////////////////////////////////////
	// --- on boucle sur la liste contenant les id de jrp EJP, déjà triés dans l'ordre souhaité
	for idtxtjrp in lstEJPpmapSortedKeys {
		pmapval = Object(pmapjrpEJP.pmGet(idtxtjrp));
		nYearCrt = dec(pmapval.annee);
		if nYearCrt < nYearBegin || nYearCrt > nYearEnd {
			continue ;
		}
		
		// MB 10/08/2011 : ajouté pour ignorer les dates abbérantes ==> pour ne pas perturber le nouvel algo....
		if nYearCrt < 1000 || nYearCrt > 2099 {	
			continue ;
		}

		//======================================================================================================
		//			1. ignorer ttes les jrps qui ne se trouvent pas ds un bloc à (re)construire
		if jrpDansBlocAconstruire(pmapval.annee,pmapval.mois,pmapval.jour) == nothing {
			//cout << format("\t--> JRP idtxtjrp ignorée !\n");
			continue;
		}
		//======================================================================================================
		++nbjrpconstruites;
		
		//======================================================================================================
		//			2. ancien traitement pour le reste des jrps
		//======================================================================================================
		
		// --- creation le cas échéant d'un nouveau bloc
		if (G_sBlocrule=="day" && (bCreateFirstBloc || creationNouveauBloc(pmapval, anneecrt, moiscrt, jourcrt, anneePrec, moisPrec, jourPrec, nbSrcIncluded, taillebloc,1))) { 

			if blocEnCours {

				// --- fermeture de l'element racine :
				fbloc << format("</%1>\n",sRootTag) ;
				close(fbloc);
				blocEnCours = false;

				// RENOMMAGE
				var sBlocnameNew = format("%s-%s%s%s", sBlocname, anneePrec, moisPrec, jourPrec);
				var sBlocfilenameNew = format("%1%2.optj.sgm",sBlocfileRoot,sBlocnameNew);
				if not fileRename(sBlocfilename, sBlocfilenameNew) {
					cout << "Erreur : impossible de renommer " + sBlocfilename + " --> " + sBlocfilenameNew + "\n";
					exit(77);
				}
				
				// 26/02/2014 MB : suite pb prod makeblocs_v2.bal ajout test fileAccess(sBlocfilename)
				if nbSrcIncluded == 0 { if fileAccess(sBlocfilename) {
						fileRemove(sBlocfilename); cout << format("\nfichier %1 supprimé car vide!", sBlocfilename);
					} 
				}
				//else cout << format("\n\tcréation bloc %1\n", sBlocfilename, sBlocfilenameNew);
				cout << format("\t     %1$05d sources intégrées avec succès", nbSrcIncluded);
			}

			bCreateFirstBloc = false ; // ca ne sert que la premiere fois pour arriver ici sur la premiere jrp... RIP :-)

			// --- Repositionner les dates pour le prochain bloc
			anneecrt = pmapval.annee;
			moiscrt = pmapval.mois;
			jourcrt = pmapval.jour;	
			
			// CREATION NOUVEAU BLOC
			++nbblocsconstruits;
			sBlocname = format("%s%s%s", anneecrt, moiscrt, jourcrt);
			sBlocfilename = format("%1%2-aaaammjj.optj.sgm.tmp",sBlocfileRoot,sBlocname);
			cout << format("\n\t[cpt jrps = %1\] Intégration de sources dans le bloc n°%2/%3 %4 : 00000",nbjrpconstruites,nbblocsconstruits,totalToCreate, fileBaseName(sBlocfilename));
			//cout << format("");
			fbloc = FileStream(sBlocfilename,"w");
			if fbloc==nothing || not isaStream(fbloc) { error format("Impossible de creer %1",sBlocfilename); return CANNOT_CREATE_BLOC; }
			// RAZ du compteur de sources et de la taille du bloc de sources
			nbSrcIncluded = 0 ;
			taillebloc = 0 ;
			blocEnCours = true;
			// Choix et ouverture de l'element racine :
			switch(G_sSourceType) {
			case "txt" : sRootTag = "TXTBLOC-OPTJ" ; sRootID = format("%1TXTBLOC%2",G_zdp,sBlocname.transcript(UpperCase)); 
				if G_bANTmode  sRootID = format("%1TXTANTBLOC%2",G_zdp,sBlocname.transcript(UpperCase));
				break;
			case "jrp" : sRootTag = "DECISBLOC-OPTJ" ; sRootID = format("%1%3DECISBLOC%2",G_zdp,sBlocname.transcript(UpperCase),sEJP); break;
			}						
			fbloc << format("<%1 MATIERE=\"ELNET\" ID=\"%2\">",sRootTag,sRootID) ;		


		}

		sIdref = idtxtjrp ;
		
		// LECTURE DU SOURCE A INTEGRER DANS LE BLOC COURANT

		//======================================================================================================
		//			modif MB : 05/08/2011 --> appel fct splitpath balise (+ rapide, voir doc synthèse)
		//======================================================================================================
		
		// Appel a la nouvelle fct Balise splitpath
		var sSplitFileName = "" ;
		if G_bINSTRYT trace_function("func splitpath_v2 balise",D_TRACE_START);
		sSplitFileName = splitPath_v2(format("%1.optj.sgm", sIdref.explode(".")[0] ),1);
		if G_bINSTRYT trace_function("func splitpath_v2 balise",D_TRACE_END);
		//
		

		if G_bINSTRYT trace_function("func createBlocsEJPELNET_NEW lecture+ecriture",D_TRACE_START); ////////////////////////////////////////

		sSourcefilename = format("%1%2", sSourcedir, trimRight(sSplitFileName,"\n"));
		//cout << format("\nsSourcedir=%s\nsSourcefilename = %s", sSourcedir, sSourcefilename);
		
		fsrc = FileStream(sSourcefilename,"r");
		if fsrc==nothing {
			error format("impossible d'acceder a %1",sSourcefilename);
			ErrorLimit++;
			lstSrcNotIncluded << sIdref ;
			continue;
		}
		else if isaStream(fsrc) {
			// On cree un bloc uniquement s'il y a des textes qu'il faut conserver dedans...
			if isaStream(fbloc) fbloc << readAll(fsrc);
			nbSrcIncluded++;
			if G_bINSTRYT trace_function("func createBlocsEJPELNET_NEW fileSize(sSourcefilename)",D_TRACE_START); ////////////////////////////////////////
			taillebloc += fileSize(sSourcefilename);
			if G_bINSTRYT trace_function("func createBlocsEJPELNET_NEW fileSize(sSourcefilename)",D_TRACE_END); ////////////////////////////////////////
			nbTotSrcIncluded++;
			//cout << format("%1 ",sIdref);
			if ( nbSrcIncluded % 100 == 0 ) {
				cout << format("%1$05d",nbSrcIncluded); flush(cout);
			}
			close(fsrc);
		}
		else {
			cout << format("Erreur ! dans stream pour fichier %1",sBlocfilename);
		}

		if G_bINSTRYT trace_function("func createBlocsEJPELNET_NEW lecture+ecriture",D_TRACE_END); ////////////////////////////////////////

		anneePrec=pmapval.annee;
		moisPrec=pmapval.mois;
		jourPrec=pmapval.jour;
	}		
	// TRAITEMENT DU DERNIER BLOC
	if isaStream(fbloc) {
		
		fbloc << format("</%1>\n",sRootTag) ;	// Fermeture de l'element racine
		close(fbloc);
		// RENOMMAGE
		var sBlocnameNew = format("%s-%s%s%s", sBlocname, anneePrec, moisPrec, jourPrec);
		var sBlocfilenameNew = format("%1%2.optj.sgm",sBlocfileRoot,sBlocnameNew);
		if not fileRename(sBlocfilename, sBlocfilenameNew) {
			cout << "Erreur : impossible de renommer " + sBlocfilename + " --> " + sBlocfilenameNew + "\n";
			exit(77);
		}

		if nbSrcIncluded == 0 {if fileAccess(sBlocfilename) fileRemove(sBlocfilename);}
		cout << format("\t     %1$05d sources intégrées avec succès", nbSrcIncluded);
	}		
	closePMapStorage(pmapjrpEJP);				// --- ne pas oublier de fermer la pmap EJP !
	
	if (listUpdateBlocs.length() > 0)	cout << format("\nFin création des blocs EJP : en ");
	cout << format(" %s min \n", timeDiff(timeCurrent(), timeStart)/60);
	cout << format("\n\nFin de la création : %1 sources intégrées", nbTotSrcIncluded );		
	// AFFICHAGE DES FICHIERS CADUCS MAIS REFERENCES DANS LA MAP
	if (nbTotSrcIncluded > lstEJPpmapSortedKeys.length())  {
		//cout << format("\n\nFin de la création : %1 sources intégrées", nbTotSrcIncluded );
		cout << format("\nATTENTION : %1 sources non déclarés dans la pmap ! Ces sources ne sont pas référencées dans la pmapjrpEJP alors qu'elles existent toujours dans le dossier traité.\n", nbTotSrcIncluded - lstEJPpmapSortedKeys.length());

	}

	// AFFICHAGE DES FICHIERS DANS LA MAP MAIS QUI N'EXISTENT PLUS
	if (lstSrcNotIncluded.length()>0) {
		//cout << format("\n\nFin de la création : %1 sources intégrées", nbTotSrcIncluded );
		cout << format("\nATTENTION : %1 sources non trouvées ! (Ces sources sont référencées dans les maptxt/mapjrp alors qu'ils n'existent plus : il y a du ménage à faire semble-t-il...)\n", lstSrcNotIncluded.length());
		for id in lstSrcNotIncluded {
			cout << format("%1 ",id);
		}
	}

	
	if G_bINSTRYT trace_function("func createBlocsEJPELNET_NEW boucle",D_TRACE_END); ////////////////////////////////////////
	if G_bINSTRYT cout << format("\n%1\n", trace_getAllFunctionStats());	
}

// YE 11/01/2014 Mantis 4380
// Cette fonction permet de verifier si le txt est a traiter ou pas
// Si le txt est a traiter alors le rajouter dans le set G_setIdTxtToBuild

//var dirtxt = "/usr/local/ela/cd-rom/elnet/data/sgml/txt/optj/";		
// var dateLancementDir = format("%1/dateLancement/",G_ela_liv);
// var referenceDatefile = dateLancementDir+"hulkliv.txt";
function txtToBuild(dirtxt,referenceDatefile){	
	var alltxtFiles = eSort(fileReadDir(dirtxt,true));  
	var referencefiledate = "";
	var txtfiledate = "";	
	var idTxtToAdd = "";
	if !fileAccess(G_txtToBuildFile){
		//G_txtToBuildFile = FileStream(G_txtToBuildFile,"w");		
		G_setIdtxtToBuild = Set();
		setObjectInFile(G_txtToBuildFile, G_setIdtxtToBuild);   
	}				
	G_setIdtxtToBuild = Set();//= loadObjectFromFile(G_txtToBuildFile);	
	//cout << format("\nLe set setExoticjrpFile avant traitement = '%1'\n ",G_setIdtxtToBuild.length());
	
	if alltxtFiles != nothing {				
		for file in alltxtFiles {	
			if file.search(0,RegExp(".optj.sgm$")) > 0{			
				txtfiledate = timeFormat(fileDate(file), "%d/%m/%Y %H:%M:%S");
				if G_bRefDateTxtDepuis == true {	// Le traitement a partir d'une date predefinie par l'utilisateur						
					if compareDate(G_refDateTxtDepuis,txtfiledate) == "supp" || compareDate(G_refDateTxtDepuis,txtfiledate) == "equal" {
						idTxtToAdd = fileBaseName(file).replace(0,".optj.sgm","").transcript(UpperCase);
						if !G_setIdtxtToBuild.knows(idTxtToAdd) G_setIdtxtToBuild << fileBaseName(file).replace(0,".optj.sgm","").transcript(UpperCase);	
					}				
				}else{	// Si la date n'est pas specifier on recupere celle de la derniere hulkliv				
					
					//referenceDatefile = dateLancementDir +"hulkliv.txt";						
					if fileSize(referenceDatefile) > 0 referencefiledate =  readAll(FileStream(referenceDatefile, "r")).explode("\n")[0];	
					
					else {
						cout << format("ERROR : Attention le fichier %1 introuvable\n",referenceDatefile);
						referencefiledate = timeFormat(timeCurrent(), "%d/%m/%Y %H:%M:%S ");
					}
					
					if compareDate(referencefiledate,txtfiledate) == "supp" || compareDate(referencefiledate,txtfiledate) == "equal" {							
						idTxtToAdd = fileBaseName(file).replace(0,".optj.sgm","").transcript(UpperCase);
						//cout << format("Le set %2, idTxtToAdd :%1\n",idTxtToAdd,G_setIdtxtToBuild);
						if !G_setIdtxtToBuild.knows(idTxtToAdd) G_setIdtxtToBuild << fileBaseName(file).replace(0,".optj.sgm","").transcript(UpperCase);
						
					}		
				}	
			}			
		}
	}
	
	// initialiser le Set HulkTxtToBuild
	setObjectInFile(G_txtToBuildFile, G_setIdtxtToBuild);    
}

function get_map_id_logique_jrp_dalloz(){
	// cette fonction charge les deux map de correspondance iddpm / id logique jrp dalloz
	// elle retourne une map qui contient la somme des deux autres
	
	// /usr/local/ela/tmp-idx/jrp_id_el_id_logique_dz_depuis_br.map
	// /usr/local/ela/tmp-idx/jrp_id_el_id_logique_dz_depuis_jrpinfo.map
	// cout << "debug function get_map_id_logique_jrp_dalloz\n";
	var map = Map();

	// 1. on initalise avec la map issue de jrpinfo
	var map_jrp_id_el_id_logique_dz_depuis_jrpinfo = loadObjectFromFile("/usr/local/ela/tmp-idx/jrp_id_el_id_logique_dz_depuis_jrpinfo.map");
	if isaMap(map_jrp_id_el_id_logique_dz_depuis_jrpinfo){
		for cle,set in map_jrp_id_el_id_logique_dz_depuis_jrpinfo{
			// cle_upper_case = cle.transcript(UpperCase);
			// if !map.knows(cle_upper_case) map[cle_upper_case] = set;
			// on tri le Set pour garder uniquement la premiere valeur
			map[cle.transcript(UpperCase)] = eSort(set)[0];
		}
	}

	// on vide les variables map pour economiser de la memoire
	// cout << format("debug function get_map_id_logique_jrp_dalloz map_jrp_id_el_id_logique_dz_depuis_jrpinfo contient %1 cles\n",map_jrp_id_el_id_logique_dz_depuis_jrpinfo.length());
	map_jrp_id_el_id_logique_dz_depuis_jrpinfo = nothing;

	// 2. les informaions de la br sont prioritaires sur celles de jrpinfo
	// on ecrase et on complete avec la map issue de la br
	var map_jrp_id_el_id_logique_dz_depuis_br = loadObjectFromFile("/usr/local/ela/tmp-idx/jrp_id_el_id_logique_dz_depuis_br.map");
	
	// var cle_upper_case = nothing;
	if isaMap(map_jrp_id_el_id_logique_dz_depuis_br){
		for cle,set in map_jrp_id_el_id_logique_dz_depuis_br{
			map[cle.transcript(UpperCase)] = eSort(set)[0];
		}
	}
	
	// cout << format("debug function get_map_id_logique_jrp_dalloz map_jrp_id_el_id_logique_dz_depuis_br contient %1 cles\n",map_jrp_id_el_id_logique_dz_depuis_br.length());
	map_jrp_id_el_id_logique_dz_depuis_br = nothing;
	
	// 4. on retourne la map fusionnee
	// cout << format("debug function get_map_id_logique_jrp_dalloz map contient %1 cles\n",map.length());
	return map;
}


// YE 23/05/2014 Mantis 7336
// Cette fonction permet de verifier si la jrp est a traiter ou pas
// Si la jrp est a traiter alors la rajoutee dans le set G_setIdTxtToBuild

function getSetjrpToBuild(dirjrp,referenceDatefile){	
	var alljrpFiles = eSort(fileReadDir(dirjrp,true));  
	var referencefiledate = "";
	var jrpfiledate = "";	
	var idJrpToAdd = "";		
	var map_id_logique_jrp_dalloz = nothing ;	
	map_id_logique_jrp_dalloz = get_map_id_logique_jrp_dalloz();
	
	var setIdjrpToBuild = Set();//= loadObjectFromFile(G_jrpToBuildFile);	
	//cout << format("\nLe set setExoticjrpFile avant traitement = '%1'\n ",setIdjrpToBuild.length());
	
	if alljrpFiles != nothing {				
		for file in alljrpFiles {	
			if file.search(0,RegExp(".optj.sgm$")) > 0{			
				jrpfiledate = timeFormat(fileDate(file), "%d/%m/%Y %H:%M:%S");
				if G_bRefDateJrpDepuis == true {	// Le traitement a partir d'une date predefinie par l'utilisateur
					if compareDate(G_refDateJrpDepuis,jrpfiledate) == "supp" || compareDate(G_refDateJrpDepuis,jrpfiledate) == "equal" {
						idJrpToAdd = fileBaseName(file).replace(0,".optj.sgm","").transcript(UpperCase);
						// On ne traite que les JRP EL
						if !setIdjrpToBuild.knows(idJrpToAdd) && !map_id_logique_jrp_dalloz.knows(idJrpToAdd){
							setIdjrpToBuild << fileBaseName(file).replace(0,".optj.sgm","").transcript(UpperCase);
							if idJrpToAdd.rsearch(0,"^COURD") > 0 G_setEJPV2NonLivreDl << idJrpToAdd;
						}
					}				
				}else{	// Si la date n'est pas specifier on recupere celle du dernier hulkliv				
					
					//referenceDatefile = dateLancementDir +"hulkliv.txt";						
					if fileSize(referenceDatefile) > 0 referencefiledate =  readAll(FileStream(referenceDatefile, "r")).explode("\n")[0];	
					
					else {
						cout << format("ERROR : Attention le fichier %1 introuvable\n",referenceDatefile);
						referencefiledate = timeFormat(timeCurrent(), "%d/%m/%Y %H:%M:%S ");
					}
					
					if compareDate(referencefiledate,jrpfiledate) == "supp" || compareDate(referencefiledate,jrpfiledate) == "equal" {							
						idJrpToAdd = fileBaseName(file).replace(0,".optj.sgm","").transcript(UpperCase);
						
						if !setIdjrpToBuild.knows(idJrpToAdd) && !map_id_logique_jrp_dalloz.knows(idJrpToAdd){
							setIdjrpToBuild << fileBaseName(file).replace(0,".optj.sgm","").transcript(UpperCase);
							if idJrpToAdd.rsearch(0,"^COURD") >0  G_setEJPV2NonLivreDl << idJrpToAdd;
						}
					}		
				}	
			}			
		}
		
		
		if G_setEJPV2NonLivreDl.length() >0 {				
			
			G_tracefile << format("le nombre total D'EJP V2 non livres par Dalloz  = '%1'\n\n",G_setEJPV2NonLivreDl.length());
			for elem in eSort(G_setEJPV2NonLivreDl) {		
				G_tracefile << format("\t%1  \n",elem);		
			}			
			setObjectInFile(G_EJPV2NonLivreDl, G_setEJPV2NonLivreDl);  
			var maildest = "alazreg cchareau";
			var sujet = "mail auto : Hulk makeblocs EJP Non livrees par Dalloz : ";
			
			system(format("/usr/local/ela/bin/sendmaildpm %1 -s %2 -c \" %4 EJP V2 détectées comme non livrées par Dalloz. \n Consulter le fichier de log \"%3\" pour plus de précision\" ",maildest,sujet,G_traceDirOutName,G_setEJPV2NonLivreDl.length()));
			
		}
	}
	// cout << format("Le nombre de jrp a traiter est  = '%1'\n\n",setIdjrpToBuild.length());		
	// Retourner le set des Jrp a traiter 
	return setIdjrpToBuild;
	
}


/*--------------------------------------------------------------------
main : au travail :-)
--------------------------------------------------------------------*/
main {
	
	var msg, sRappelParam, sIdxfile, sBlocdir, sSourcedir, sBlocfileRoot, docParseResult, doc ;
	var eladata, eladatacomm, eladico, eladec, eladtd ;
	var sDtdfile ;

	
	// --- controle du bon positionnement de l'environnement
	eladata = env("ELA_DATA");
	//eladatacomm = "/usr/local/ela/cd-rom/datacomm/";
	eladatacomm = 	env("ELA_DATACOMM");
	eladico = env("ELA_DICO");
	eladec = env("ELA_DEC");
	eladtd = env("ELA_DTD");
	if eladico == nothing || eladata == nothing || eladec == nothing || eladtd == nothing {
		cout << format("*** variables d'environnement non positionnees\n\n");
		abort(ENVIRONMENT_NOT_LOADED);	
	}
	switch(eladico) {
	case "docg":	
	case "elnet":	G_zdp = eladico.transcript(UpperCase); break;
		default :	G_zdp = getDicoID(eladico).transcript(UpperCase);
	}

	// --- recuperation de la ligne de commande ---
	handleCommandLine() ;

	if env("DEBUGYTTESTVERSIONNING") == "ON" G_bANTmode = true ;

	// --- initialisations diverses
	ErrorLimit=10000;
	sDtdfile = format("%1%2idx-optj.dtd",eladtd,SEP);
	if eladico != "elnet"	sIdxfile = format("%1%2idx%3%2optj%2%4_ind%3.optj.sgm",eladata,SEP,G_sSourceType,eladico);
	else			sIdxfile = "N/A" ;

	// Modif du 0-12-2003 --> Ahmed
	// Dans le cas du dp15 parser le fichier comjrp.optj.sgm
	// Le fichier dp15_indjrp.optj.sgm n'existe pas
	//
	if eladico == "dp15"{
		sDtdfile = format("%1%2comjrp-optj.dtd",eladtd,SEP);
		sIdxfile = format("%1%2comjrp%2optj%2comjrp.optj.sgm",eladata,SEP);
	}

	//Mantis 4380
	// Dans le cas des TXT pour hulk 
	if G_sSourceType == "txtblochulk" {	 
		var G_ela_liv = env("ELA_LIV");
		var dirtxt = env("ELA_DATACOMM")+"/txt/optj/";
		var dateLancementDir = format("%1/dateLancement/",env("ELA_LIV"));
		var referenceDatefile = dateLancementDir+"hulkliv.txt";
		txtToBuild(dirtxt,referenceDatefile);	
	}
	
	// 18/09/2014 sfouzi
	// Dans le cas du traitement unitaire des TXT
	if G_sSourceType == "addtxtfiles" {
		G_dirAddTxtFiles = G_dirAddTxtFiles + "/";
		G_dirAddTxtFiles = G_dirAddTxtFiles.replace(0,"//","/");
		var alltxtFiles = eSort(fileReadDir(G_dirAddTxtFiles,true));
		var idTxtToAdd = "";
		G_setIdtxtToBuild = Set();
		if !fileAccess(G_txtToBuildFile)
		setObjectInFile(G_txtToBuildFile, G_setIdtxtToBuild);   
		
		if alltxtFiles == nothing {
			cout << format("aucun fichier a traiter\n\n");
			abort(CANNOT_LOAD_SGML_DOCUMENT);
		}
		for file in alltxtFiles {
			if file.search(0,RegExp(".optj.sgm$")) > 0 {
				
				idTxtToAdd = fileBaseName(file).replace(0,".optj.sgm","").transcript(UpperCase);
				cout << format("debugsf idTxtToAdd = %1\n", idTxtToAdd);
				if !G_setIdtxtToBuild.knows(idTxtToAdd) G_setIdtxtToBuild << idTxtToAdd;
			}
		}
		setObjectInFile(G_txtToBuildFile, G_setIdtxtToBuild); 
	}
	
	// 24/05/2017 alazreg Dans le cas du traitement unitaire des JRP
	if G_sSourceType == "addjrpfiles" {
		G_dirAddJrpFiles = G_dirAddJrpFiles + "/";
		G_dirAddJrpFiles = G_dirAddJrpFiles.replace(0,"//","/");
		var alljrpFiles = eSort(fileReadDir(G_dirAddJrpFiles,true));
		var idJrpToAdd = "";
		G_setIdjrpToBuild = Set();
		if !fileAccess(G_jrpToBuildFile)
		setObjectInFile(G_jrpToBuildFile, G_setIdjrpToBuild);   
		
		if alljrpFiles == nothing {
			cout << format("aucun fichier a traiter\n\n");
			abort(CANNOT_LOAD_SGML_DOCUMENT);
		}
		for file in alljrpFiles {
			if file.search(0,RegExp(".optj.sgm$")) > 0 {
				
				idJrpToAdd = fileBaseName(file).replace(0,".optj.sgm","").transcript(UpperCase);
				// cout << format("debugsf idJrpToAdd = %1\n", idJrpToAdd);
				if !G_setIdjrpToBuild.knows(idJrpToAdd) G_setIdjrpToBuild << idJrpToAdd;
			}
		}
		setObjectInFile(G_jrpToBuildFile, G_setIdjrpToBuild); 
	}
	
	if !G_bEJPmode and !G_bANTmode{

		sBlocdir = format("%1%2%3blocs%2", eladata,SEP,G_sSourceType);
		// 17/09/2012 MB : si option jrpexotic ==> livrer dans le ela_liv de hulk
		
		sSourcedir = format("%1%2%3%2optj%2", eladata, SEP,"jrp" /*G_sSourceType*/);

		sBlocfileRoot = format("%1%2_%3bloc_",sBlocdir,eladico,G_sSourceType);
		G_sErrorFileName = format("%1%2",sBlocdir,DEFAULT_ERROR_FILENAME) ;
		
		// YE 12/02/2014 Hulk Mantis 4380 
		// Dans le but de traiter les txt en fonction de la date de maj
		// stocker les blocs dans le dossier $ELA_LIV/txtblochulk
		if G_sSourceType == "txtblochulk" {
			//sBlocdir = format("%1", "/mac.public/yendichi/sgm/txtblochulk/",SEP,G_sSourceType);
			sBlocdir = format("%1/%2/",env("ELA_LIV"),G_sSourceType);
			system("mkdir -p "+sBlocdir);
			sBlocfileRoot = format("%1elnet_txtbloc_",sBlocdir);
			sSourcedir = format("%1/txt/optj/", eladata);
			//cout << format("*******************************************************************\n");
			// cout << format("debug Je suis dans le cas de txtblochulk sSourcedir=%1\n",sSourcedir);
			// cout << format("debug Je suis dans le cas de txtblochulk sBlocfileRoot=%1\n",sBlocfileRoot);
		}	
		
		//YE 23/05/2014
		// Mantis 7336
		if G_sSourceType == "jrpblochulk" {	 
			// YE 23/05/2014 Debug 
			// sBlocdir = format("%1", "/mac.public/yendichi/sgm/jrpblochulk/",SEP,G_sSourceType);
			sBlocdir = format("%1%2%3%2", env("ELA_LIV"),SEP,G_sSourceType);			
			sBlocfileRoot = format("%1%2_%3bloc_",sBlocdir,"elnet","jrp");
			sSourcedir = format("%1%2%3%2optj%2", eladata, SEP,"jrp" /*G_sSourceType*/);
			
		}	
		
		// 18/09/2014 sfouzi
		if G_sSourceType == "addtxtfiles" {
			sBlocdir = format("%1%2%3%2", env("ELA_LIV"),SEP,G_sSourceType);
			sBlocfileRoot = format("%1%2_%3bloc_",sBlocdir,"elnet","txt");
			sSourcedir = G_dirAddTxtFiles;
		}
		
		// 24/05/2017 alazreg
		if G_sSourceType == "addjrpfiles" {
			sBlocdir = format("%1%2%3%2", env("ELA_LIV"),SEP,G_sSourceType);
			sBlocfileRoot = format("%1%2_%3bloc_",sBlocdir,"elnet","jrp");
			sSourcedir = G_dirAddJrpFiles;
		}		
	}
	// --- MJE 22/11/2010 Si on est en "mode ANT", on stocke les blocs spécifiques ANT ailleurs
	else if G_bANTmode {
		// YE 21/05/2014	Debug
		sBlocdir = format("%1%2%3blocsANT%2", eladata,SEP,G_sSourceType);
		
		// sBlocdir = format("%1", "/mac.public/yendichi/sgm/txtblochulk",SEP,G_sSourceType);		
		//sSourcedir = format("%1%2%3%2optj%2", eladata, SEP, G_sSourceType);
		sSourcedir = format("%1/%2/versionning/optj/",env("ELA_DATACOMM"), G_sSourceType);

		sBlocfileRoot = format("%1%2_%3antbloc_",sBlocdir,eladico,G_sSourceType);
		G_sErrorFileName = format("%1%2",sBlocdir,DEFAULT_ERROR_FILENAME) ;
	}

	// --- Si on est en "mode EJP", on stocke les blocs spécifiques EJP ailleurs
	else {
		
		G_sEJPlivRoot = format("%1/jrp/ejp/sgmoptjfull",env("ELA_DATACOMM")) ;

		sBlocdir = format("%1%2%3blocsEJP%2", eladata,SEP,G_sSourceType);
		sSourcedir = G_sEJPlivRoot;

		sBlocfileRoot = format("%1%2_%3blocEJP_",sBlocdir,eladico,G_sSourceType);
		G_sErrorFileName = format("%1%2",sBlocdir,DEFAULT_ERROR_FILENAME) ;
	}

	// --- si on ne peut pas acceder au fichier index, on braille!
	if eladico!="elnet" && !fileAccess(sIdxfile,"r") {
		cout << format("*** impossible de lire %1\n\n",sIdxfile);
		abort(CANNOT_LOAD_SGML_DOCUMENT);
	}


	// --- si le dossier de sortie n'existe pas, on le cree
	cout << format("debug sBlocdir = '%1'\n",sBlocdir);
	if !fileAccess(sBlocdir,"w") {
		cout << format("debug if not fileAccess sBlocdir w = '%1'\n",sBlocdir);
		if !makeDir(sBlocdir) {
			msg = format("*** echec creation dossier %1\n\n",sBlocdir);
			cout << msg ;
			G_sErrors << msg;
			abort(CANNOT_CREATE_DIROUT);
		}
	}
	
	// YE Le 03/06/2014
	
	var pathtrace = filePath(env("ELA_LIV"),"jrpblochulk/log"); 
	if pathtrace != "" {
		system("mkdir -p "+pathtrace);
		if !fileAccess(pathtrace,"w") {
			if !makeDir(pathtrace) {		
				cout << format("*** echec creation dossier %1\n\n",G_traceDirOutName);		
				abort(2);
			}
		}
	} 
	// G_traceDirOutName = filePath(pathtrace,"makeblocs_v2.log");
	// G_traceDirOutName = filePath(pathtrace,format("makeblocs_%1.log.txt",timeFormat(timeCurrent(),"%d%m%Y_%H%M%S")));
	G_traceDirOutName = filePath(pathtrace,format("makeblocs_%1.log.txt",timeFormat(timeCurrent(),"%Y%m%d_%H%M%S")));
	cout << format("debug G_traceDirOutName='%1'\n",G_traceDirOutName);
	G_tracefile = FileStream(G_traceDirOutName,"w");  


	// --- entete traces ecran
	msg = "" ;
	msg << LINESEPARATOR ;
	msg << format("%1 V%2 - %3\n",PROGNAME,CODEVERSION,CODEDATE) ;
	msg << format("Date execution : %1\n", timeFormat(timeCurrent(),"%A %d/%m/%Y %H:%M:%S\n")) ;
	msg << format("fichier d'erreur : %1"+LINESEPARATOR,G_sErrorFileName);
	sRappelParam = "" ;
	sRappelParam << format("type de source : %1\n",G_sSourceType);
	sRappelParam << format("regles de creation de blocs : %1\n",G_sBlocrule);
	msg << sRappelParam + "\n" ;
	msg << format("fichier index exploite : %1\n",sIdxfile);
	msg << format("fichier sources exploites : %1*.optj.sgm\n",sSourcedir);
	msg << format("fichiers blocs crees : %1*.optj.sgm",sBlocfileRoot);
	
	msg << LINESEPARATOR ;

	G_tracefile << msg;
	cout << msg ;

	//  mb : pour ne pas toucher à la prod
	G_bINSTRYT = true;
	if env("DEBUGYTTESTNEWBLOCS") == "ON" {
		cout << format("appel createBlocsEJPELNET_NEW\n");	
		G_bINSTRYT = false ; // pour observer les temps de trt
		
	}

	// --- YTR 05/10/2005 : init pour création blocs "régimes"  (dp33 uniquement)

	// --- on charge la map des txt
	if eladico == "dp33" {
		var mapetfile = format("%1%2%3_et.clt",env("ELA_TMP_IDX"),SEP,eladico);
		var lockname = fileBaseName(mapetfile);
		waitUntilLockIsReleased(lockname,12,"map "+lockname+" en cours d'utilisation",cout);
		setLockOn(lockname) ;
		var fmapet = FileStream(mapetfile,"r");
		if fmapet != nothing {
			cout << format("\n--- Lecture map et ..."); flush(cout);
			G_mapet = Object(readAll(fmapet));
			if !isaMap(G_mapet) G_mapet = Map();
			close(fmapet);
			cout << format("%1 enregistrements lus\n",G_mapet.length());
		}
		else {
			msg = format("*** echec lecture map '%1' ==> le makebloc ne peut fonctionner!\n\n",mapetfile);
			cout << msg ; G_sErrors << msg ;
			G_exitVal=INTERNAL_ERROR;
		}
		releaseLockOn(lockname);

	}

	if eladico!="elnet" {

		// --- Parsing et chargement de l'instance SGML ---
		cout << format("\nChargement du document %1...", fileBaseName(sIdxfile)); flush(cout);
		docParseResult = parseDocument(List(eladec,sDtdfile,sIdxfile));
		if docParseResult.status != 0 {
			msg = format("*** echec parsing fichier '%1'\n\n",sIdxfile);
			cout << msg ; G_sErrors << msg ;
			G_exitVal=CANNOT_LOAD_SGML_DOCUMENT;
		}
		else doc = docParseResult.document ;
		cout << "terminé\n";

		// --- creation des blocs "normaux"
		if G_exitVal==OK && !(eladico=="dp33" && G_sSourceType=="txt") createBlocs(doc,sBlocfileRoot,sSourcedir,eladico);

		if G_exitVal==OK && eladico == "dp33" && G_sSourceType == "txt" createBlocsTxtRegimes(sBlocfileRoot,sSourcedir,eladico);
	}
	else {
		cout << format("ELA_DICO=%1\tG_sSourceType=%2\tG_bEJPmode=%3\tG_bANTmode=%4\n",eladico,G_sSourceType,G_bEJPmode,G_bANTmode);

		// --- YTR 18/09/2007 : On construit les blocs en exploitant les maps maptxt.map et mapjrp.map
		//			Afin de refléter exactement le contenu de tout8 (version optj préparée chaque nuit)

		// --- on charge le maps des txt et/ou decis
		cout << format("\nCas eladico = %1\tG_sSourceType=%2\n", eladico,G_sSourceType);
		var mapfile ; 
		switch(G_sSourceType) {
		case "txt" : mapfile = format("%1%2prodmaps%2maptxt.map",env("ELA_DATA"),SEP); break;
			// YE 12/02/2014 Mantis 4380 txtblochulk
			// YE 23/05/2014 Mantis 7336 jrpblochulk
			// 09/06/2015 SF la map du dossier prodmaps n'est plus a jour, on la prend du dossier $ELA_TMP_IDX
			// case "txtblochulk" : mapfile = format("%1%2prodmaps%2maptxt.map",env("ELA_DATA"),SEP); break;
		case "txtblochulk" : mapfile = format("%1%2maptxt.map",env("ELA_TMP_IDX"),SEP); break;
		case "jrpblochulk" : mapfile = format("%1%2prodmaps%2mapjrp.map",env("ELA_DATA"),SEP); break;
		case "jrp" : mapfile = format("%1%2prodmaps%2mapjrp.map",env("ELA_DATA"),SEP); break;
			// 18/09/2014 sfouzi
			// 09/06/2015 SF la map du dossier prodmaps n'est plus a jour, on la prend du dossier $ELA_TMP_IDX
			// case "addtxtfiles" : mapfile = format("%1%2prodmaps%2maptxt.map",env("ELA_DATA"),SEP); break;
		case "addtxtfiles" : mapfile = format("%1%2maptxt.map",env("ELA_TMP_IDX"),SEP); break;
		case "addjrpfiles" : mapfile = format("%1%2mapjrp.map",env("ELA_TMP_IDX"),SEP); break;
		}

		if G_bANTmode {
			mapfile = format("%1%2mapMDF.map",env("ELA_TMP_IDX"),SEP);
			cout << format("Lecture de la map %1...", mapfile); flush(cout);
			G_mapMDFversionning = loadObjectFromFile(mapfile);
			mapfile = format("%1%2mapTxtversionning.map",env("ELA_TMP_IDX"),SEP);
		}

		if G_bEJPmode {
			// --- YTR 23/02/2011 : ancien code : on chargeait une map "jrpinfoEJP.map" mais cela devient trop consommateur en RAM
			// ---                                depuis l'ajout de Legifrance+Jurica
			mapfile = format("%1%2prodmaps%2jrpinfoEJP.map",env("ELA_DATA"),SEP);
			G_bINSTRYT = true ; // pour observer les temps de trt
			// mettre cette règle ici
			G_sBlocrule = "day";
			createBlocsEJPELNET_NEW(sBlocfileRoot, sSourcedir, G_sYearBegin, G_sYearEnd);
			
		}
		else {// quand JURICA sera intégré il faudra remettre le "else" et arrêter de charger la mapfile
			cout << format("Lecture de la map %1...", mapfile); flush(cout);
			G_maptxtjrp = loadObjectFromFile(mapfile);
			cout << format("Ok. %1 enregistrements lus\n",G_maptxtjrp.length());
			
			if G_sSourceType == "txtblochulk" {	//12/02/2014 - 4380		
				G_setIdtxtToBuild =	chargerSetJrpToBuildForHulk(G_txtToBuildFile);					
			}else if G_sSourceType == "jrpblochulk" {						
				//YE 23/05/2014
				// Mantis 7336				
				var G_ela_liv = env("ELA_LIV");
				var dirjrp = "/usr/local/ela/cd-rom/elnet/data/sgml/jrp/optj/";		
				var dateLancementDir = format("%1/dateLancement/",G_ela_liv);
				var referenceDatefile = dateLancementDir+"hulkliv.txt";
				G_setIdjrpToBuild = getSetjrpToBuild(dirjrp,referenceDatefile);	
				
			}

			// 23/07/2013 AL/MB : si exoticjrpmat ==> deposer tjrs dans $ELA_LIV/exoticjrpblocs et non dans $ELA_LIV/exoticjrpmatblocs
			createBlocsELNET(sBlocfileRoot, sSourcedir);
			
			// Mantis 7336 YE 22/05/2014 Creer les textes antereiurs				
			if (G_sSourceType == "txtblochulk"){
				// Pour activer le mod ant
				G_bANTmode = true;
				
				// YE a modifier le chemin
				sBlocdir = format("%1%2%3%2", env("ELA_LIV"),SEP,G_sSourceType);																
				sSourcedir = format("%1%2%3%2versionning%2optj%2",env("ELA_DATACOMM"), SEP, "txt");
				sBlocfileRoot = format("%1%2_%3antbloc_",sBlocdir,eladico,"txt");
				G_sErrorFileName = format("%1%2",sBlocdir,DEFAULT_ERROR_FILENAME) ;			
				
				// mapMDF cette map contient tous les txt 
				// txxxxx Map(version)
				mapfile = format("%1%2mapMDF.map",env("ELA_TMP_IDX"),SEP);
				cout << format("Lecture de la map %1...", mapfile); flush(cout);
				G_mapMDFversionning = loadObjectFromFile(mapfile);				
				
				// reduire la map G_mapMDFversionning 
				for idtxt in G_mapMDFversionning {	     
					if  not G_setIdtxtToBuild.knows(idtxt.transcript(UpperCase)) { 
						G_mapMDFversionning.remove(idtxt);	    
					}
				} 										
				mapfile = format("%1%2mapTxtversionning.map",env("ELA_TMP_IDX"),SEP);				
				G_maptxtjrp = loadObjectFromFile(mapfile);
				for idtxtMdf in G_maptxtjrp {					
					if idtxtMdf.rsearch(0,"-mdfct") > 0{						
						if  not G_setIdtxtToBuild.knows(idtxtMdf.explode("-")[0].transcript(UpperCase)) { 						
							G_maptxtjrp.remove(idtxtMdf);	    
						}
					}
				} 		
				cout << format("\nCreation des bloc anterieures ..........\n");
				createBlocsELNET(sBlocfileRoot, sSourcedir);
				
			}
			// Fin mantis 7336
		}

	}


	// --- constitution ou ecrasement du fichier d'erreurs
	if G_sErrors != "" {
		ferror = FileStream(G_sErrorFileName,"w");
		if ferror == nothing { cout << format("*** echec creation %1\n\n",G_sErrorFileName);abort(CANNOT_CREATE_ERROR_FILE); }
		ferror << G_sErrors ;
		close(ferror);
		msg = format("\n\n*** ATTENTION, des erreurs ont ete detectees\n"+
		"Consulter le fichier %1", G_sErrorFileName);
		cout << msg;
		if G_exitVal==OK G_exitVal=PARSE_OR_CODE_ERROR;
	}
	else if fileAccess(G_sErrorFileName,"w") fileRemove(G_sErrorFileName);



	msg = format("\n%1%2 : fin du traitement - %3\n\n",LINESEPARATOR,PROGNAME,timeFormat(timeCurrent(),"%A %d/%m/%Y %H:%M:%S\n"));		
	cout << msg ;

	G_tracefile << msg;
	close(G_tracefile);
	cout << format("Fin du programme makeblocs_v2.bal\n");
	exit(G_exitVal);

} // main



//---------------------------------------------------------------------


/*
error {
	G_sErrors << format("\n*** ERREUR FATALE : fichier SGML %1  ligne %2 / "+
				"fichier balise %3 fonction %4 ligne %5 / erreur %6 : %7",
				SgmlFile, SgmlLine, ErrorFile, ErrorFun, ErrorLine, ErrorName, ErrorArg) ;
}

error [User] {
	G_sErrors << format("\n*** ERREUR FATALE : erreur %6 : %7",
				SgmlFile, SgmlLine, ErrorFile, ErrorFun, ErrorLine, ErrorName, ErrorArg) ;
}
*/

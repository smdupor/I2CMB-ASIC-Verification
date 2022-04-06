// ===============================================
// Copyright 2010-2012 Mentor Graphics Corporation
//
//    All Rights Reserved.
//
// THIS WORK CONTAINS TRADE SECRET
// AND PROPRIETARY INFORMATION WHICH IS THE
// PROPERTY OF MENTOR GRAPHICS
// CORPORATION OR ITS LICENSORS AND IS
// SUBJECT TO LICENSE TERMS.
// ===============================================
//
// MGCLangOptions.js
//

function MGCSetLangOptions()
{
   MGCSetTabLangOptions();
   MGCButtonBarLangOptions();
   MGCSearchMessages();
   MGCOptionsDBLang();
   MGCHelpTopicTitles();

   translateText();
}

function MGCSetTabLangOptions()
{
   TabLabels = ["Rubriques","Index","Recherche","",""];
   InActiveTooltip = "Basculer vers";
   NoIndexTooltip = "Pas d'index pour ce document";
   ActiveToolTip = "L'onglet Rubriques est actif";
   TOCResize = "Cliquez et glissez pour redimensionner";
   InfoHubLink = "Pour d'autres informations, y compris les vidéos et la formation, ouvrez ";
   InfoHubTerm = "InfoHub.";
   LibListTitle = "Toute la documentation";
}

function MGCButtonBarLangOptions()
{
   Button = {};
   Button["Titles"] = {};
   Button.Titles["closewindow"] = "Fermer cette fenêtre";
   Button.Titles["showtabsX"] = "Afficher les onglets Rubriques, Index et Recherche";
   Button.Titles["showtabs"] = "Masquer les onglets Rubriques, Index et Recherche";
   Button.Titles["hidedoclist"] = "Masquer la liste de documents";
   Button.Titles["home"] = "Afficher la page de titre pour ";
   Button.Titles["prevtopic"] = "Rubrique précédente";
   Button.Titles["prevtopicX"] = "Pas de rubrique précédente";
   Button.Titles["nexttopic"] = "Rubrique suivante";
   Button.Titles["nexttopicX"] = "Pas de rubrique suivante";
   Button.Titles["prevsrch"] = "Résultat de recherche précédent";
   Button.Titles["nextsrch"] = "Résultat de recherche suivant";
   Button.Titles["highlight_on"] = "Désactiver la mise en surbrillance";
   Button.Titles["highlight_off"] = "Activer la mise en surbrillance";
   Button.Titles["font0"] = "Petite taille de police";
   Button.Titles["font1"] = "Taille de police normale";
   Button.Titles["font2"] = "Grande taille de police";
   Button.Titles["help"] = "Aide";
   Button.Titles["ihub"] = "Ouvrir InfoHub pour voir d'autres manuels";
   Button.Titles["pdf"] = "Ouvrir le PDF de cette rubrique";
   Button.Titles["print"] = "Imprimer cette rubrique";
   Button.Titles["feedback"] = "Envoyer un retour d'informations à propos de ce document à Mentor Graphics";
   Button.Titles["mgc"] = "Afficher le site Web de Mentor Graphics";
   Button.Titles["preferences"] = "Boîte de dialogue Préférences d'affichage";
   Button["Text"] = {};
   Button.Text["ihub"] = "Autres manuels";
   Button.Text["title"] = "Afficher la liste de tous les documents installés";
   Button.Text["fonts"] = "TAILLE DE TEXTE ";
   Button.Text["feedback"] = "Retour d'information";
   return;
}

function MGCOptionsDBLang()
{
   ODBLabels = {};
   ODBLabels["title"] = "Préférences de la documentation MGC";
   ODBLabels["close"] = "Fermer la boîte de dialogue Options";
   ODBLabels["intro"] = "Modifier les options du système de documentation de Mentor Graphics.";
   ODBLabels["AllDocs"] = "Tous les documents installés";
   ODBLabels["MyBooks"] = "Mes guides";
   ODBLabels["SNet"] = "SupportNet";
   ODBLabels["SortByTopic"] = "Par rubrique";
   ODBLabels["SortByBook"] = "Par guide/par rubrique";
   ODBLabels["SortTitle"] = "Ordre de tri :";
   ODBLabels["ScopeTitle"] = "Domaine de recherche :";
   ODBLabels["MiscTitle"] = "Options diverses :";
   ODBLabels["ApplyFilterMsg"] = "Filtrer les résultats de recherche selon les paramètres actuels";
   ODBLabels["CloseFilterMsg"] = "Fermer les options du filtre de recherche";
   ODBLabels["FilterResultsMsg"] = "<b>Filtrer les résultats de recherche selon:</b>";
   ODBLabels["FilterResultsBtn"] = "Filtrer les résultats";
   ODBLabels["RemoveFilterBtn"] = "Supprimer le filtre";
   ODBLabels["SearchTipsBtn"] = "Conseils pour la recherche";
   ODBLabels["SearchCommands"] = "Limiter la recherche aux titres des commandes et des fonctions";
   ODBLabels["SearchTitles"] = "Afficher seulement les résultats contenant les termes de recherche dans l'en-tête";
   ODBLabels["ExactMatchSearch"] = "Correspondance exacte des mots de la recherche";
   ODBLabels["IncludeSynonyms"] = "Ne pas inclure les synonymes";
   ODBLabels["DisplayFunctionsTitle"] = "Liste des commandes et fonctions pour ";
   ODBLabels["DisplaySynonymsTitle"] = "Liste des synonymes définis pour ";
   ODBLabels["DisplaySynonymsFeedback1"] = "Voulez-vous ajouter des définitions de synonymes ? Envoyez-nous ";
   ODBLabels["DisplaySynonymsFeedback2"] = "Retour d'information";
   ODBLabels["DisplaySnippets"] = "Afficher les extraits de texte dans les résultats";
   ODBLabels["DisplayCloseList"] = "Fermer la liste";
   ODBLabels["DisplayShowList"] = "\(Afficher la liste\)";
   ODBLabels["DisplaySynonyms"] = "Afficher la liste des synonymes";
   ODBLabels["DisplayKeywords"] = "Afficher la liste des mots-clés de recherche";
   ODBLabels["IncludeVariants"] = "Inclure les variantes \(\.\*mot-clé\.\*\)";
   ODBLabels["IncludedSynonyms"] = "Les synonymes (en vert) inclus dans cette recherche sont:\n";
   ODBLabels["Persistence"] = "Ces paramètres sont temporaires pour cette session du navigateur seulement.\n";
   ODBLabels["DisplaySnippets"] = "Afficher les extraits de recherche/d'index.\n";
}

function MGCSearchMessages()
{
   SearchMessages = {};
   SearchMessages.QSPrompt = "Rechercher dans ce document";
   SearchMessages.QSBasic = "Effectuer une recherche par mot-clé dans ce document.";
   SearchMessages.QSPrevTip = "Rubrique précédente contenant le(s) mots de la recherche";
   SearchMessages.QSNextTip = "Rubrique suivante contenant le(s) mots de la recherche";
   SearchMessages.NoSearchResults = "Pas de résultats trouvés.";
   SearchMessages.Searched4Begin = "Vous avez recherché ";
   SearchMessages.Searched4End = "Vous ne trouvez pas ce que vous cherchez ? Soumettre la même recherche à ";
   SearchMessages.SearchedShowing = " Affichage de ";
   SearchMessages.SearchedShowingE = " résultats.";
   SearchMessages.TurnHighlightOn = "Activer la mise en surbrillance";
   SearchMessages.TurnHighlightOff = "Désactiver la mise en surbrillance";
   SearchMessages.ApplyFilter = "Appliquer un filtre";
   SearchMessages.RemoveFilter = "Supprimer le filtre";
}

function MGCHelpTopicTitles()
{
   HelpTopicTitle = {};
   HelpTopicTitle.Tip = "Conseils sur";
   HelpTopicTitle.Search = "Conseils pour la recherche";
   HelpTopicTitle.Nav = "Navigation";
   HelpTopicTitle.QuickHelp = "Aide rapide";
   HelpTopicTitle.Print = "Impression";
   HelpTopicTitle.Settings = "Paramètres du Navigateur";
   HelpTopicTitle.Feedback = "Envoyer un retour d'informations sur la documentation";
   HelpTopicTitle.Sep = " | ";
}

function translateText() {
    var e = document.getElementById("tab0");
    e.innerText = TabLabels[0];

    e = document.getElementById("tab1");
    if (e) e.innerText = TabLabels[1];

    // Set Search tab label. 
    // Search tab is hidden for all except English. The test is done in mgchelp.js
    e = document.getElementById("tab2");
    if(e) e.innerText = TabLabels[2];

    // Note the following is sensitive to the order of nodes in mgchelp.htm.
    e = document.getElementById("InfoHubLibListLink");
    if (e) {
        var children = e.childNodes;
        if (children[0]) children[0].textContent = InfoHubLink; // Text of the InfoHubLibListLink
        if (children[1]) children[1].innerText = InfoHubTerm;   // Text of the nested <a> child node.
    }

    e = document.getElementById("LibListTitle");
    if (e) e.innerText = LibListTitle;

    e = document.getElementById("dragbar");
    if (e) e.setAttribute('title', TOCResize);

    e = document.getElementById("showhidetabs");
    e.setAttribute('title', Button.Titles["showtabs"]);

    e = document.getElementById('HideShowTOC');
    if (e) e.setAttribute('title', Button.Titles["showtabs"]);

    e = document.getElementById('HideDocList');
    if (e) e.setAttribute('title', Button.Titles['hidedoclist']);

    e = document.getElementById("PrevTopic");
    e.firstElementChild.setAttribute('title', Button.Titles["prevtopic"]);

    e = document.getElementById("NextTopic");
    e.firstElementChild.setAttribute('title', Button.Titles["nexttopic"]);

    // Feedback link not present for SIEMENS_OEM, but it's also hidden for translations.
    e = document.getElementById("FdbackLnk");
    if (e != null) {
        // e.firstElementChild.setAttribute('title', Button.Titles["feedback"]);
        e.setAttribute('style', 'display: none;');
    }

    /* 
    * Hidden for all but English.
    e = document.getElementById("FeedbackSpan");
    if(e != null) {
      e.innerText = Button.Text["feedback"];
    }
    */

    e = document.getElementById("manuals_button");
    e.setAttribute('title', Button.Text["title"]);
    e = document.getElementById("MoreSpan");
    e.innerText = Button.Text["ihub"];

    // The footer contains links to the untranslated mgc_help book. 
    // It is hidden for all but English.
    e = document.getElementById("footer");
    if (e) e.setAttribute('style', 'display: none;');

    // Hidden for all but English.
    // e.firstElementChild.setAttribute('title', Button.Titles["pdf"]);    
    e = document.getElementById("PDFLnk");
    if (e) e.setAttribute('style', 'display: none;');

    e = document.getElementById("PrintTopic");
    e.setAttribute('title', Button.Titles["print"]);
}

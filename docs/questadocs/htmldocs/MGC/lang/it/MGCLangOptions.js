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
   TabLabels = ["Argomenti", "Indice", "Ricerca","",""];
   InActiveTooltip = "Passa a";
   NoIndexTooltip = "Nessun indice per questo documento";
   ActiveToolTip = "La scheda Argomenti è attiva";
   TOCResize = "Fare clic e trascinare per modificare le dimensioni";
   InfoHubLink = "Per ulteriori informazioni, compresi video e formazione, aprire ";
   InfoHubTerm = "InfoHub.";
   LibListTitle = "Tutta la documentazione";
}

function MGCButtonBarLangOptions()
{
   Button = {};
   Button["Titles"] = {};
   Button.Titles["closewindow"] = "Chiudi la finestra";
   Button.Titles["showtabsX"] = "Mostra le schede Argomenti, Indice e Ricerca";
   Button.Titles["showtabs"] = "Nascondi le schede Argomenti, Indice e Ricerca";
   Button.Titles["hidedoclist"] = "Nascondi elenco di documenti";
   Button.Titles["home"] = "Visualizza pagina del titolo per ";
   Button.Titles["prevtopic"] = "Argomento precedente";
   Button.Titles["prevtopicX"] = "Nessun argomento precedente";
   Button.Titles["nexttopic"] = "Argomento successivo";
   Button.Titles["nexttopicX"] = "Nessun argomento successivo";
   Button.Titles["prevsrch"] = "Risultato precedente della ricerca";
   Button.Titles["nextsrch"] = "Risultato successivo della ricerca";
   Button.Titles["highlight_on"] = "Disattiva evidenziazione";
   Button.Titles["highlight_off"] = "Attiva evidenziazione";
   Button.Titles["font0"] = "Dimensioni carattere ridotte";
   Button.Titles["font1"] = "Dimensioni carattere normali";
   Button.Titles["font2"] = "Dimensioni carattere grandi";
   Button.Titles["help"] = "Guida";
   Button.Titles["ihub"] = "Apri InfoHub per visualizzare altri manuali";
   Button.Titles["pdf"] = "Apri il PDF relativo all’argomento";
   Button.Titles["print"] = "Stampa l’argomento";
   Button.Titles["feedback"] = "Invia un feedback sul documento a Mentor Graphics";
   Button.Titles["mgc"] = "Visualizza il sito web di Mentor Graphics";
   Button.Titles["preferences"] = "Visualizza la finestra di dialogo Preferenze";
   Button["Text"] = {};
   Button.Text["ihub"] = "Altri manuali";
   Button.Text["title"] = "Mostra l'elenco di tutti i documenti installati";
   Button.Text["fonts"] = "DIMENSIONE TESTO ";
   Button.Text["feedback"] = "Feedback";
   return;
}

function MGCOptionsDBLang()
{
   ODBLabels = {};
   ODBLabels["title"] = "Preferenze della documentazione MGC";
   ODBLabels["close"] = "Chiudi la finestra di dialogo Opzioni";
   ODBLabels["intro"] = "Modificare le opzioni di sistema della documentazione di Mentor Graphics.";
   ODBLabels["AllDocs"] = "Tutti i documenti installati";
   ODBLabels["MyBooks"] = "I miei raccoglitori";
   ODBLabels["SNet"] = "SupportNet";
   ODBLabels["SortByTopic"] = "Per argomento";
   ODBLabels["SortByBook"] = "Per argomento/raccoglitore";
   ODBLabels["SortTitle"] = "Criterio di ordinamento:";
   ODBLabels["ScopeTitle"] = "Ambito della ricerca:";
   ODBLabels["MiscTitle"] = "Opzioni varie:";
   ODBLabels["ApplyFilterMsg"] = "Filtra i risultati della ricerca in base alle impostazioni attuali";
   ODBLabels["CloseFilterMsg"] = "Chiudi opzioni di filtro della ricerca";
   ODBLabels["FilterResultsMsg"] = "<b>Filtra i risultati della ricerca in base a:</b>";
   ODBLabels["FilterResultsBtn"] = "Filtra risultati";
   ODBLabels["RemoveFilterBtn"] = "Rimuovi filtro";
   ODBLabels["SearchTipsBtn"] = "Istruzioni per la ricerca";
   ODBLabels["SearchCommands"] = "Limita la ricerca ai titoli di comandi e funzioni";
   ODBLabels["SearchTitles"] = "Mostra solo i risultati con intestazioni contenenti i termini ricercati";
   ODBLabels["ExactMatchSearch"] = "Corrispondenza esatta dei termini ricercati";
   ODBLabels["IncludeSynonyms"] = "Non includere i sinonimi";
   ODBLabels["DisplayFunctionsTitle"] = "Elenco di comandi/funzioni per ";
   ODBLabels["DisplaySynonymsTitle"] = "Elenco di sinonimi definiti per ";
   ODBLabels["DisplaySynonymsFeedback1"] = "Si desidera aggiungere altre definizioni di sinonimi? Invia ";
   ODBLabels["DisplaySynonymsFeedback2"] = "Feedback";
   ODBLabels["DisplaySnippets"] = "Mostra frammenti di testo nei risultati";
   ODBLabels["DisplayCloseList"] = "Chiudi elenco";
   ODBLabels["DisplayShowList"] = "\(Mostra elenco\)";
   ODBLabels["DisplaySynonyms"] = "Visualizza elenco di sinonimi";
   ODBLabels["DisplayKeywords"] = "Visualizza l'elenco di parole chiave da ricercare";
   ODBLabels["IncludeVariants"] = "Includi varianti \(\.\*parola chiave\.\*\)";
   ODBLabels["IncludedSynonyms"] = "I sinonimi (evidenziati in verde) inclusi nella ricerca sono:\n";
   ODBLabels["Persistence"] = "Le impostazioni sono temporanee e specifiche della sessione del browser corrente.\n";
   ODBLabels["DisplaySnippets"] = "Visualizzare frammenti di indice/ricerca.\n";
}

function MGCSearchMessages()
{
   SearchMessages = {};
   SearchMessages.QSPrompt = "Cerca nel documento";
   SearchMessages.QSBasic = "Eseguire una ricerca per parola chiave nel documento corrente.";
   SearchMessages.QSPrevTip = "Argomento precedente contenente i termini ricercati";
   SearchMessages.QSNextTip = "Argomento successivo contenente i termini ricercati";
   SearchMessages.NoSearchResults = "Nessun risultato trovato.";
   SearchMessages.Searched4Begin = "È stata eseguita la ricerca di ";
   SearchMessages.Searched4End = "Impossibile trovare il risultato desiderato? Invia la stessa ricerca a ";
   SearchMessages.SearchedShowing = " Visualizzazione ";
   SearchMessages.SearchedShowingE = " risultati.";
   SearchMessages.TurnHighlightOn = "Attiva evidenziazione";
   SearchMessages.TurnHighlightOff = "Disattiva evidenziazione";
   SearchMessages.ApplyFilter = "Applica filtro";
   SearchMessages.RemoveFilter = "Rimuovi filtro";
}

function MGCHelpTopicTitles()
{
   HelpTopicTitle = {};
   HelpTopicTitle.Tip = "Istruzioni per";
   HelpTopicTitle.Search = "Istruzioni per la ricerca";
   HelpTopicTitle.Nav = "Navigazione";
   HelpTopicTitle.QuickHelp = "Guida rapida";
   HelpTopicTitle.Print = "Stampa";
   HelpTopicTitle.Settings = "Impostazioni del browser";
   HelpTopicTitle.Feedback = "Invia feedback sulla documentazione";
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

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
   TabLabels = ["Themen","Index","Suche","",""];
   InActiveTooltip = "Umstellen auf";
   NoIndexTooltip = "Für dieses Dokument ist kein Index vorhanden";
   ActiveToolTip = "Registerkarte 'Themen' ist aktiv";
   TOCResize = "Zum Anpassen der Größe klicken und ziehen";
   InfoHubLink = "Für weitere Informationen, einschließlich Filme und Training, öffnen Sie den ";
   InfoHubTerm = "InfoHub.";
   LibListTitle = "Gesamte Dokumentation";
}

function MGCButtonBarLangOptions()
{
   Button = {};
   Button["Titles"] = {};
   Button.Titles["closewindow"] = "Dieses Fenster schließen";
   Button.Titles["showtabsX"] = "Themen-, Index- und Suchregisterkarten anzeigen";
   Button.Titles["showtabs"] = "Themen-, Index- und Suchregisterkarten ausblenden";
   Button.Titles["hidedoclist"] = "Dokumentenliste ausblenden";
   Button.Titles["home"] = "Titelseite anzeigen für ";
   Button.Titles["prevtopic"] = "Vorheriges Thema";
   Button.Titles["prevtopicX"] = "Kein vorheriges Thema";
   Button.Titles["nexttopic"] = "Nächstes Thema";
   Button.Titles["nexttopicX"] = "Kein nächstes Thema";
   Button.Titles["prevsrch"] = "Vorheriges Suchergebnis";
   Button.Titles["nextsrch"] = "Nächstes Suchergebnis";
   Button.Titles["highlight_on"] = "Hervorhebung deaktivieren";
   Button.Titles["highlight_off"] = "Hervorhebung aktivieren";
   Button.Titles["font0"] = "Kleiner Schriftgrad";
   Button.Titles["font1"] = "Normaler Schriftgrad";
   Button.Titles["font2"] = "Großer Schriftgrad";
   Button.Titles["help"] = "Hilfe";
   Button.Titles["ihub"] = "InfoHub zum Anzeigen weiterer Handbücher anzeigen";
   Button.Titles["pdf"] = "PDF für dieses Thema öffnen";
   Button.Titles["print"] = "Dieses Thema drucken";
   Button.Titles["feedback"] = "Feedback für dieses Dokument an Mentor Graphics senden";
   Button.Titles["mgc"] = "Website von Mentor Graphics aufrufen";
   Button.Titles["preferences"] = "Voreinstellungsdialogfenster anzeigen";
   Button["Text"] = {};
   Button.Text["ihub"] = "Weitere Handbücher";
   Button.Text["title"] = "Liste aller installierten Dokumente anzeigen";
   Button.Text["fonts"] = "TEXTGRÖSSE ";
   Button.Text["feedback"] = "Feedback";
   return;
}

function MGCOptionsDBLang()
{
   ODBLabels = {};
   ODBLabels["title"] = "MGC-Dokumentationsvoreinstellungen";
   ODBLabels["close"] = "Optionsdialogfenster schließen";
   ODBLabels["intro"] = "Ändern Sie Systemoptionen für die Mentor Graphics-Dokumentation.";
   ODBLabels["AllDocs"] = "Alle installierten Dokumente";
   ODBLabels["MyBooks"] = "Meine Bücher";
   ODBLabels["SNet"] = "SupportNet";
   ODBLabels["SortByTopic"] = "Nach Thema";
   ODBLabels["SortByBook"] = "Nach Buch/Thema";
   ODBLabels["SortTitle"] = "Sortierreihenfolge:";
   ODBLabels["ScopeTitle"] = "Suchbereich:";
   ODBLabels["MiscTitle"] = "Verschiedene Optionen:";
   ODBLabels["ApplyFilterMsg"] = "Suchergebnisse basierend auf aktuellen Einstellungen filtern";
   ODBLabels["CloseFilterMsg"] = "Suchfilteroptionen schließen";
   ODBLabels["FilterResultsMsg"] = "<b>Suchergebnisse filtern basierend auf:</b>";
   ODBLabels["FilterResultsBtn"] = "Filterergebnisse";
   ODBLabels["RemoveFilterBtn"] = "Filter entfernen";
   ODBLabels["SearchTipsBtn"] = "Suchtipps";
   ODBLabels["SearchCommands"] = "Suche auf Befehls- und Funktionstitel beschränken";
   ODBLabels["SearchTitles"] = "Nur Ergebnisse mit den Suchbegriffen in Überschriften anzeigen";
   ODBLabels["ExactMatchSearch"] = "Exakte Übereinstimmung der Suchbegriffe";
   ODBLabels["IncludeSynonyms"] = "Synonyme nicht einschließen";
   ODBLabels["DisplayFunctionsTitle"] = "Liste der Befehle/Funktionen für ";
   ODBLabels["DisplaySynonymsTitle"] = "Liste der definierten Synonyme für ";
   ODBLabels["DisplaySynonymsFeedback1"] = "Möchten Sie, dass zusätzliche Synonymdefinitionen hinzugefügt werden? Senden Sie uns ";
   ODBLabels["DisplaySynonymsFeedback2"] = "Feedback";
   ODBLabels["DisplaySnippets"] = "Textschnipsel in Ergebnissen anzeigen";
   ODBLabels["DisplayCloseList"] = "Liste schließen";
   ODBLabels["DisplayShowList"] = "\(Liste anzeigen\)";
   ODBLabels["DisplaySynonyms"] = "Synonymliste anzeigen";
   ODBLabels["DisplayKeywords"] = "Schlagwortliste anzeigen";
   ODBLabels["IncludeVariants"] = "Varianten einschließen \(\.\*Schlagwort\.\*\)";
   ODBLabels["IncludedSynonyms"] = "In dieser Suche enthaltene Synonyme (grün hervorgehoben) sind:\n";
   ODBLabels["Persistence"] = "Diese Einstellungen sind temporär nur für diese Browser-Sitzung.\n";
   ODBLabels["DisplaySnippets"] = "Such-/Indexschnipsel anzeigen.\n";
}

function MGCSearchMessages()
{
   SearchMessages = {};
   SearchMessages.QSPrompt = "Dieses Dokument durchsuchen";
   SearchMessages.QSBasic = "Führen Sie eine Schlagwortsuche im aktuellen Dokument durch.";
   SearchMessages.QSPrevTip = "Vorheriges Thema, das die Suchbegriffe enthält";
   SearchMessages.QSNextTip = "Nächstes Thema, das die Suchbegriffe enthält";
   SearchMessages.NoSearchResults = "Keine Ergebnisse gefunden.";
   SearchMessages.Searched4Begin = "Sie haben gesucht nach ";
   SearchMessages.Searched4End = "Können Sie das Gesuchte nicht finden? Die gleiche Suche senden an ";
   SearchMessages.SearchedShowing = " Anzeigen ";
   SearchMessages.SearchedShowingE = " von Ergebnissen.";
   SearchMessages.TurnHighlightOn = "Hervorhebung aktivieren";
   SearchMessages.TurnHighlightOff = "Hervorhebung deaktivieren";
   SearchMessages.ApplyFilter = "Filter anwenden";
   SearchMessages.RemoveFilter = "Filter entfernen";
}

function MGCHelpTopicTitles()
{
   HelpTopicTitle = {};
   HelpTopicTitle.Tip = "Tipps aktiviert";
   HelpTopicTitle.Search = "Suchtipps";
   HelpTopicTitle.Nav = "Navigieren";
   HelpTopicTitle.QuickHelp = "Schnellhilfe";
   HelpTopicTitle.Print = "Drucken";
   HelpTopicTitle.Settings = "Browser-Einstellungen";
   HelpTopicTitle.Feedback = "Feedback zur Dokumentation senden";
   HelpTopicTitle.Sep = " | ";
}

function translateText()
{

    var e = document.getElementById("tab0");
    e.innerText = TabLabels[0];

    e = document.getElementById("tab1");
    if(e) e.innerText = TabLabels[1];

    // Set Search tab label. 
    // Search tab is hidden for all except English. The test is done in mgchelp.js
    e = document.getElementById("tab2");
    if(e) e.innerText = TabLabels[2];

    // Note the following is sensitive to the order of nodes in mgchelp.htm.
    e = document.getElementById("InfoHubLibListLink");
    if(e) {
      var children = e.childNodes;
      if(children[0]) children[0].textContent = InfoHubLink; // Text of the InfoHubLibListLink
      if(children[1]) children[1].innerText = InfoHubTerm;   // Text of the nested <a> child node.
    }

    e = document.getElementById("LibListTitle");
    if(e) e.innerText = LibListTitle;

    e = document.getElementById("dragbar");
    if(e) e.setAttribute('title', TOCResize);

    e = document.getElementById("showhidetabs");
    e.setAttribute('title', Button.Titles["showtabs"]);

    e = document.getElementById('HideShowTOC');
    if(e) e.setAttribute('title', Button.Titles["showtabs"]);

    e = document.getElementById('HideDocList');
    if(e) e.setAttribute('title', Button.Titles['hidedoclist']);

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

    // Feedback link not present for SIEMENS_OEM
    if(e != null) {
      e.firstElementChild.setAttribute('title', Button.Titles["feedback"]);
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

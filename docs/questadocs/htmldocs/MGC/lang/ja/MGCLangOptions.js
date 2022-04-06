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
   TabLabels = ["トピック","インデックス","検索","",""];
   InActiveTooltip = "Switch to";
   NoIndexTooltip = "There is no index for this document";
   ActiveToolTip = "トピックタブを現在選択中";
   TOCResize = "クリックしてからドラッグ";
   InfoHubLink = "ムービーやトレーニングなどその他の情報は、";
   InfoHubTerm = "InfoHubを開いてください。";
   LibListTitle = "マニュアル一覧";
}

function MGCButtonBarLangOptions()
{
   Button = {};
   Button["Titles"] = {};
   Button.Titles["closewindow"] = "Close this window";
   Button.Titles["showtabsX"] = "トピックタブを表示";     // "Show Topics Tab";
   Button.Titles["showtabs"] = "トピックタブを非表示";    // "Hide Topics Tab";
   Button.Titles["hidedoclist"] = "Hide document list";
   Button.Titles["home"] = "このマニュアルのタイトルを表示";
   Button.Titles["prevtopic"] = "前のトピック";
   Button.Titles["prevtopicX"] = "前のトピックはありません";
   Button.Titles["nexttopic"] = "次のトピック";
   Button.Titles["nexttopicX"] = "次のトピックはありません";
   Button.Titles["prevsrch"] = "Previous Search Result";
   Button.Titles["nextsrch"] = "Next Search Result";
   Button.Titles["highlight_on"] = "Turn OFF Highlighting";
   Button.Titles["highlight_off"] = "Turn ON Highlighting";
   Button.Titles["font0"] = "Small font size";
   Button.Titles["font1"] = "Normal font size";
   Button.Titles["font2"] = "Large font size";
   Button.Titles["help"] = "Help";
   Button.Titles["ihub"] = "Open the InfoHub to view more manuals";
   Button.Titles["pdf"] = "Open the PDF for this topic";
   Button.Titles["print"] = "このトピックを印刷";
   Button.Titles["feedback"] = "Submit feedback on this document to Mentor Graphics";
   Button.Titles["mgc"] = "Display the Mentor Graphics web site";
   Button.Titles["preferences"] = "Display preferences dialog box";
   Button["Text"] = {};
   Button.Text["ihub"] = "他のマニュアルを表示";
   Button.Text["title"] = "利用可能なマニュアル一覧を表示";
   Button.Text["fonts"] = "TEXT SIZE ";
   Button.Text["feedback"] = "Feedback";
   return;
}

function MGCOptionsDBLang()
{
   ODBLabels = {};
   ODBLabels["title"] = "MGC Documentation Preferences";
   ODBLabels["close"] = "Close the Options Dialog Box";
   ODBLabels["intro"] = "Modify Mentor Graphics documentation system options.";
   ODBLabels["AllDocs"] = "All Installed Docs";
   ODBLabels["MyBooks"] = "My Books";
   ODBLabels["SNet"] = "SupportNet";
   ODBLabels["SortByTopic"] = "By Topic";
   ODBLabels["SortByBook"] = "By Book/Topic";
   ODBLabels["SortTitle"] = "Sort Order:";
   ODBLabels["ScopeTitle"] = "Search Scope:";
   ODBLabels["MiscTitle"] = "Misc Options:";
   ODBLabels["ApplyFilterMsg"] = "Filter search results based on current settings";
   ODBLabels["CloseFilterMsg"] = "Close Search Filter Options";
   ODBLabels["FilterResultsMsg"] = "<b>Filter search results based on:</b>";
   ODBLabels["FilterResultsBtn"] = "Filter Results";
   ODBLabels["RemoveFilterBtn"] = "Remove Filter";
   ODBLabels["SearchTipsBtn"] = "Search Tips";
   ODBLabels["SearchCommands"] = "Limit Search to Command and Function Titles";
   ODBLabels["SearchTitles"] = "Show only results with the search term(s) in headings";
   ODBLabels["ExactMatchSearch"] = "Exact match of search word(s)";
   ODBLabels["IncludeSynonyms"] = "Do not include synonyms";
   ODBLabels["DisplayFunctionsTitle"] = "List of Commands/Functions for ";
   ODBLabels["DisplaySynonymsTitle"] = "List of defined synonyms for ";
   ODBLabels["DisplaySynonymsFeedback1"] = "Want additional synonym definitions added? Send us ";
   ODBLabels["DisplaySynonymsFeedback2"] = "Feedback";
   ODBLabels["DisplaySnippets"] = "Show text snippets in results";
   ODBLabels["DisplayCloseList"] = "Close List";
   ODBLabels["DisplayShowList"] = "\(Show List\)";
   ODBLabels["DisplaySynonyms"] = "View Synonym List";
   ODBLabels["DisplayKeywords"] = "View Search Keyword List";
   ODBLabels["IncludeVariants"] = "Include Variants \(\.\*keyword\.\*\)";
   ODBLabels["IncludedSynonyms"] = "Synonyms (highlighted in green) included in this search are:\n";
   ODBLabels["Persistence"] = "These settings are temporary for this browser session only.\n";
   ODBLabels["DisplaySnippets"] = "Show search/index snippets.\n";
}

function MGCSearchMessages()
{
   SearchMessages = {};
   SearchMessages.QSPrompt = "Search this document";
   SearchMessages.QSBasic = "Perform a Keyword Search in the current document.";
   SearchMessages.QSPrevTip = "Previous topic containing search word(s)";
   SearchMessages.QSNextTip = "Next topic containing search word(s)";
   SearchMessages.NoSearchResults = "No results found.";
   SearchMessages.Searched4Begin = "You searched for ";
   SearchMessages.Searched4End = "Can't find what you need? Submit the same search to ";
   SearchMessages.SearchedShowing = " Showing ";
   SearchMessages.SearchedShowingE = " results.";
   SearchMessages.TurnHighlightOn = "Turn ON Highlighting";
   SearchMessages.TurnHighlightOff = "Turn OFF Highlighting";
   SearchMessages.ApplyFilter = "Apply Filter";
   SearchMessages.RemoveFilter = "Remove Filter";
}

function MGCHelpTopicTitles()
{
   HelpTopicTitle = {};
   HelpTopicTitle.Tip = "Tips on";
   HelpTopicTitle.Search = "Search Tips";
   HelpTopicTitle.Nav = "Navigating";
   HelpTopicTitle.QuickHelp = "Quick Help";
   HelpTopicTitle.Print = "Printing";
   HelpTopicTitle.Settings = "Browser Settings";
   HelpTopicTitle.Feedback = "Send Feedback on Documentation";
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
    if (e) e.innerText = LibListTitle;

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
    if(e != null) {
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
    if(e) e.setAttribute('style', 'display: none;');
    
    // Hidden for all but English.
    // e.firstElementChild.setAttribute('title', Button.Titles["pdf"]);    
    e = document.getElementById("PDFLnk");
    if(e) e.setAttribute('style', 'display: none;');

    e = document.getElementById("PrintTopic");
    e.setAttribute('title', Button.Titles["print"]);
}

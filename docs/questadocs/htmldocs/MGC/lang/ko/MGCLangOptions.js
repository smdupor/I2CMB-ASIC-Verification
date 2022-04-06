// ===============================================
// Copyright 2010-2020 Mentor Graphics Corporation
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
   TabLabels = ["항목","색인","검색","",""];
   InActiveTooltip = "다음으로 전환";
   NoIndexTooltip = "There is no index for this document";
   ActiveToolTip = "주제 탭이 활성화 상태";
   TOCResize = "클릭한 후 끌어서 크기 조정";
   InfoHubLink = "동영상 및 교육을 포함한 추가 정보를 보려면 ";
   InfoHubTerm = "InfoHub를 엽니다.";
   LibListTitle = "모든 문서";
}

function MGCButtonBarLangOptions()
{
   Button = {};
   Button["Titles"] = {};
   Button.Titles["closewindow"] = "이 윈도우 닫기";
   Button.Titles["showtabsX"] = "주제, 색인 및 검색 탭 표시";
   Button.Titles["showtabs"] = "주제, 색인 및 검색 탭 숨기기";
   Button.Titles["hidedoclist"] = "문서 리스트 숨기기";
   Button.Titles["home"] = "다음에 대한 제목 페이지 표시 ";
   Button.Titles["prevtopic"] = "이전 주제";
   Button.Titles["prevtopicX"] = "이전 주제 없음";
   Button.Titles["nexttopic"] = "다음 주제";
   Button.Titles["nexttopicX"] = "다음 주제 없음";
   Button.Titles["prevsrch"] = "이전 검색 결과";
   Button.Titles["nextsrch"] = "다음 검색 결과";
   Button.Titles["highlight_on"] = "강조 표시 끄기";
   Button.Titles["highlight_off"] = "강조 표시 켜기";
   Button.Titles["font0"] = "작은 글꼴 크기";
   Button.Titles["font1"] = "보통 글꼴 크기";
   Button.Titles["font2"] = "큰 글꼴 크기";
   Button.Titles["help"] = "도움말";
   Button.Titles["ihub"] = "더 많은 매뉴얼을 보려면 InfoHub 열기";
   Button.Titles["pdf"] = "이 주제에 대한 PDF 열기";
   Button.Titles["print"] = "이 주제 인쇄";
   Button.Titles["feedback"] = "이 문서에 대한 피드백을 Mentor Graphics에 제출";
   Button.Titles["mgc"] = "Mentor Graphics 웹 사이트 표시";
   Button.Titles["preferences"] = "환경설정 다이얼로그 표시";
   Button["Text"] = {};
   Button.Text["ihub"] = "더 많은 매뉴얼";
   Button.Text["title"] = "설치된 모든 문서 리스트 표시";
   Button.Text["fonts"] = "텍스트 크기 ";
   Button.Text["feedback"] = "피드백";
   return;
}

function MGCOptionsDBLang()
{
   ODBLabels = {};
   ODBLabels["title"] = "MGC 문서 환경설정";
   ODBLabels["close"] = "옵션 다이얼로그 닫기";
   ODBLabels["intro"] = "Mentor Graphics 문서 시스템 옵션을 수정합니다.";
   ODBLabels["AllDocs"] = "설치된 모든 문서";
   ODBLabels["MyBooks"] = "내 책";
   ODBLabels["SNet"] = "SupportNet";
   ODBLabels["SortByTopic"] = "주제 기준";
   ODBLabels["SortByBook"] = "책/주제 기준";
   ODBLabels["SortTitle"] = "정렬 순서:";
   ODBLabels["ScopeTitle"] = "검색 범위:";
   ODBLabels["MiscTitle"] = "기타 옵션:";
   ODBLabels["ApplyFilterMsg"] = "현재 설정을 기준으로 검색 결과 필터링";
   ODBLabels["CloseFilterMsg"] = "검색 필터 옵션 닫기";
   ODBLabels["FilterResultsMsg"] = "<b>다음을 기준으로 검색 결과 필터링:</b>";
   ODBLabels["FilterResultsBtn"] = "결과 필터링";
   ODBLabels["RemoveFilterBtn"] = "필터 제거";
   ODBLabels["SearchTipsBtn"] = "검색 팁";
   ODBLabels["SearchCommands"] = "명령 및 기능 제목으로 검색 제한";
   ODBLabels["SearchTitles"] = "제목에 검색어가 포함된 결과만 표시";
   ODBLabels["ExactMatchSearch"] = "검색어와 정확히 일치";
   ODBLabels["IncludeSynonyms"] = "동의어 포함 안 함";
   ODBLabels["DisplayFunctionsTitle"] = "다음에 대한 명령/기능 리스트 ";
   ODBLabels["DisplaySynonymsTitle"] = "다음에 대한 정의된 동의어 리스트 ";
   ODBLabels["DisplaySynonymsFeedback1"] = "추가 동의어 정의를 추가하시겠습니까? 당사로 ";
   ODBLabels["DisplaySynonymsFeedback2"] = "피드백 보내기";
   ODBLabels["DisplaySnippets"] = "결과에 텍스트 조각 표시";
   ODBLabels["DisplayCloseList"] = "리스트 닫기";
   ODBLabels["DisplayShowList"] = "(리스트 표시)";
   ODBLabels["DisplaySynonyms"] = "동의어 리스트 보기";
   ODBLabels["DisplayKeywords"] = "검색 키워드 리스트 보기";
   ODBLabels["IncludeVariants"] = "변형 포함(.*키워드.*)";
   ODBLabels["IncludedSynonyms"] = "이 검색에 포함된 동의어(녹색으로 강조 표시):\n";
   ODBLabels["Persistence"] = "이러한 설정은 이 브라우저 세션에 대해서만 일시적입니다.\n";
   ODBLabels["DisplaySnippets"] = "검색/색인 조각을 표시합니다.\n";
}

function MGCSearchMessages()
{
   SearchMessages = {};
   SearchMessages.QSPrompt = "이 문서 검색";
   SearchMessages.QSBasic = "현재 문서에서 키워드 검색을 수행합니다.";
   SearchMessages.QSPrevTip = "검색어가 포함된 이전 주제";
   SearchMessages.QSNextTip = "검색어가 포함된 다음 주제";
   SearchMessages.NoSearchResults = "결과가 없습니다.";
   SearchMessages.Searched4Begin = "다음에 대해 검색했음 ";
   SearchMessages.Searched4End = "필요한 것을 찾을 수 없습니까? 동일한 검색을 다음으로 제출 ";
   SearchMessages.SearchedShowing = " 결과 ";
   SearchMessages.SearchedShowingE = " 표시.";
   SearchMessages.TurnHighlightOn = "강조 표시 켜기";
   SearchMessages.TurnHighlightOff = "강조 표시 끄기";
   SearchMessages.ApplyFilter = "필터 적용";
   SearchMessages.RemoveFilter = "필터 제거";
}

function MGCHelpTopicTitles()
{
   HelpTopicTitle = {};
   HelpTopicTitle.Tip = "다음에 대한 팁";
   HelpTopicTitle.Search = "검색 팁";
   HelpTopicTitle.Nav = "탐색";
   HelpTopicTitle.QuickHelp = "빠른 도움말";
   HelpTopicTitle.Print = "인쇄";
   HelpTopicTitle.Settings = "브라우저 설정";
   HelpTopicTitle.Feedback = "문서에 대한 피드백 보내기";
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

    e = document.getElementById("FdbackLnk");

    // Feedback link not present for SIEMENS_OEM
    if(e != null) {
      e.firstElementChild.setAttribute('title', Button.Titles["feedback"]);
    }

    e = document.getElementById("FeedbackSpan");
    if(e != null) {
      e.innerText = Button.Text["feedback"];
    }

    e = document.getElementById("manuals_button");
    e.setAttribute('title', Button.Text["title"]);
    e = document.getElementById("MoreSpan");
    e.innerText = Button.Text["ihub"];

    e = document.getElementById("PDFLnk");
    e.firstElementChild.setAttribute('title', Button.Titles["pdf"]);

    e = document.getElementById("PrintTopic");
    e.setAttribute('title', Button.Titles["print"]);
}

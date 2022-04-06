// ===============================================
// Copyright 2005-2017 Mentor Graphics Corporation
//
//    All Rights Reserved.
//
// THIS WORK CONTAINS TRADE SECRET
// AND PROPRIETARY INFORMATION WHICH IS THE
// PROPERTY OF MENTOR GRAPHICS
// CORPORATION OR ITS LICENSORS AND IS
// SUBJECT TO LICENSE TERMS.
// ===============================================

// define global variables
var mVersion = "4.2";                    // InfoHub Version
var mInfohubLook = "MGC";                // MGC look+feel
var mURL = location.href;                // current URL
var mInfoHub = "mgc_ih";                 // default infohub
var mInfoHubName = "Mentor Graphics";    // default InfoHub name
var mReleaseName = "";                   // Release name
var mCurrentTab = 0;                     // used to keep track of current tab
var mTabName = "docs";                   // name of default tab to display on load
var mRedirectURL = "https://support.sw.siemens.com/infohub";  // location of redirect utility
var mRedirectDataURL = "";               // location of development data files for redirect utility to use
var mbWebAccess = true;                  // set to true if internet access is available
var mbLibListLoaded = true;              // flag indicating whether LibList.js loaded properly
var mCookiePath = "";                    // path to store with cookie (derived from URL)
var mbCookiesEnabled = null;             // cached result of test for cookies being enabled
var mMyDocsCookie = "MGC_mydoclist";     // name of cookie used to store My Docs list
var mTextCookie = "MGC_IHTextSize";      // name of cookie used to store user text-size preference
var mTextSize = null;                    // cached text size preference (copied from cookie)
var mbLocalSearchDisabled = false;       // set to true if Local Search is disabled
var mbSNetSearchDisabled = false;        // set to true if Support Center Search is disabled
var mSearchWords = "";                   // stores the last used search words
var mSearchScope = "";                   // stores the last used search scope
var mbSearchDirty = false;               // flag as to whether user has modified search box
var mbSearchListDirty = false;           // flag as to whether user has changed search scope list selection
var mbShowFilter = false;                // flag for showing search results filter
var mOpenWin;                            // pointer to opened window
var mbMyDocsPrompt = false;              // flag as to whether my docs prompt has been shown
var mMaxListSize = 7;                    // default maximum size for doclists
var mbShowKanjiSNet = false;             // show/hide kanji supportnet search scope
var mKanjiSNetText = "";                 // text to use for kanji supportnet search scope
var mbShowSingleIH = true;               // flag to auto-redirect to single IH scope
var mbShowCommunities = false;           // flag to enable/disable Communities entry in mgc_ih scope
var mbUseInstalledIhubs = false;         // flag to determine if ihublist_installed.js loaded
var mHandle = "mgc_html_help";           // default book handle
var mPreviousHash = "";                  // last known value of location.hash
var mSidebarFraction = .26;              // default percentage width of sidebar
var mMaxSidebarFraction = .4;            // maximum percentage width of sidebar
var mbDataLoaded = false;                // flag used to determine if search data is loaded
var mbIncrementalLoad = false;           // flag for incremental loading of data files
var BookData = {};                       // object containing all book data
var DataFiles = [];                      // array of book data files to be loaded
var AllSearchResults = [];               // array of search results data
var AllSynonyms = []                     // array of synonyms used for search
var mydoclist_cookie = ""                // variable to store content of mydoclist - used for browser that can't store cookies
var SearchData = [];
var SearchFilter = {};
var SearchOptions = null;
var LinkHoverText = "Links to content on external web site. Not part of local installed content.";
var CustomerJS = "";
var EnableKanjiSupportNetBool = false;
var KanjiSearchText    = "";             // tooltip override variables for kanji supportnet
var KanjiSearchTextAll = "";
var IHTab_Olh, IHTab_Flow, IHTab_Support, IHTab_Training, IHTab_Beta, IHTab_Custom, IHTab_Search;
var IHTabs = null;
var IHList = [];
var IHDoclistCount = 0;
var IH = window.self;
var IHFrame = IH;
var MGCFrame = IH;
var MGCTreeLoc = "";
var popupStatus = 0;
var popupDiv = "";
var pdflinkPopupCookie = "MGC_pdflink_noprompt";
var OpenPdfUrl = "";
var TotalResultNumber = 0;
window.name = "IHFrame";

BrowserCheck();
BrowserCSS();
CreateInfoHubData();

$(document).ready( function() {
    // if LibList.js didn't load, populate mLibraryList with the default mgc_html_help manual
    if ( typeof mLibraryList == "undefined" || mLibraryList.length < 1 ) {
        mLibraryList = [];
        mLibraryList.push(["Mentor Graphics Documentation System","mgc_html_help"] );
        mbLibListLoaded = false;
    } else if(mLibraryList.length >= 1){
        //Remove registered trademark, service mark, and trademark symbols.
        for (var i=0; i < mLibraryList.length; i++){
            mLibraryList[i][0] = mLibraryList[i][0].replace(/\u00AE/g, '');
            mLibraryList[i][0] = mLibraryList[i][0].replace(/\u2122/g, '');
            mLibraryList[i][0] = mLibraryList[i][0].replace(/\u2120/g, '');
        }
        //Sort Array alphebetically
        mLibraryList.sort(SortAscendingMultiArray);
    }

    CreateBookData();
    CreateCustomTab();

    // Hide InfoHubs "tab" and populate IHList for sidebar
    IHTab_InfoHubs.fVisible( false );
    for ( var i=0; i < IHTab_InfoHubs.mEntries.length; i++ ) {
        for ( var j=0; j < IHTab_InfoHubs.mEntries[i].mItems.length; j++ ) {
            for ( var k=0; k < IHTab_InfoHubs.mEntries[i].mItems[j].mItems.length; k++ ) {
                IHList[IHList.length] = IHTab_InfoHubs.mEntries[i].mItems[j].mItems[k];
            }
        }
    }

    // add My Docs and All Docs scopes
    IHList[IHList.length] = "My Document List@@mydoc_ih";
    IHList[IHList.length] = "All " + mReleaseName + " Installed Documents@@mgc_ih";
    
    // prepare Search Results tab
    IHTab_Search.fVisible( true );
    var Entry = new TabEntry_Object();
    Entry.fAddHTML( '<div id="search_results"></div>' );
    IHTab_Search.fAddEntry( Entry );
    if ( GetDefaultTabName() != "search" ) {
        IHTab_Search.fVisible( false );
    }

    // determine base path to htmldocs
    MGCTreeLoc = location.href.split("#")[0];
    // if docs are web-served, index.html may not be part of the path
    if( /index\.html/.test(MGCTreeLoc) ) {
        MGCTreeLoc = MGCTreeLoc.replace("/index.html","/htmldocs");
    } else {
        MGCTreeLoc = MGCTreeLoc+"htmldocs"
    }

    if ( mReleaseName ) {
        $("#InfoHub_title").append('<p class="supportLine">Support for ' + mReleaseName + '</p>');
    }
    
    // build array of data files to load
    for ( var MaxIndex = mLibraryList.length, Index = 0 ; Index < MaxIndex ; Index++ ) {
        var handle = mLibraryList[Index][1];
        if ( DataFiles.length < 1 ) {
            // make sure first reference we push is actually a html file, not a pdf
            if ( mLibraryList[Index].length == 2 || (mLibraryList[Index].length == 3 && mLibraryList[Index][2] == "html") ) {
                DataFiles.push( GetDataFilePath(handle) );
            }
        } else if ( mLibraryList[Index].length == 2 || (mLibraryList[Index].length == 3 && mLibraryList[Index][2] == "html") ) {
            DataFiles.push( GetDataFilePath(handle) );
        }
    }
    if ( $.browser.msie && $.browser.version == "7.0" ) {
        mbIncrementalLoad = true;
    }

    mPreviousHash = location.hash;
    if ( mPreviousHash ) {
        ParseURLParams();
    } else {
        LoadDefaultInfoHub();
    }

    // enforce minimum sidebar width
    var minWidth = parseInt($("#sidebar").css("min-width"));
    if ( minWidth == $("#sidebar").width() ) {
        $("#main").css("left", minWidth + "px");
        $("#header").css("left", minWidth + "px");
    }
    
    if( EnableKanjiSupportNetBool ) {
        EnableKanjiSupportNetHelper(EnableKanjiSupportNetBool);
    }
    
    setupPopupEvents();

    // bind click/dblclick events for My Docs List
    $("#mydocmoveright").click( function() {
        AddMyDocs();
    });
    $("#alldocsdoclist").dblclick( function() {
        AddMyDocs();
    });
    $("#selecteddoclist").dblclick( function() {
        $("#selecteddoclist option:selected").each( function() {
            $(this).remove();
        });
    });
    $("#mydocmoveleft").click( function() {
        $("#selecteddoclist option:selected").each( function() {
            $(this).remove();
        });
    });
    
    $("#prefsLink").click( function() {
        $("#prefsPopup").css("display", "block");
        if ( GetCookie("MGC_preferences") == "true" ) {
            $("#pref_promptclose").prop("checked", true);
            $("#pref_promptclose").next().addClass("checkbox_selected");
        } else {
            $("#pref_promptclose").prop("checked", false);
            $("#pref_promptclose").next().removeClass("checkbox_selected");
        }
        loadPopup("#prefsPopup");
        setupPopupEvents("#prefsPopup");
        return false;
    });
    
    $("#pdflinkPopup .ok_button").click( function() {
        cookieText = $("#pdflink_noprompt").prop("checked") ? "true" : "false";
        SetCookie(pdflinkPopupCookie, cookieText);
        disablePopup();
        OpenWin(OpenPdfUrl);
    });
    
    $("#pdflinkPopup .cancel_button").click( function() {
        disablePopup();
    });

    $("#pdflinkPopup .popupClose").click(function(){
        disablePopup();
    });

    $("#dragbar").mousedown( function(e) {
        e.preventDefault();
        $("body").css("cursor", "col-resize");
        var minWidth = parseInt($("#sidebar").css("min-width"));
        $(document).mousemove( function(e) {
            // check for appropiate width on both sides. 100px and 60% of the page should be good enough.
            // 100px is the size of the mentor graphics logo.
            var screenPercent =  (e.pageX+2)/$(document).width();
            var screen_width = e.pageX+2;
            if ( (e.pageX > minWidth) && (screenPercent < mMaxSidebarFraction) ) {
                screenPercent = screenPercent.toPrecision(2)*100
                $("#sidebar").css("width",screen_width + "px");
                $("#main").css("left", screen_width + "px");
                $("#header").css("left", screen_width + "px");
            }
        })
    });

    $(document).mouseup( function() {
        $("body").css("cursor", "default");
        $(document).unbind("mousemove");
    });
       
    $(window).resize( function(e) {
        document_width = $(document).width();
        sidebar_width = $("#sidebar").width();
        var minWidth = parseInt($("#sidebar").css("min-width"));
        if ( sidebar_width  == minWidth && document_width * mSidebarFraction < minWidth ) {
            $("#main").css("left", minWidth + "px");
            $("#header").css("left", minWidth + "px");
        } else if ( sidebar_width >= minWidth && document_width * mSidebarFraction > minWidth ) {
            $("#main").css("left", sidebar_width + "px");
            $("#header").css("left", sidebar_width + "px");
        }
    });

    $("#search_list input").click( function() {
        mbSearchListDirty = true;
        mSearchScope = $("#search_list input:checked").val();
        UpdateSearchForm();
    });

    // use onhashchange function if available
    if ( window.onhashchange !== undefined ) {
        window.onhashchange = HashChanged;
    } else {
        // for older browsers, check for hash change every 100 miliseconds
        window.setInterval( function() {
            if ( location.hash != mPreviousHash ) {
                HashChanged();
            }
        }, 100);
    }

    window.onbeforeunload = function() {
        if ( typeof IH.DataFilesLength != "undefined" && GetCookie("MGC_preferences") != "true" ) {
            return "Tip: If you close or navigate away from this InfoHub, all cached search data must be reloaded next time you search. To disable this dialog, click on the Preferences link in the footer of this InfoHub.";
        }
    }

    if ( ! mbLibListLoaded ) {
        var msg = "The mgc_ih/js/LibList.js file does not exist because DocMerge has not been run on this InfoHub. ";
        msg += "Search will not function. However, you can continue to create and test the content layout of the InfoHub scopes without running DocMerge.";
        alert(msg);
    }
});

function HashChanged()
{
    if ( decodeURIComponent(mPreviousHash) != decodeURIComponent(location.hash) ) {
        mPreviousHash = location.hash;
        ParseURLParams();
    }
}

// Parse parameters from location.hash and switch scopes
function ParseURLParams()
{
    var Params = {};
    var Hash = location.hash.replace("#","");
    mURL = location.href;

    // store all hash parameters in Params object
    Hash.replace(/([^=&]+)=([^&]*)/g, function(m, key, val) {
        Params[decodeURIComponent(key)] = decodeURIComponent(val);
    });
    
    if ( Params.infohub ) {
        mInfoHub = Params.infohub;
        if ( mInfoHub == "all" ) {
            mInfoHub = "mgc_ih";
            mbShowSingleIH = false;
        }
    }
    if ( Params.tab ) {
        mTabName = Params.tab;
    }
    if ( Params.query ) {
        mSearchWords = Params.query;
        //$("#query").val(Params.query);
        mbSearchDirty = true;
    }
    if ( Params.noweb ) {
        if ( Params.noweb.toLowerCase() != "false" ) {
            mbWebAccess = false;
        }
    }

    if ( Params.query ) {
        LocalSearch( mSearchWords, mInfoHub );
    } else {
        SwitchScope( mInfoHub, mTabName );
    }
}

function CreateInfoHubData()
{
    if ( IHTabs == null ) {
        // load these objects once
        IHTab_Beta     = new TabContent_Object( "beta",     "Beta" );
        IHTab_Custom   = new TabContent_Object( "custom",   "Custom" );
        IHTab_InfoHubs = new TabContent_Object( "infohubs", "InfoHubs" );
    } else {
        // clear out existing data
        mInfoHubName = undefined;
        mProductList = undefined;
    }

    // Create InfoHub Tab objects
    IHTab_Olh      = new TabContent_Object( "docs",     "Documents" );
    IHTab_Flow     = new TabContent_Object( "flow",     "Design Flow");
    IHTab_Support  = new TabContent_Object( "support",  "Support Center QuickLinks" );
    IHTab_Search   = new TabContent_Object( "search",   "Search Results" );
    IHTab_Training = new TabContent_Object( "training", "Training" );
    // The infohubs tab is now used to define the content of the sidebar, don't include in IHTabs array
    IHTabs = [ IHTab_Olh, IHTab_Flow, IHTab_Support, IHTab_Search, IHTab_Training, IHTab_Beta, IHTab_Custom ];
}

function RefreshInfoHub()
{
    LoadScopeLinks();
    LoadTabs();
    UpdateTabPane();
    UpdateSearchForm();
}

function LoadDefaultInfoHub()
{
    if ( IHList[0].indexOf("=") != -1 ) {
        SwitchScope( IHList[0].split("=")[1], "docs" );
    } else if( IHList[0].indexOf("@@") != -1 ) {
        SwitchScope( IHList[0].split("@@")[1], "docs" );
    } else {
        SwitchScope( "mgc_ih", "docs" );
    }
}

function BrowserCheck()
{
    // if url contains ? params, replace with hash (this causes a page reload)
    if ( location.href.indexOf("?") != -1 ) location.replace( location.href.replace("?", "#") );

    // Redirect IE6 and Netscape browsers to the basic infohub
    var testver = /MSIE (\d+\.\d+);/.exec(navigator.userAgent);
    if ( testver != null && typeof(testver[1]) == "string" && parseFloat(testver[1]) <= 6.9 ) {
        location.href = "infohubs/basic.htm";
    }
    testver = /(Netscape)/.exec(navigator.userAgent);
    if ( testver != null ) {
        location.href = "infohubs/basic.htm";
    }
}

function BrowserCSS()
{
    // write text size stylesheet into document head
    document.write('<link rel="stylesheet" href="infohubs/common/style/' + GetTextSize() + '.css" id="text_ss" />');
}

function SortAscendingMultiArray( e1, e2 )
{
    return ( e1[0].toLowerCase() > e2[0].toLowerCase() ? 1 : -1 );
}


//////////////
//  Scopes  //
//////////////

// Switches to the selected InfoHub scope
function SwitchScope( infohub, tab )
{
    if ( typeof infohub == "undefined" || infohub == "" ) infohub = "mgc_ih";
    if ( typeof tab == "undefined" || tab == "" ) tab = "docs";
    IHDoclistCount = 0;

    var pageHash = "#infohub=" + infohub;
    pageHash += "&tab=" + tab;
    if ( tab == "search" ) {
        pageHash += "&query=" + mSearchWords;
    }

    // only update hash if it changed, or if IE on the file system (needed for back/foward to work)
    if ( location.hash != pageHash || ( $.browser.msie && /file:\/\//.test(location.href) ) ) {
        mPreviousHash = pageHash;
        location.hash = pageHash;
    }
    
    if ( tab == "search" ) {
        $("#query").val(mSearchWords);
        mbSearchDirty = true;
    } else if ( $("#query").val() == GetSearchPhrase(mInfoHub) ) {
        mbSearchDirty = false;
    }
    if ( mbSearchListDirty ) {
        mSearchScope = $("#search_list input:checked").val();
    }

    IH.mInfoHub = infohub;
    IH.mTabName = tab;

    CreateInfoHubData();

    // update the title
    var scopeTitle = GetScopeTitle(infohub);
    if ( scopeTitle ) {
        document.title = scopeTitle;
        mInfoHubName = scopeTitle;
    } else {
        document.title = "Infohub";
    }

    if ( mInfoHub != "mgc_ih" && mInfoHub != "mydoc_ih" ) {
        // First check to see if this is a valid infohub. We can do this by checking to see if the "handle" has a "title" defined.
        // If this function returns null, we don't have an entry in the infohub for this scope.
        if ( GetScopeTitle(mInfoHub) == null ) {
            LoadDefaultInfoHub();
        } else {
            // load doclist.js for selected scope
            GetScript( "scope_doclist", "infohubs/" + mInfoHub + "/js/doclist.js", function() {
                mCurrentTab = GetTabIndexByName(mTabName);
                RefreshInfoHub();
            });
        }
    } else {
        // mgc_ih and mydoc_ih scopes are generated dynamically
        if ( mInfoHub == "mgc_ih" ) {
            GenerateAllDocsScope();
        }
        if ( mInfoHub == "mydoc_ih" ) {
            GenerateMyDocsScope();
        }
        mCurrentTab = GetTabIndexByName(mTabName);
        RefreshInfoHub();
    }
}

// Returns the title of the scope specified by its handle
function GetScopeTitle( handle )
{
    // Sometimes we get an error when we try getting the scope title before the scope is fully loaded.
    // If this is the case, just return a null string.
    if( typeof IHList != "undefined" ) {
        for ( var i=0; i < IHList.length; i++ ) {
            var parts = IHList[i].split("@@");
            var txt = parts[0];
            var hdl = parts[1];
            if ( txt.substring(txt.length-8) == " InfoHub" ) {
                txt = txt.substring(0,(txt.length-8));
                }
            // old format was ./index.html?infohub=<infohub_ih>, parse this
            if ( hdl.indexOf("infohub=") != -1 ) {
                parts = hdl.split("infohub=");
                hdl = parts[1];
            }
            if ( handle == hdl ) {
                return txt;
            }
            // correct problem where mgc_ih is never found because we're looking for "all" and we now use the "mgc_ih" handle
            if ( handle == "all" && hdl=="mgc_ih" ) {
                return txt;
            }
        }
    }
    return null;
}

// returns array of html books in the current scope
function GetBookList()
{
    var booklist = [];
    // build list of books to search in current scope based on infohub data objects
    for ( var j = 0; j < IHTab_Olh.mEntries.length; j++ ) {
        // each document list is contained in it's own mEntries location.
        // however, sometimes text, like bulleted lists, is also stored in these variables.
        // If that's the case, and there's a list of items, we can have more than one item here.
        for ( var i = 0; i < IHTab_Olh.mEntries[j].mItems.length; i++ ) {
            // make sure that we are not trying to search lists
            if ( typeof(IHTab_Olh.mEntries[j].mItems[i].mItems) == "undefined" ) {
                continue;
            }
            // these are actually books or are *supposed* to be books. For each of these,
            // check to see if they exist in the mLibraryList.
            for ( var k = 0; k < IHTab_Olh.mEntries[j].mItems[i].mItems.length; k++ ) {
                var linkValue = IHTab_Olh.mEntries[j].mItems[i].mItems[k].split("@@");
                linkValue = linkValue[1].split(/[&&|::]+/);
                for ( var LSIndex = 0 ; LSIndex < mLibraryList.length ; LSIndex++ ) {
                    if ( mLibraryList[LSIndex][1] == linkValue[0] && ( mLibraryList[LSIndex].length == 2
                            || ( mLibraryList[LSIndex].length == 3 && mLibraryList[LSIndex][2] == "html" ) ) ) {
                        // Add handle to the array of books to be searched. Submit search after all books in this scope
                        // have been added and have been made unique.
                        booklist.push( linkValue[0] );
                        break;
                    }
                }
            }
        }
    }
    // remove any duplicate entries in booklist
    return unique(booklist);
}

// returns true/false whether the current scope is a Release Information scope
function IsReleaseScope()
{
    if ( mInfoHubName.match("Release Information") && IHList[0].match("Release Information") ) {
        return true;
    }
    return false;
}

function GetReleaseScope()
{
    if ( typeof IHList != "undefined" && IHList[0].match("Release Information") ) {
        // Sometimes we get an error when we try getting the scope title before the scope is fully loaded.
        // If this is the case, just return a null string.
        for ( var i=0; i < IHList.length; i++ ) {
            var parts = IHList[i].split("@@");
            var txt = parts[0];
            var hdl = parts[1];
            if ( txt.substring(txt.length-8) == " InfoHub" ) {
                txt = txt.substring(0,(txt.length-8));
            }
            // old format was ./index.html?infohub=<infohub_ih>, parse this
            if ( hdl.indexOf("infohub=") != -1 ) {
                parts = hdl.split("infohub=");
                hdl = parts[1];
            }
            if( txt.match("Release Information") ){
                return hdl;
            }
        }
    }
    return "";
}

// populates the list of infohub scope links in the sidebar
function LoadScopeLinks()
{
    var scopediv = document.getElementById("scope_links");
    var HTML = "";

    // load with current/default tab selected
    var tab = GetCurrentTabName();
    if ( tab == "search" || tab=="custom" || tab=="beta" ) {
        tab="docs";
    }
    // insert scope links
    for ( var i=0; i < IHList.length; i++ ) {
        var parts = IHList[i].split("@@");
        var txt = parts[0];
        var handle = parts[1];
        var cls = "scope_link";
        if ( txt.substring(txt.length-8) == " InfoHub" ) {
            txt = txt.substring(0,(txt.length-8));
        }
        // old format was ./index.html?infohub=<infohub_ih>, parse this
        if ( handle.indexOf("infohub=") != -1 ) {
            parts = handle.split("infohub=");
            handle = parts[1];
        }
        if ( mInfoHub == handle ) {
            cls = "scope_link_active";
        }
        if ( handle == "all" ) {
            handle = "mgc_ih";
        }

        HTML += '<a onclick="SwitchScope(\'' + handle + '\', \'' + tab + '\'); return false;" href="index.html#infohub=' + handle + '&tab=' + tab + '" class="' + cls + '" title="' + txt + '" >';
        // the following 3 divs are used to center the text properly in all browsers
        HTML += '<div style="display: table; height: 30px; #position: relative; overflow: hidden;">';
          HTML += '<div style=" #position: absolute; _top: 50%;display: table-cell; vertical-align: middle;">';
            HTML += '<div style="#position: relative; #top: -50%;">';
              HTML += txt;
            HTML += '</div>';
          HTML += '</div>';
        HTML += '</div>';
        HTML += '</a>';
    }
    scopediv.innerHTML = HTML;
}

function GenerateAllDocsScope()
{
    if ( mInfoHub == "mgc_ih" ) {
        // if only 1 scope, load it directly
        if ( IHList.length == 2 && mbShowSingleIH ) {
            var parts = IHList[0].split("@@");
            var handle = parts[1];
            // old format was ./index.html?infohub=<infohub_ih>, parse this
            if ( handle.indexOf("infohub=") != -1 ) {
                parts = handle.split("infohub=");
                handle = parts[1];
            }
            SwitchScope( handle, mTabName );
        }
        // populate All Local Docs entry
        IHTab_Olh.fVisible( true );
        var Entry = new TabEntry_Object( "All Locally Installed Documentation" );
        List = new List_Object("doclist");
        List.fSetMaxSize(25);
        if ( typeof mLibraryList != "undefined" && mLibraryList.length > 0 ) {
            for ( var i=0; i < mLibraryList.length; i++ ) {
                List.fAddItem( mLibraryList[i][0], mLibraryList[i][1], mLibraryList[i][2] );
            }
        }
        Entry.fAddList( List );
        IHTab_Olh.fAddEntry( Entry );
        CreateSupportNetTab();
        CreateTrainingTab();
    }
}

function GenerateMyDocsScope()
{
    cookieString = GetCookie("MGC_mydoclist").split(",");  //Parse cookie of documents belonging to this scope
    if ( cookieString == "" ) {
        cookieString = mydoclist_cookie.split(","); //backup for browsers not supporting cookies
    }

    IHTab_Olh.fVisible( true );
    var Entry = new TabEntry_Object( "My Document List" );
    Entry.fSetBodyText( "Custom list of documents for viewing and for constraining search. <br><br>" +
                        "  Note that PDF documents are not included in InfoHub searches. To search PDF-only documents, you must use the native PDF-based search capabilities." );
    var List = new List_Object("mydocs");
    List.fSetMaxSize(25);
    
    //look at cookies & read them in here?
    if(cookieString.length >= 1 && cookieString[0] != ""){
        for ( var i=0; i < cookieString.length; i++ ) {
            List.fAddItem( GetBookTitle(cookieString[i]),cookieString[i], GetPdfHtmlOnlyAttribute(cookieString[i]) );
        }
    }
    Entry.fAddList( List );
    IHTab_Olh.fReplaceEntry( Entry , 0);

    CreateSupportNetTab();
    CreateTrainingTab();
}

function MyDocsNoBooksSelected()
{
    EditList(0);
    var currentHeight = $("#mydocsPopup").height();
    $("#mydocsPopup").height(currentHeight+60);
    $('<div class="notice">No HTML documents specified in your document list.<br />Please add document(s), click Save, and then resubmit your search.</div>').insertAfter($("#mydocsPopup h1"));
}

function AddMyDocs()
{
    // Before adding a value, we need to make sure it's not a duplicate of something that already exists in the list
    $("#alldocsdoclist option:selected").each( function() {
        // proceed item by item to compare to existing list
        var valuer = $(this).val();
        var texter = $(this).text();
        var add_this_value = true;   //assume there are no duplicates at first, if there is one we'll set this value to false
        $("#selecteddoclist option").each( function() {
            if ( $(this).text() == texter ) {
                add_this_value = false;
            }
        });
        if ( add_this_value ) {
            $("#selecteddoclist").append($('<option></option>').val(valuer).html(texter));
        }
        // if there is nothing in the doclist, there can't be any duplicates, so just add the first value.
        if ( $("#selecteddoclist option").length == 0 ) {
            $("#selecteddoclist").append($('<option></option>').val(valuer).html(texter));
        }
    });
}

// centers "Edit List" popup in "My Documents" scope, then loads the popup
function EditList( Index)
{
    loadPopupInformation();
    loadPopup("#mydocsPopup");
}


////////////
//  Tabs  //
////////////

// Switches to the specified tab name
function SwitchTab( TabName )
{
    var pageHash = "#infohub=" + mInfoHub + "&tab=" + TabName;
    if ( TabName == "search" ) {
        pageHash += "&query=" + mSearchWords;
    }

    // reset doclist count for new tab
    IHDoclistCount = 0;
    for ( var i = 0; i < IHTabs.length; i++ ) {
        var tab = document.getElementById(IHTabs[i].mName);
        if ( IHTabs[i].mName == TabName ) {
            //switch to foreground tab
            mCurrentTab = i;
            tab.className = "fg_tab";
            mPreviousHash = pageHash;
            location.hash = pageHash;
        } else {
            // if tab exists, switch to background style
            if ( tab ) {
                tab.className = "bg_tab";
            }
        }
    }

    // update search field based on current tab
    if ( TabName != "custom" && TabName != "beta" && ( $(".hidden_custom").length > 0 || ! $(".search_btn").is(":visible") ) ) {
        // update highlighting on search scope
        $(".search_box").removeClass("hidden_custom");
        $(".hidden_custom").addClass("scope_link_active").removeClass("scope_link").removeClass("hidden_custom");
    } else if ( (TabName == "custom" || TabName == "beta" ) && $(".hidden_custom").length == 0 ) {
        // remove highlighting on search scope
        $(".scope_Link_Active").addClass("hidden_custom");
        $(".hidden_custom").addClass("scope_link").removeClass("scope_link_active");
        $("#search_list_container").fadeOut("slow")
        $(".search_box").addClass("hidden_custom");
    } else if ( TabName == "custom" || TabName == "beta" ) {
        $(".scope_Link_Active").addClass("hidden_custom").addClass("scope_link");
        $(".hidden_custom").removeClass("scope_link_active");
    }

    RefreshInfoHub();
}

function GetTabsHTML()
{
    var Class, Name, Title;
    var HTML = [];
    HTML.push('<table><tr><td id="tabs_td"><ul class="tabs">');
    for ( var t=0; t < IHTabs.length; t++ ) {
        if ( t == mCurrentTab ) {
            Class = "fg_tab";
        } else {
            Class = "bg_tab";
        }
        Name = IHTabs[t].mName;
        Title = IHTabs[t].mTitle;
        if ( IHTabs[t].mbVisible ) {
            HTML.push('<li class="' + Class + '" >');
            HTML.push('<a href="#infohub=' + mInfoHub + '&tab=' + Name + '" onclick="SwitchTab(\'' + Name + '\'); return false;" class="' + Class + '" id="' + Name + '">');
            HTML.push('<div style="text-align: center;">');
            HTML.push('<span>' + Title + '</span>');
            HTML.push('</div>');
            HTML.push('</a>');
            HTML.push('</li>');
        }
    }
    HTML.push('</ul></td><td><div id="resize_button">');
    HTML.push('<img src="infohubs/common/graphics/gr-txt-size.gif" alt="Text Size" />');
    HTML.push('<a title="Small Text" href="javascript:void(0);" onclick="ResizeText(\'small\');"><img width="20" height="18" alt="Small Text" src="infohubs/common/graphics/gr-txt-size-sm.gif" /></a>');
    HTML.push('<a title="Medium Text" href="javascript:void(0);" onclick="ResizeText(\'medium\');"><img width="21" height="18" alt="Medium Text" src="infohubs/common/graphics/gr-txt-size-md.gif" /></a>');
    HTML.push('<a title="Large Text" href="javascript:void(0);" onclick="ResizeText(\'large\');"><img width="19" height="18" alt="Large Text" src="infohubs/common/graphics/gr-txt-size-lg.gif" /></a>');
    HTML.push('</div></td></tr></table>');
    return HTML.join("\n");
}

// Returns the index of the default tab to display (0 to n-1)
function GetDefaultTab()
{
    var Default = mTabName;
    var First = 0;

    for ( var t=0; t < IHTabs.length; t++ ) {
        if ( ! (IHTabs[t].mbVisible) ) {
            if ( t == First ) {
                First = t+1;
            }
        } else {
            if ( IHTabs[t].mName == Default ) {
                return t;
            }
        }
    }
    // None specified, default to first tab
    return First;
}

// Returns the name of the default tab to display
function GetDefaultTabName()
{
    return IHTabs[GetDefaultTab()].mName;
}

// Returns the name of the current tab
function GetCurrentTabName()
{
    return IHTabs[mCurrentTab].mName;
}

// Returns the index of the current tab (0 to n-1)
function GetTabIndexByName( name )
{
    for ( var i = 0; i < IHTabs.length; i++ ) {
        if ( (IHTabs[i].mName == name && IHTabs[i].mbVisible == true)||(name == "search" && IHTabs[i].mName == name) ) {
            return i;
        }
    }
    return 0;
}

function LoadTabs()
{
    $("#tabs").html( GetTabsHTML() );
    CustomTabHeader();
    //if IE, we need to do a hack to get the back part of the last tab displaying.
    if ( $.browser.msie ) {
        $("ul.tabs li:last div").width( $("ul.tabs li:last div").width() + 10 );
    }
}

// Called when the tab gets resized
function Tab_OnResize()
{
    var Lists = document.getElementsByName("doclist");
    for ( var i=0; i < Lists.length; i++ ) {
        Doclist_OnChange(i);
    }
}

// update HTML for current tab contents
function UpdateTabPane()
{
    var TabName = GetCurrentTabName();
    if ( TabName == "search" ) {
        // load data files and initiate search
        LoadSearchData();
    } else {
        $("#IHTabPane").html( IHTabs[mCurrentTab].fGetHTML() );
        Tab_OnResize();
        if ( TabName == "custom" ) {
            $("#hidecustomtab").click( function() {
                $("#custom").hide();
                SetCookie("MGC_showcustomtab", "false");
                IHTabs[IHTabs.length-1].mbVisible = false;
                SwitchTab("docs");
            });
        }
        if ( $("#IHTabPane .productList").length == 0 && typeof mInfoHubName != "undefined" && typeof mProductList != "undefined" && TabName != "custom" && TabName != "beta" ) {
            $("#tabTable").append('<tr><td><div class="productList" ><b>' + mInfoHubName + ' scope supports these products</b>: ' + mProductList + '</div></td></tr>');
        } else if ( $("#tabTable .productList").length == 0 && mInfoHub == "mgc_ih" && TabName != "custom" &&  TabName != "beta" ) {
            $("#tabTable").append('<tr><td><div class="productList"><b>All ' + mReleaseName + ' Installed Documents scope lists all currently installed documents.</b></div></td></tr>');
        }
    }
}

function CustomTabHeader()
{
    var tabName = GetCurrentTabName();
    if ( tabName == "custom" || tabName == "beta" ) {
        $("#query").hide();
        $(".search_box").css("background-image", "url('infohubs/common/graphics/bg-search_x.png')");
        $(".search_box").attr("title", "Note: Content linked from the Custom tab is not searchable from the InfoHub.");
        $(".search_btn").hide();
        $("#icon-replacement img").attr("src", "infohubs/common/graphics/go_search_x.png");
        $("#icon-replacement").show();
        $("#search_list_container").fadeOut("slow");
        $(".scope_Link_Active").addClass("hidden_custom");
        $(".scope_Link_Active").addClass("scope_link");
        $(".hidden_custom").removeClass("scope_link_active");
    } else if ( $("#icon-replacement img").attr("src") != "infohubs/common/graphics/go_search_spin.gif" ) {
        $("#query").show();
        $(".search_box").css("background-image", "url('infohubs/common/graphics/bg-search.png')")
        $(".search_box").attr("title","");;
        $(".search_btn").show();
        $("#icon-replacement img").attr("src", "infohubs/common/graphics/go_search_spin.gif");
        $("#icon-replacement").hide();
        $("#search_list_container").fadeIn("slow");
    }
}

function CreateCustomTab()
{
    if ( typeof IHTab_Custom.customerSpecified == "undefined" ) {
        var customTabCookie = GetCookie("MGC_showcustomtab");
        if ( customTabCookie == "false" ) {
            //don't show the custom tab
            IHTabs[IHTabs.length-1].mbVisible = false;
        } else {
            //write HTML directly into the custom tab...   this needs to be done here so it's copied over to all the scopes, not just one.
            IHTab_Custom.fSetTitle( "Custom Info" );
            Entry = new TabEntry_Object();             // Sets title for entry
            var browsercookiewarning = "";
            if ( ! CookiesEnabled() ) {
                browsercookiewarning = CookieWarningMessage();
            }
            var HTML = "<h2>Populate this Tab with Your Content</h2>" + browsercookiewarning + "<p>The Custom tab enables you to "
                + "customize the InfoHub with your own content. Choose what you want to show on the custom tab:</p><ul><li class=\"listbull\"><p class=\"listbull\"> "
                + "Links to your internal web sites</p></li><li class=\"listbull\"><p class=\"listbull\">List of your design-related documents</p></li>"
                + "<li class=\"listbull\"><p class=\"listbull\">Links to external web sites</p></li></ul>"
                + "<p><b>Note:</b> Content listed or linked to from the Custom tab is not searchable from the InfoHub</p>"
                + "<div id=\"hidecustomtab_box\"><p> To hide this Custom tab, click the Hide Custom Tab button:</p>"
                + "<div id=\"hidecustomtab\" class=\"textButtons\"><span>Hide Custom Tab </span></div>"
                + "<p>To create your own Custom tab after you have hidden it, click the \"Custom Tab\" link in the footer of the InfoHub for instructions.</p></div>";
            Entry.fAddHTML(HTML);
            IHTab_Custom.fAddEntry( Entry );
            IHTab_Custom.mbVisible = true;
        }
    }
}

function CreateSupportNetTab()
{
    if ( IHTab_Support.mEntryCount == 0 && (mInfoHub == "mydoc_ih" || mInfoHub == "mgc_ih") ) {
        IHTab_Support.fVisible( true );
        Entry = new TabEntry_Object( "Technical Support & Downloads" );
        Entry.fAddLink( "Access Support Center", "microsite" );
        Entry.fAddLink( "Sign up for CustomerInsight Newsletter", "supportpro" );
        IHTab_Support.fAddEntry( Entry );

        // only add Communities entry if variable set to true
        if ( ( typeof mbShowCommunities == "boolean" && mbShowCommunities ) ||
             ( typeof mbShowCommunities == "string" && mbShowCommunities.toLowerCase() == "true" ) ) {
            Entry = new TabEntry_Object( "Communities" );
            Entry.fAddLink( "Participate in Mentor Graphics Communities", "community", "A place to learn, share, and network with other designers." );
            IHTab_Support.fAddEntry( Entry );
        }
        
        Entry = new TabEntry_Object( "Contact Us" );
        Entry.fAddLink( "Send feedback on the documentation", "feedback" );
        Entry.fAddLink( "Visit mentor.com", "mentor" );
        IHTab_Support.fAddEntry( Entry );
    }
}

function CreateTrainingTab()
{
    if ( IHTab_Training.mEntryCount == 0  && (mInfoHub == "mydoc_ih" || mInfoHub == "mgc_ih") ) {
        IHTab_Training.fVisible(true);

        Entry = new TabEntry_Object( "Training" );
        Entry.fAddLink( "View available training courses", "training" );
        IHTab_Training.fAddEntry( Entry );

        Entry = new TabEntry_Object( "Videos" );
        Entry.fAddLink( "View How-To and Tutorial videos on Support Center", "animations", "A list of videos available on Support Center." );
        IHTab_Training.fAddEntry( Entry );
    }
}


/////////////
//  Links  //
/////////////

// sends the specified link tag to the InfoHub redirect page
function GotoLink( Link )
{
    var url = GetLinkURL( Link );
    if ( Link.indexOf("javascript:") == 0 ) {
        // detect javascript links and run in current window
        location.href = Link;
        return;
    }
    OpenWin(url);
}

// return the full url for the specified link identifier
function GetLinkURL( Link )
{
    var url = mRedirectURL;
    if ( Link.indexOf("javascript:") == 0 ) {
        url = Link;
    } else if ( Link.indexOf("/") != -1 ) {
        // link contains slash, treat as URL
        url = Link;
    } else {
        url += "?link=" + Link;
        if ( typeof mInfoHub != "undefined" && mInfoHub.length > 0 ) {
            url += "&infohub=" + mInfoHub;
        }
        if ( typeof mInfoHubName != "undefined" && mInfoHubName.length > 0 ) {
            url += "&name=" + mInfoHubName;
        }
        if ( typeof mReleaseName != "undefined" && mReleaseName.length > 0 ) {
            url += "&release=" + mReleaseName;
        }
        if ( typeof mFlowName != "undefined" && mFlowName.length > 0 ) {
            url += "&flow=" + mFlowName;
        }
        if ( typeof(mRedirectDataURL) != "undefined" && mRedirectDataURL.length > 0 ) {
            url += "&data=" + mRedirectDataURL;
        }
    }
    return url;
}

// safely open window, catch blocked popups
function OpenWin( url )
{
    if ( window.open && url ) {
        try {
            mOpenWin = window.open( url, "_blank" );
        } catch( err ) {
            alert( "A popup blocker has prevented opening this link:\n\n" + url );
        }
    }
}

// Open the doc that is selected in the specified listbox
function OpenDoc( ListIndex )
{
    var Select = document.getElementById( "doclist" + ListIndex );
    if ( Select.value && Select.value != "none" ) {
        var Value = Select.value;
        if ( Value.indexOf("::") != -1 ) {
            // if type specified, open appropriately
            var Parts = Value.split("::");
            switch ( Parts[1].toLowerCase() ) {
            case "html":
                OpenHtmlDoc( Parts[0] );
                break;
            case "pdf":
                OpenPdfDoc( Parts[0] );
                break;
            case "infohub":
                location.href = Parts[0];
                break;
            default:
                if ( Parts[0].indexOf("&&") != -1 ) {
                    // topic specified, but not valid type, so default to html
                    OpenHtmlDoc( Parts[0] );
                } else {
                    OpenWin( Parts[0] );
                }
            }
        } else if (Value.indexOf("&&") != -1 ) {
            // Topic specified, but not type, so default to html
            OpenHtmlDoc( Value );
        } else {
            // No Type, so just open
            OpenWin( Value );
        }
    }
}

// Open the doc that is selected in the specified listbox, preferrably PDF
function PrintDoc( Index )
{
    var Select = document.getElementById( "doclist" + Index );
    if ( Select.value && Select.value != "none" )
    {
        var Value = Select.value;
        if ( Value.indexOf("::") != -1 ) {
            // Type specified, so check for html, otherwise use pdf
            var Parts = Value.split("::");
            if ( Parts[1].toLowerCase() == "html" ) {
                OpenHtmlDoc( Parts[0] );
            } else {
                OpenPdfDoc( Parts[0] );
            }
        } else {
            // No Type, so default to pdf
            OpenPdfDoc( Value );
        }
    }
}

// Open the doc that is selected in the specified listbox, preferrably HTML
function ViewDoc( Index )
{
    var Select = document.getElementById( "doclist" + Index );
    if ( Select.value && Select.value != "none" )
    {
        var Value = Select.value;
        if ( Value.indexOf("::") != -1 ) {
            // Type specified, so check for pdf, otherwise use html
            var Parts = Value.split("::");
            if ( Parts[1].toLowerCase() == "pdf" ) {
                OpenPdfDoc( Parts[0] );
            } else {
                OpenHtmlDoc( Parts[0] );
            }
        } else {
            // No Type, so default to html
            OpenHtmlDoc( Value );
        }
    }
}

// Open the specified PDF doc
function OpenPdfDoc( Handle )
{
    var Topic = null;
    if ( typeof Handle == "string" && Handle != "" ) {
        if ( Handle.indexOf("&&") != -1 ) {
            // split into handle & topic
            var Parts = Handle.split("&&");
            Handle = Parts[0];
            Topic = Parts[1];
        }
        
        if ( Topic ) {
            // allow alphanumeric, underscore, and hyphen characters; replace everything else with periods
            Topic = "#M8.newlink." + Topic.replace(/[^A-Za-z0-9_\-]/, " ").replace(/ /g, ".")
            OpenPdfPopup("pdfdocs/" + Handle + ".pdf" + Topic);
        } else {
            OpenPdfPopup("pdfdocs/" + Handle + ".pdf");
        }
    }
}

// Load PDF link popup dialog unless cookie set
// Remove the popup -- cookies don't work anyway, when docs are opened from the file system.
function OpenPdfPopup( url )
{
    OpenWin(url);
    /*
    if ( GetCookie(pdflinkPopupCookie) != "true" ) {
        OpenPdfUrl = url;
        loadPopup("#pdflinkPopup");
    } else {
        OpenWin(url);
    }
    */
}

// Open the specified HTML doc
function OpenHtmlDoc( Handle )
{
    var Topic = null;
    var IHub = "ihub=" + mInfoHub;
    if ( typeof(Handle) == "string" && Handle != "" ) {
        if ( Handle.indexOf("&&") != -1 ) {
            // split into handle & topic
            var Parts = Handle.split("&&");
            Handle = Parts[0];
            Topic = Parts[1];
        }
        if ( Topic ) {
            // allow alphanumeric, underscore, and hyphen characters; strip everything else
            Topic = Topic.replace(/[^A-Za-z0-9_\-]/g, "");
            OpenWin("htmldocs/mgchelp.htm#context=" + Handle + "&topic=" + Topic + "&" + IHub);
        } else {
            OpenWin("htmldocs/mgchelp.htm#context=" + Handle + "&" + IHub);
        }
    }
}

function ToggleExpContentsById( ID )
{
    if ( typeof(ID) != "undefined" ) {
        var Contents = document.getElementById( "ExpContents_" + ID );
        if ( typeof Contents != "undefined" ) {
            if ( Contents.style.display == "none" ) {
                Contents.style.display = "block";
            } else {
                Contents.style.display = "none";
            }
        }
        Button = document.getElementById( "ExpButton_" + ID );
        if ( typeof Button != "undefined" ) {
            if ( Contents.style.display == "none" ) {
                Button.innerHTML = "<input type=\"image\" src=\"../graphics/show_tasks.png\" onClick=\"ToggleExpContentsById('"+ ID + "')\" onMouseOver=\"this.src='../graphics/show_tasks_h.png';\" onMouseOut=\"this.src='../graphics/show_tasks.png';\" class=\"showtask\" >";
            } else {
                Button.innerHTML = "<input type=\"image\" src=\"../graphics/hide_tasks.png\" onClick=\"ToggleExpContentsById('"+ ID + "')\" onMouseOver=\"this.src='../graphics/hide_tasks_h.png';\" onMouseOut=\"this.src='../graphics/hide_tasks.png';\" class=\"showtask\" >";
            }
        }
    }
}

function Doclist_OnChange( ListIndex )
{
    var Select  = document.getElementById("doclist"+ListIndex);
    var BtnHTML = document.getElementById("btnHTML"+ListIndex);
    var BtnPDF  = document.getElementById("btnPDF"+ListIndex);
    var PDFButtonsExist = $(BtnPDF).length > 0 ? true : false;

    if ( BtnHTML ) {
        if ( Select.value && Select.value != "none" ) {
            var Value = Select.value;
            if ( Value.indexOf("::") != -1 ) {
                switch( Value.split("::")[1] ) {
                case "pdf":
                    BtnHTML.onclick = function(){return false;};
                    if ( PDFButtonsExist ) {
                        $(BtnHTML).addClass("disabled");
                        BtnPDF.onclick = function(){PrintDoc(ListIndex);};
                        $(BtnPDF).removeClass("disabled");
                    }
                    break;
                case "html":
                    BtnHTML.onclick = function(){ViewDoc(ListIndex);};
                    if ( PDFButtonsExist ) {
                        $(BtnHTML).removeClass("disabled");
                        BtnPDF.onclick = function(){return false;};
                        $(BtnPDF).addClass("disabled");
                    }
                    break;
                default:
                    BtnHTML.onclick = function(){ViewDoc(ListIndex);};
                    if ( PDFButtonsExist ) {
                        $(BtnHTML).removeClass("disabled");
                        BtnPDF.onclick = function(){PrintDoc(ListIndex);};
                        $(BtnPDF).removeClass("disabled");
                    }
                }
            } else {
                //If the type of a listbox is not defined, it will be missing certain properties.
                //one of those properties is the onkeyup function. If this function is missing, then
                //we know that we're looking at a generic listbox, which should only contain URLs.
                //Since the URLs should resolve, make the Open box behavior the same as the doubleclick behavior.
                if ( BtnHTML.getAttribute('value') == "Open" ) {
                    BtnHTML.onclick = function(){OpenDoc(ListIndex);};
                } else {
                    BtnHTML.onclick = function(){ViewDoc(ListIndex);};
                }
                $(BtnHTML).removeClass("disabled");
                if ( PDFButtonsExist ) {
                    BtnPDF.onclick = function(){PrintDoc(ListIndex);};
                    $(BtnPDF).removeClass("disabled");
                }
            }
        } else {
            //if there's nothing selected, then the select box is probably empty. Make disabled.
            BtnHTML.onclick = function(){ViewDoc(ListIndex);};
            $(BtnHTML).addClass("disabled");
            if ( PDFButtonsExist ) {
                BtnPDF.onclick = function(){PrintDoc(ListIndex);};
                $(BtnPDF).addClass("disabled");
            }
        }
    }
}

// case-insenstive compare function for sorting listboxes
function SortAscendingAlpha( e1, e2 )
{
    return ( e1.toLowerCase() > e2.toLowerCase() ? 1 : -1 );
}

function SetDefaultListSize( size )
{
    if ( typeof size == "number" ) {
        mMaxListSize = size;
    }
}

function SetCustomerJS( src )
{
    if ( typeof src == "string" && src.length > 0 ) {
        GetScript("customerjs", src, RefreshInfoHub);
    }
}

// Returns Title for book specified by its handle
function GetBookTitle( handle )
{
    for ( var i = 0; i < mLibraryList.length; i++ ) {
        if ( mLibraryList[i][1] == handle ) {
            return mLibraryList[i][0];
        }
    }
}

// Checks book entries to see if the "pdf/html-only" entry is set.
// If it isn't, then return empty string.  If it is, return attribute string
function GetPdfHtmlOnlyAttribute(handle){
    for ( var i = 0; i < mLibraryList.length; i++ ) {
        if ( mLibraryList[i][1] == handle ) {
            return ( typeof mLibraryList[i][2] == "undefined" ) ? "" : mLibraryList[i][2];
        }
    }
    return "";
}

function GetTextSize()
{
    if ( ! mTextSize ) {
        if ( GetCookie(mTextCookie) != "" ) {
            mTextSize = GetCookie(mTextCookie);
        } else {
            mTextSize = "medium";
        }
    }
    return mTextSize;
}

function ResizeText( size )
{
    if ( typeof size == "string" && size.length > 0 ) {
        SetCookie( mTextCookie, size );
        mTextSize = size;
        document.getElementById("text_ss").href = "infohubs/common/style/" + size + ".css";
    }
}

function SubmitInfoHubFeedback()
{
    var url = "https://support.sw.siemens.com/doc_feedback_form"
        + "?doc_title=Infohub; Scope: " + GetScopeTitle(mInfoHub)
        + "&version\=Version: " + mVersion
        + " Release name:" + mReleaseName;
    window.open(url);
}


//////////////
//  Search  //
//////////////

function DoSearch()
{
    if ( ! mbSearchDirty ) return;
    var q = $("#query");
    q.val( q.val().replace(/^\s+|\s+$/g,"") );
    if ( ! q.val() ) return;

    var sel = $("#search_list input:checked");
    if ( sel.val() == "supportnet" ) {
        if ( mbSearchDirty ) {
            SNSearch( "top" );
        }
    } else if ( sel.val() == "supportnet_ja" ) {
        if ( mbSearchDirty ) {
            SNKanjiSearchV3( "top" );
        }
    } else {
        mbSearchDirty = true;
        LocalSearch();
    }
}

// performs a search of local HTML documentation
function LocalSearch( query, scope )
{
    // get query from input field if arg not specified
    if ( typeof query == "undefined" ) query = $("#query").val();
    
    // apply filter to search words, then update input field
    mSearchWords = applyWordFilter( query );
    $("#query").val( mSearchWords );

    // switch scope/tab will initiate search
    if ( typeof scope != "undefined" ) {
        // switch to scope if arg specified
        SwitchScope( scope, "search" );
    } else {
        // otherwise just switch tabs
        IHTab_Search.fVisible( true );
        LoadTabs();
        SwitchTab("search");
    }
}

function SearchInfoHub( bFilter )
{
    var booklist = [];
    AllSearchResults = [];
    AllSynonyms = [];

    // define SearchOptions for MGCExecuteSearch
    if ( ! SearchOptions || bFilter ) {
        SearchOptions = {
            include_synonyms: true,
            exact_match: false,
            infohubs: true,
            show_topic_titles: false
        };
        if ( $("#exact_match").prop("checked") ) {
            SearchOptions.exact_match = true;
        }
        if ( $("#synonymns").prop("checked") ) {
            SearchOptions.include_synonyms = false;
        }
        if ( $("#show_topic_titles").prop("checked") ) {
            SearchOptions.show_topic_titles = true;
        }
    }

    // remove any duplicate words in the synonyms/search query
    var SearchWordArray = mSearchWords.split(" ");
    var SearchWordsTemp = [];
    for ( var element in SearchWordArray ) {
        if ( SearchWordArray[element] != "" ) {
            SearchWordsTemp.push( SearchWordArray[element] );
        }
    }
    SearchWordArray = unique(SearchWordsTemp);
    
    // Based on feedback, users are not seeing the results they expect when they initially load up the infohub
    // and search the Release Information scope. To solve this, if the user is searching a Release Information scope,
    // and it is the first in the list, then the default behavior should be to search all docs.
    // to do this, we need to modifiy the IHTab_Olh object to trick the search into including all documents into the search.
    var AllDocsEntry, AllDocsCount;
    if ( IsReleaseScope() ) {
        var Entry = new TabEntry_Object( "All Locally Installed Documentation" );
        List = new List_Object("doclist");
        if ( typeof mLibraryList != "undefined" && mLibraryList.length > 0 ) {
            for ( i=0; i < mLibraryList.length; i++ ) {
                List.fAddItem( mLibraryList[i][0], mLibraryList[i][1], mLibraryList[i][2] );
            }
        }
        Entry.fAddList( List );
        AllDocsEntry = IHTab_Olh.mEntries;
        AllDocsCount = IHTab_Olh.mEntryCount;
        IHTab_Olh.mEntries = [Entry];
    }

    // if My Docs scope and no books defined, present the user with popup
    if ( typeof IHTab_Olh.mEntries[0].mItems[0].mListType  != "undefined"
            &&  IHTab_Olh.mEntries[0].mItems[0].mListType  == "mydocs"
            &&  IHTab_Olh.mEntries[0].mItems[0].mItemCount == 0 ) {
        MyDocsNoBooksSelected();
        return;
    }

    // get list of books in current scope
    booklist = GetBookList();
    for( var idx = 0; idx < booklist.length; idx++ ) {
        MGCExecuteSearch( booklist[idx], SearchWordArray, SearchOptions );
    }

    // sort results into an ordered list
    AllSearchResults.sort(compareTotals);
    LibResults = "";
    
    if ( IsReleaseScope() ) {
        // restore release scope entries
        IHTab_Olh.mEntries = AllDocsEntry;
        IHTab_Olh.mEntryCount = AllDocsCount;
    }
}

function DisplaySearchResults()
{
    // Generate formatted list of all hits
    var LibResults = "";
    var ResultCount = 0;
    var ResultBody = GenerateResultBody( ResultCount, LibResults, 0, 50 );
    LibResults = ResultBody.LibResults;
    ResultCount = ResultBody.ResultCount;
    IH.TotalResultNumber = ResultBody.totalResultNumber;

    // if search successful, generate html for search results
    if ( LibResults ) {
        LibResults = GenerateResultsHead(ResultBody.totalResultNumber) + LibResults;
        LibResults += GenerateResultsFooter();
    } else {
        LibResults = GetNoSearchResultsPage();
    }

    // refresh page by updating content
    $("#IHTabPane").html(LibResults);
}

// Create search result table head with filter options, text telling what term was searched for, and # of results
function GenerateResultsHead( ResultCount )
{
    // get correct formatting for the search scope description
    var scopeText = "&nbsp;Search results ";
    if ( mInfoHub == "mgc_ih" || IsReleaseScope() ) {
        scopeText += "from all documents in the <b>" + mReleaseName + "</b> release.";
    } else {
        scopeText += "limited to the <b>" + mInfoHubName + "</b> scope.";
    }

    // generate "synonyms include" text, if necessary
    var synonymText = "";
    var synonymArray = unique(AllSynonyms);
    if ( synonymArray.length > 0 ) {
        synonymText = '<span class="synonym_string"> including synonyms <span class="green_highlight">&nbsp;';
        synonymText += synonymArray.join('&nbsp;</span>,&nbsp;<span class="green_highlight">&nbsp;') + ' </span></span>';
    }

    var resultRange = "x-x";
    if ( ResultCount == 0 ) {
        resultRange = "0";
    }

    var thead = '<table class="SearchResults"><thead>'
        + '<tr><td colspan="2" style="height:27px;"><span id="SearchTitle">Search Results </span>'
          + '<div id="search_tips"><a href="htmldocs/mgchelp.htm#context=mgc_html_help&amp;topic=mgc_help_008" '
          + 'onclick="OpenHtmlDoc(\'mgc_html_help&&mgc_help_008\'); return false;" target="_blank"><span>Search Tips</span></a></div>'
          + '<div id="advanced_search_button"><span id="advanced_search_button_text">Filter Results</span></div>'
        + '</td></tr>'
        + '<tr><td colspan="2"><div id="advanced_search">'
          + '<div id="search_filter_title" class="search_results">Filter search results based on:</div>'
          + '<div id="search_filter_div" class="search_results">'
          + '<input id="exact_match" type="checkbox" value="exact" class="search_filter" />'
          + '<label for="exact_match">Exact match of search word(s)</label><br />'
          + '<input id="synonymns" type="checkbox" value="synonyms" class="search_filter" />'
          + '<label for="synonymns">Do not include synonyms</label><br />'
          + '<input id="show_topic_titles" type="checkbox" value="topics" class="search_filter" />'
          + '<label for="show_topic_titles">Search within topic headings only</label>'
          + '<div id="refine_search_button"><span>Apply Filter</span></div>'
        + '</div></div></td></tr>'
        + '<tr><td colspan="2">'
          + '<div id="results_right"> Results <span id="current_results_counter">' + resultRange + '</span> of '
          + ' <span class="ResultsLabel">' + ResultCount + '</span></div>'
          + '<span class="search_results">You searched for &quot;<span class="yellow_highlight"> '
          + mSearchWords + ' </span>&quot;' + synonymText + '. ' + scopeText + '</span>'
        + '</td></tr>'
        + '<tr><td colspan="2">'
          + '<span class="prev_next_button"></span>'
        + '</td></tr></thead><tbody>';
    return thead;
}

function GenerateResultsFooter()
{
    var tfoot = '</tbody><tfoot><tr><td colspan="2"><div class="prev_next_button search_results">Can\'t find what you need? &nbsp;'
        + '<a href="' + SNSearch('top', 0, true) + '" target="_blank">Submit your search to Support Center</a></div></td></tr></tfoot></table>';
    return tfoot;
}

// Iterate through search results and generate the HTML code for the result listing.
// Accept parameters to control which results to generate.
function GenerateResultBody( ResultCount, LibResults, StartIndex, StopIndex )
{
    for ( var i = StartIndex; i < StopIndex && i < AllSearchResults.length; i++ ) {
        var syn = unique(AllSynonyms);
        var searchParams = "&amp;Sword=" + encodeURIComponent(mSearchWords);
        if ( syn.length > 0 ) searchParams += "&amp;Syn=" + encodeURIComponent(syn.join(" "));
        LibResults += "<tr title='Found " + AllSearchResults[i].word_count + " of " + mSearchWords.split(" ").length;
        LibResults += " words.  Words matched: " + AllSearchResults[i].matching_word.replace(/^\s+|\s+$/g, "").replace("'", "&#39;").replace(/\s/g, ", ");
        LibResults += ".  Relevance: " + AllSearchResults[i].weight + "'>";
        LibResults += "<td class='SearchNumber'><span class='ResultsNumber'>" + (ResultCount+1) + ". </span></td><td><div class='pSearchResult'>";
        LibResults += '<p class="pSearchTopic"><a class="search_result_link" href="' + AllSearchResults[i].file_link + searchParams + '" target="_blank">';
        LibResults += AllSearchResults[i].doc_title + "</a></p><p class='pSearchSource'>Document &#151; <span class='pSearchTitle'>";
        LibResults += MGC_Handle_to_Title(AllSearchResults[i].book) + "</span></p>";
        LibResults += "<div class='pSearchSnippet'>" + AllSearchResults[i].snippet + "</div>";
        LibResults += "</div></td></tr>";
        ResultCount++;
    }
    return { ResultCount:ResultCount, LibResults:LibResults, totalResultNumber:AllSearchResults.length };
}

// function called to apply/remove filters to search results
function UpdateSearchResultBody()
{
    SearchInfoHub(true);
    
    var LibResults = "";
    var ResultCount = 0;
    ResultBody = GenerateResultBody( ResultCount, LibResults, 0, 50 );
    LibResults = ResultBody.LibResults;
    ResultCount = ResultBody.ResultCount;
    IH.TotalResultNumber = ResultBody.totalResultNumber;
    
    if( ResultCount == 0 ) {
        LibResults = GetNoSearchResultsPage(true);
        $("#current_results_counter").html("0");
    } else {
    }

    $(".SearchResults tbody").html(LibResults);
    $(".SearchResults thead .ResultsLabel").html( ResultBody.totalResultNumber );
    if ( $("#synonymns").prop("checked") ) {
        $(".SearchResults thead .synonym_string").hide();
    } else {
        $(".SearchResults thead .synonym_string").show();
    }
}

// creates different "No Search Results" pages based on search scope
function GetNoSearchResultsPage( bUpdate )
{
    var Suggestions = "";
    var SearchTipSuggestion = "";
    var SubmitScopeSuggestion = '<li>Submit your search within a different InfoHub scope.</li>';
    var AllDocsSuggestion = '<li>Expand your search to <a href="javascript:LocalSearch(\'' + mSearchWords + '\', \'mgc_ih\');" '
        + 'title="Changes scope to All ' + mReleaseName + ' Installed Documents and automatically resubmits the search">'
        + 'All ' + mReleaseName + ' Installed Documents</a>.</li>';
    var SupportNetSuggestion = '<li><a href="' + SNSearch("top", 0, true)
        + '" title="Submits a search to Support Center using the ' + mInfoHubName
        + ' scope" target="_blank">Submit your search to Support Center</a> (requires Internet access).</li>';

    switch ( mInfoHub ) {
        case "all":
        case "mgc_ih":
            // If we are in the all docs scope, and the Release Information scope exists,
            // then we want to use the Release Information scope to submit the search to supportnet
            var ReleaseScope = GetReleaseScope();
            if ( ReleaseScope ) {
                SupportNetSuggestion = '<li><a href="' + SNSearch("top", 0, true, ReleaseScope)
                    + '" title="Submits a search to Support Center using the ' + GetScopeTitle(ReleaseScope)
                    + ' scope" target="_blank">Submit your search to Support Center</a> (requires Internet access).</li>';
            }
            Suggestions = SupportNetSuggestion;
            break;
        case "mydoc_ih":
            Suggestions = SubmitScopeSuggestion + AllDocsSuggestion + SupportNetSuggestion;
            break;
        default:
            Suggestions = SubmitScopeSuggestion + AllDocsSuggestion + SupportNetSuggestion;
            break;
    }
    
    if ( typeof bUpdate != "boolean" ) bUpdate = false;

    var LibResults = "";
    if ( ! bUpdate ) {
        LibResults += GenerateResultsHead(0);
    }
    LibResults += '<tr><td><div class="suggestions search_results">';
    LibResults += '<p class="pNoResults">No topics were found containing those keywords.</p>';
    LibResults += 'Suggestions: <ul>' + Suggestions;
    LibResults += '<li>See <a href="htmldocs/mgchelp.htm#context=mgc_html_help&amp;topic=mgc_help_008" onclick="OpenHtmlDoc(\'mgc_html_help&&mgc_help_008\');return false;" target="_blank">Search Tips</a> for more information.</li>';
    LibResults += '</ul></div></td></tr>';
    if ( ! bUpdate ) {
        LibResults += GenerateResultsFooter();
    }
    return LibResults;
}

function PaginateSearchResults()
{
    var currentPage = 0;
    var disabledPrev = true;
    var disabledNext = false;
    var numRows;
    var numPages;
    var table;
    var current_limit = 0;
    var DefaultResultsNumber = 50;
    
    if ( mbShowFilter ) {
        //go through and make sure all the correct buttons are checked.
        //if search returns no search results, we need to make sure that the filter dialog is still displayed.
        if ( AllSearchResults.length == 0 ) {
            $(".SearchResults tbody").html( GetNoSearchResultsPage(true) );
            $("#current_results_counter").html("0");
        }
        process_filter(false);
        process_filter(true);
    } else {
        $("#advanced_search").hide();
    }

    // handle coloring of checkboxes & labels
    $(".search_filter").click( function() {
        $(".search_filter").each( function() {
            if ( SearchFilter[$(this).attr("id")] != $(this).is(":checked") ) {
                $("#refine_search_button").removeClass("disabled");
                return false;
            }
            $("#refine_search_button").addClass("disabled");
        });
    }).each( function() {
        if ( $(this).is(":checked") ) {
            $(this).next().addClass("checkbox_selected");
            SearchFilter[$(this).attr("id")] = true;
        } else {
            SearchFilter[$(this).attr("id")] = false;
        }
    });

    // handle coloring of checkboxes & labels, display the filter dialog
    $("#advanced_search_button").toggle( function() {
        mbShowFilter = true;
        process_filter(false);
        $("#advanced_search_button_text").html("Remove Filter");
        $("#advanced_search").slideDown( "slow", function() {
            $("#refine_search_button").addClass("disabled");
        });
    }, function() {
        mbShowFilter = false;
        $("#advanced_search_button_text").html("Filter Results");
        SearchFilter["exact_match"] = false;
        SearchFilter["synonymns"] = false;
        SearchFilter["show_topic_titles"] = false;
        process_filter(false);
        UpdateSearchResultBody();
        $("#advanced_search").slideUp( "slow", function() {
            $("#refine_search_button").removeClass("disabled");
            // we might want to make repaginate() a function that can be called independently, but for right now we need to remove
            // the pager html code that is placed in by the PaginateSearchResults function, then call it.
            $(".SearchResults thead .pager").html("");
            $(".SearchResults tfoot .pager").html("");
            // This will take search results and make them paged again.
            PaginateSearchResults();
        });
    });

    $(".SearchResults").each( function() {
        var numPerPage = 11;
        table = $(this);
        numRows = table.find("tbody tr").length;
        numPages = Math.ceil(numRows / (numPerPage-1));
        //don't append pager if there are no results
        if ( numRows > 0 ) {
            var pager = $('<div class="pager"></div>');
            pager.append('<div class="back_arrow"><img src="infohubs/common/graphics/gr-arrow_left.gif" alt="previous" /></div>');
            $('<span class="previous-page">Previous</span>').appendTo(pager);
            pager.append(" | ");
            $('<span class="next-page">Next</span>').appendTo(pager);
            pager.append('<div class="next_arrow"><img src="infohubs/common/graphics/gr-arrow_right.gif" alt="next" /></div>');
            // insert before since pager has a "float:right" style
            pager.insertBefore($(".prev_next_button"));
            repaginate();
        }
    });

    //only allow button to be clicked when it is not disabled.
    $("#refine_search_button").click( function() {
        if(!$(this).is(".disabled")){
            // set the current page to 0-  this way, if the user has browsed off the first page of results,
            // we will start the new result list on the first page
            currentPage = 0;
            process_filter(true);
            process_filter(false);
            UpdateSearchResultBody();
            repaginate();
        }
    });

    //function to update/rewrite data for our filter
    //if modify_array is true, then we'll update the values that are in the array
    //this is used to change the array when the user clicks "apply filter"
    //if modify_array is set to false then we'll just make sure that what is being
    //displayed on the screen matches what is in the array
    function process_filter( modify_array ) {
        if ( modify_array ) {
            $(".search_filter").each( function() {
                if ( $(this).prop("checked") ) {
                    SearchFilter[$(this).attr("id")] = true;
                } else {
                    SearchFilter[$(this).attr("id")] = false;
                }
             });
             // set disabled flag on updated button
             $("#refine_search_button").addClass("disabled");
        } else {
            // check appropiate checkboxes based off of SearchFilter array
            $(".search_filter").each( function() {
                if ( SearchFilter[$(this).attr("id")] == true ) {
                    $(this).prop("checked", true);
                    $(this).next().addClass("checkbox_selected");
                } else {
                    // modify array based on what is checked
                    $(this).prop("checked", false);
                    $(this).next().removeClass("checkbox_selected");
                }
            });
        }
    }

    function repaginate() {
        var numPerPage = 11;
        // search results are new, so figure how many results we have
        numRows = table.find(".pSearchResult").length;
        var firstNumber = (currentPage * numPerPage-(currentPage));
        var secondNumber = ((currentPage + 1) * numPerPage -(currentPage+1));
        if ( secondNumber > numRows ) {
            secondNumber = numRows;
        }
        if ( numRows > 0 ) {
            $("#current_results_counter").html( (firstNumber+1) + "-" + secondNumber );
        }
        if ( firstNumber <=1 ) {
            disabledPrev = true;
            $(".previous-page").css("color", "#666666").removeClass("clickable").css("cursor", "default");
            $(".back_arrow").html('<img src="infohubs/common/graphics/gr-arrow_left_grey.gif" alt="previous" />');
        } else {
           disabledPrev = false;
           $(".previous-page").addClass("clickable").css("color", "#3769AC").css("cursor", "pointer");
           $(".back_arrow").html('<img src="infohubs/common/graphics/gr-arrow_left.gif" alt="previous" />');
        }
        if ( secondNumber >= numRows ) {
            disabledNext = true;
            if ( numRows + DefaultResultsNumber <= IH.TotalResultNumber ) {
                var newResults = GenerateResultBody( numRows, "", numRows, numRows + DefaultResultsNumber );
                $(".SearchResults").append(newResults.LibResults);
                numRows = table.find(".pSearchResult").length;
                numPages = Math.ceil(numRows / (numPerPage-1));
                repaginate();
            } else if ( numRows == IH.TotalResultNumber ) {
                disabledNext = true;
                $(".next-page").removeClass("clickable").css("text-decoration", "none").css("color", "#666666").css("cursor", "default");
                $(".next_arrow").html('<img src="infohubs/common/graphics/gr-arrow_right_grey.gif" alt="next" />');
            } else {
                var newResults = GenerateResultBody( numRows, "", numRows, IH.TotalResultNumber );
                $(".SearchResults").append(newResults.LibResults);
                numRows = table.find(".pSearchResult").length;
                numPages = Math.ceil(numRows / (numPerPage-1));
                repaginate();
            }
        } else {
           disabledNext = false;
           $(".next-page").addClass("clickable").css("color", "#3769AC").css("cursor", "pointer");
           $(".next_arrow").html('<img src="infohubs/common/graphics/gr-arrow_right.gif" alt="next" />');
        }

        $(".tabPane").scrollTo("0%",{duration:500});
        table.find(".pSearchResult").parent().parent().show().slice(0, firstNumber).hide().end().slice(secondNumber).hide().end();
    }

    $(".next-page").click( function() {
        if ( disabledNext ) return;
        currentPage++;
        repaginate();
    });

    $(".previous-page").click( function() {
        if ( disabledPrev ) return;
        currentPage--;
        repaginate();
    });

    $(".previous-page, .next-page").mouseover( function() {
        if ( $(this).text() == "Previous" ) {
            if( !disabledPrev ) {
                $(this).css("text-decoration", "underline");
            }
        } else if ( $(this).text() == "Next" ) {
            if ( !disabledNext ) {
                $(this).css("text-decoration", "underline");
            }
        }
    }).mouseout( function() {
        $(this).css("text-decoration", "none");
    });
}

// Updates the search form based on page state
function UpdateSearchForm()
{
    var query = $("#query");
    if ( query.val() == "Loading search database" ) {
        return;
    }
    if ( ! mbSearchListDirty ) {
        if ( mSearchScope != "" ) {
            $('#search_list input[value="' + mSearchScope + '"]').prop("checked", true);
        } else if ( GetCurrentTabName() == "support" && ! mbSNetSearchDisabled ) {
            $('#search_list input[value="supportnet"]').prop("checked", true);
        } else {
            $('#search_list input[value="ihub"]').prop("checked", true);
        }
    }
    // update search phrase *after* updating search scope above
    query.attr( "title", GetSearchPhrase($("#search_list input:checked").val()) );
    if ( ! mbSearchDirty ) {
        query.val( query.attr("title") );
    }
}

function SearchBox_KeyPress(evt)
{
    mbSearchDirty = true;
    if ( evt.keyCode == 13 ) {
        DoSearch();
        return false;
    }
    return true;
}

function SearchBox_Focus()
{
    $("#query").css("color", "black");
    if ( ! mbSearchDirty ) {
        $("#query").val("");
    }
}

function SearchBox_Blur()
{
    var query = $("#query");
    if ( query.val() == "" ) {
        query.css("color", "#6D6D6D");
        mbSearchDirty = false;
        query.val( GetSearchPhrase($("#search_list input:checked").val()) );
    }
}

function GetSearchPhrase( scope )
{
    var phrase = "";
    //if we are not trying to search Kanji support net or regular support net, let's get a more specific string 
    //for the search text-  based on which scope we're on
    if ( scope == "ihub" ) {
        scope = mInfoHub;
    }
    switch ( scope ) {
        case "mydoc_ih":
            phrase = "Type keywords here to search locally installed documentation based on custom search scope.";
            break;
        case "supportnet":
            phrase = "Type keywords here to search Support Center, constrained to this scope's products.";
            break;
        case "supportnet_ja":
            phrase = "%E6%97%A5%E6%9C%AC%E8%AA%9ESupport Center%E3%81%A7%EF%BD%A4%E9%81%B8%E6%8A%9E%E3%81%95%E3%82%8C%E3%81%9F%E8%A3%BD%E5%93%81%E3%81%AE%E6%8A%80%E8%A1%93%E6%83%85%E5%A0%B1%E3%82%92%E6%A4%9C%E7%B4%A2%E3%81%A7%E3%81%8D%E3%81%BE%E3%81%99%E3%80%82%E8%B3%AA%E5%95%8F%E5%86%85%E5%AE%B9%E3%82%92%E5%85%A5%E5%8A%9B%E3%81%97%E3%81%A6%E3%81%8F%E3%81%A0%E3%81%95%E3%81%84%EF%BD%A1";
            phrase = decodeURIComponent(phrase);
            break;
        case "mgc_ih":
            phrase = "Type keywords here to search all locally installed documentation.";
            break;
        default:
            phrase = "Type keywords here to search locally installed documentation based on scope.";
            break;
    }
    return phrase;
}

// Disables local search radio button and selects Support Center
function DisableLocalSearch()
{
    mbLocalSearchDisabled = true;
    if ( ! document.getElementById("search_snet").disabled ) {
        document.getElementById("search_snet").selected = true;
    }
    document.getElementById("search_local").disabled = true;
    document.getElementById("search_all_local").disabled = true;
    document.getElementById("search_my_local").disabled = true;
}

// Enables local search radio button and selects it (if not in Support tab, with web access)
function EnableLocalSearch()
{
    mbLocalSearchDisabled = false;
    document.getElementById("search_local").disabled = false;
    document.getElementById("search_all_local").disabled = false;
    document.getElementById("search_my_local").disabled = false;
    if ( !( GetCurrentTabName() == "support" && mbWebAccess ) ) {
        if ( mInfoHub == "mgc_ih" ) {
            document.getElementById("search_all_local").selected = true;
        } else {
            document.getElementById("search_local").selected = true;
        }
    }
}

// disables Support Center in search scope list
function DisableSNetSearch()
{
    mbSNetSearchDisabled = true;
    if ( ! document.getElementById("search_local").disabled ) {
        if ( mInfoHub == "mgc_ih" ) {
            document.getElementById("search_all_local").selected = true;
        } else {
            document.getElementById("search_local").selected = true;
        }
    }
    document.getElementById("search_snet").disabled = true;
}

// enables Support Center in search scope list and selects it if on Support tab
function EnableSNetSearch()
{
    mbSNetSearchDisabled = false;
    document.getElementById("search_snet").disabled = false;
    if ( GetCurrentTabName() == "support" && mbWebAccess ) {
        document.getElementById("search_snet").selected = true;
    }
}

// initiates a Support Center search
function SNSearch( Field, Query, ReturnURL, OverrideHandle )
{
    var searchTerms = "";
    if ( typeof Query == "string" && Query.length > 0 ) {
        searchTerms = Query;
    } else {
        searchTerms = $("#query").val();
    }
    searchTerms = searchTerms.split(" ").join("+");
    searchTerms = searchTerms.split("\"").join("'");   // quotation marks won't send in url
    searchTerms = encodeURIComponent(searchTerms);
    var url = mRedirectURL;
    url += "?query=" + searchTerms;
    if ( typeof OverrideHandle == "string" && OverrideHandle.length > 0 ) {
        url += "&infohub=" + OverrideHandle;
    } else if ( typeof mInfoHub == "string" && mInfoHub.length > 0 ) {
        url += "&infohub=" + mInfoHub;
    }
    if ( typeof mFlowName == "string" && mFlowName.length > 0 ) {
        url += "&flow=" + mFlowName;
    }
    if ( typeof Field == "string" && Field.length > 0 ) {
        switch ( Field.toLowerCase() ) {
            case "tab":
                url += "&field=tab";
                break;
            case "top":
                url += "&field=top";
        }
    }
    if ( typeof ReturnURL != "undefined" && ReturnURL ) {
        return url;
    } else {
        OpenWin( url );
    }
}

// initiates a Kanji Support Center search
function SNKanjiSearchV3( Field, Query )
{
    var searchTerms = "";
    if ( typeof Query == "string" && Query.length > 0 ) {
        searchTerms = Query;
    } else {
        searchTerms = $("#query").val();
    }
    searchTerms = searchTerms.split(" ").join("+");
    searchTerms = searchTerms.split("\"").join("'");   // quotation marks won't send in url
    searchTerms = encodeURIComponent(searchTerms);
    var url = mRedirectURL;
    url += "?query=" + searchTerms;
    url += "&lang=jp";
    if ( typeof mInfoHub == "string" && mInfoHub.length > 0 ) {
        url += "&infohub=" + mInfoHub;
    }
    OpenWin( url );
}

function EnableKanjiSupportNet( value )
{
    if ( typeof value == "undefined" ) {
        value = true;
    }
    EnableKanjiSupportNetBool = value;
}

function EnableKanjiSupportNetHelper( value )
{
    if ( typeof value == "boolean" && !value ) {
        mbShowKanjiSNet = false;
    } else if ( typeof value == "string" && value.length > 0 ) {
        if ( value == "false" ) {
            mbShowKanjiSNet = false;
        } else if ( value == "true" ) {
            mbShowKanjiSNet = true;
        } else {
            mbShowKanjiSNet = true;
            mKanjiSNetText = value;
        }
    } else {
        mbShowKanjiSNet = true;
    }
    // add Kanji Support Center radio button to search form, reformat to fit option
    if( $("#search_snet_kanji").length < 1 ) {
        $("#search_box_td").css("width", "480px");
        //$("#search_list").width("420px");
        $("#search_list").css("padding-right", "5px");
        $('<label for="supportnet_kanji" > <span style="font-weight:normal; font-size:13px !important;">&#26085;&#26412;&#35486;</span>  Support Center </label>').insertAfter($('label[for="search_snet"]'));
        $('<input type="radio" name="group1" id="search_snet_kanji" value="supportnet_ja" onclick="UpdateSearchForm();" />').insertAfter($('label[for="search_snet"]'));
    }
}

// return path to data file for given book handle
function GetDataFilePath( handle )
{
    return "htmldocs/" + handle + "/MGCdata/MGCAllData.js";
}

// load MGCAllData.js files for every book and initiate search when complete
function LoadSearchData()
{
    if ( mbIncrementalLoad && ! IsReleaseScope() ) {
        var incremental = [];
        var booklist = GetBookList();
        for ( var book in booklist ) {
            // figure out what books are in the current scope, then figure out which ones we've already loaded.
            // if the file handle does not exist in the DataFiles array, we've already loaded it.
            var dataFilePath = GetDataFilePath( booklist[book] );
            for ( var file in DataFiles ) {
                if ( dataFilePath == DataFiles[file] ) {
                    incremental.push(dataFilePath);
                    DataFiles.splice(file, 1);
                    break;
                }
            }
        }
        SearchData = incremental;
    } else {
        SearchData = DataFiles;
        DataFiles = [];
    }

    // if SearchData is not empty, load the remaining search data
    if ( SearchData.length > 0 ) {
        //prepare the page for loading search data:
        $("#query").hide();
        $(".search_box .search_btn").fadeOut("slow");
        $("#icon-replacement").fadeIn("slow");
        $("#text-replacement").fadeIn("slow");
        $(".search_box").css("background-image", "url('infohubs/common/graphics/bg-search_x.png')");
        setTimeout( function() {
            LoadingScreen();
            IH.DataFilesLength = SearchData.length;
            mbDataLoaded = false;
            RecursiveLoadData();
        }, 1 );
    } else {
        SearchInfoHub();
        DisplaySearchResults();
        PaginateSearchResults();
    }
}

function RecursiveLoadData()
{
    if ( ! mbDataLoaded ) {
        if ( SearchData.length > 0 ) {
            var string = SearchData.pop();
            // $('#progress').progressBar(Math.floor(((IH.DataFilesLength-SearchData.length)/IH.DataFilesLength)*100));
            $('#progress').scrollTo(Math.floor(((IH.DataFilesLength-SearchData.length)/IH.DataFilesLength)*100));
            setTimeout( function() {
                GetScript( "datafile" + SearchData.length, string, RecursiveLoadData );
            }, 1 );
         } else {
            mbDataLoaded = true;
            $(".scope_link_active, .scope_link").show();
            $(".tabs").show();
            $("#icon-replacement").hide();
            $("#text-replacement").hide();
            $(".search_box .search_btn").fadeIn("slow");
            $(".search_box").removeAttr("style");
            $("#query").show();
            SearchInfoHub();
            DisplaySearchResults();
            PaginateSearchResults();
            $.unblockUI();
        }
    }
}

// Appends script to head of document, then sets a callback function to run when loaded
function GetScript( id_name, path, callback_function )
{
    var old = document.getElementById(id_name);
    if (old != null) {
        old.parentNode.removeChild(old);
        delete old;
    }
    var head = document.getElementsByTagName("head")[0];
    script = document.createElement('script');
    script.id = id_name;
    script.type = 'text/javascript';
    script.src = path;
    script.onreadystatechange = function() {
        if (this.readyState == 'complete' || this.readyState == 'loaded') callback_function();
    }
    script.onload = callback_function;
    head.appendChild(script);
}


//////////////
//  Popups  //
//////////////

function LoadingScreen()
{
    $.blockUI({ message: '<div id="loading"><span class="bold">Loading InfoHub search database...</span><br /><br /><div id="progress">Just a moment...</div><br />'
        + '<span><span class="bold">Tip:</span> To avoid reloading the search database, keep this InfoHub tab (or window) open in the browser for the remainder of your workday.</span><br /></div>'});
}

function loadPopup( divName )
{
    // loads popup only if it is disabled
    if ( popupStatus == 0 ) {
        popupDiv = divName;
        $("#backgroundPopup").css({"opacity": ".5"});
        $("#backgroundPopup").fadeIn();
        $(divName).fadeIn();
        popupStatus = 1;
    }
    if ( ! CookiesEnabled() ) {
        if($(divName).height() < 200)
            $(divName).height($(divName).height()+93);
        $(CookieWarningMessage()).insertAfter($(divName +  ' h1'));
    }
}

function disablePopup()
{
    // hacked together way of doing this, but we only have two times we use this function,
    // so figure out which disables popup only if it is enabled
    if ( popupStatus == 1 ) {
        $("#backgroundPopup").fadeOut();
        $(popupDiv).fadeOut();
        $(".notice").remove();
        $("#mydocsPopup").height(400);
        $("#prefsPopup").height(110);
        popupStatus = 0;
    }
}

function loadPopupInformation()
{
    cookieString = GetCookie("MGC_mydoclist").split(",");
    if ( cookieString == "" ) {
        //backup for browsers not supporting cookies
        cookieString = mydoclist_cookie.split(",");
    }
    //make sure nothing exists in the "all doc list" by clearing it out
    $("#alldocsdoclist").html("");
    if ( typeof mLibraryList != "undefined" && mLibraryList.length > 0 ) {
        //add entries into AllDocList
        for ( var i = 0; i < mLibraryList.length; i++ ) {
            var bookHandle = mLibraryList[i][1];
            var bookTitle =  mLibraryList[i][0];
            var bookPDFHTML = mLibraryList[i][2];
            $("#alldocsdoclist").append($('<option></option>').val( bookHandle).html(typeof(bookPDFHTML)=="undefined"?bookTitle:bookTitle+" (" + bookPDFHTML.toUpperCase()+")")
                .attr("title",bookTitle)
                .attr("option",typeof(bookPDFHTML)=="undefined"?"":bookPDFHTML));
        }
    }
    if ( cookieString.length >= 1 && cookieString[0] != "" ) {
        //If there is a cookie set, write these values into the My Doc List select list
        $("#selecteddoclist").html("");
        for (var  i=0; i < cookieString.length; i++ ) {
            var pdfhtmlAttribute = GetPdfHtmlOnlyAttribute(cookieString[i]);
            var BookTitle = GetBookTitle(cookieString[i]);
            $("#selecteddoclist").append($('<option></option>').val(cookieString[i]).html(pdfhtmlAttribute==""?BookTitle:BookTitle + " ("+ pdfhtmlAttribute.toUpperCase() + ")" )
                .attr("title",BookTitle)
                .attr("option",pdfhtmlAttribute));
        }
    }
}

function setupPopupEvents()
{
    $(popupDiv + " .save_button").click( function() {
        //reset IHDoclistCount variable to 0-  if we don't do this, each time a user clicks edit list and then save, the variable will keep being incremented.
        IHDoclistCount = 0;
        if ( popupDiv == "#mydocsPopup" ) {
            cookieText = [];
            // delete contents of doclist on scope page, so we can add new items to the list
            $("#tabTable select.doclist").html("");
            List = new List_Object("mydocs");
            List.fSetMaxSize(25);
            
            $("#selecteddoclist option").each( function() {
                cookieText.push($(this).val());
                $("#tabTable select.doclist").append($('<option></option>').val($(this).val()).html($(this).text()));
            });

            if ( cookieText.length > 0 ) {
                //sort cookieText by book title, so titles appear in alphebetical order
                cookieText = cookieText.sort( function(e1,e2) {
                    return GetBookTitle(e1).toLowerCase() > GetBookTitle(e2).toLowerCase() ? 1 : -1;
                });
                var cookieString = cookieText.join(",");
                SetCookie("MGC_mydoclist",cookieString);
                mydoclist_cookie = cookieString; //backup for browsers not supporting cookies
            } else {
                //if there are no values in My Doc List, someone has cleared out the list, or tried saving a list with no values
                //in it.  Either way, let's write the cookie out with nothing in it.
                SetCookie("MGC_mydoclist","");
                mydoclist_cookie = "";
            }
            
            GenerateMyDocsScope();
            $("#tabTable").html(IHTab_Olh.mEntries[0].fGetHTML());
            disablePopup();
            Tab_OnResize();  //disable/enable open html and open pdf buttons where appropriate.
        } else if ( popupDiv == "#prefsPopup" ) {
            cookieText = $("#pref_promptclose").prop("checked") ? "true" : "false";
            SetCookie("MGC_preferences", cookieText);
            disablePopup();
        }
    });

    $(popupDiv + " .cancel_button").click( function() {
        disablePopup();
    });

    $(popupDiv + " .popupClose").click(function(){
        disablePopup();
    });

    // Escape keypress event
    $(document).keypress( function(e) {
        if ( e.keyCode==27 && popupStatus==1 ) {
          disablePopup();
        }
    });
}


///////////////
//  Cookies  //
///////////////

function SetCookiePath()
{
    var Pathname, WorkingURL, Parts, Index, Protocol = "";
    if ( mCookiePath.length > 0 ) return;
    Pathname = "/";
    WorkingURL = mURL;
    if (WorkingURL.indexOf("?") != -1) {
        Parts = WorkingURL.split("?");
        WorkingURL = Parts[0];
    }
    Index = WorkingURL.lastIndexOf("/");
    if ((Index + 1) < WorkingURL.length) {
        WorkingURL = WorkingURL.substring(0, Index);
    }
    Index = -1;
    if (WorkingURL.indexOf("http:/") == 0) {
        Index = WorkingURL.indexOf("/", 6);
        Protocol = "http";
    } else if (WorkingURL.indexOf("ftp:/") == 0) {
        Index = WorkingURL.indexOf("/", 5);
        Protocol = "ftp";
    } else if (WorkingURL.indexOf("file:///") == 0) {
        Index = 7;
        Protocol = "file";
    }
    if (Index != -1) {
        Pathname = WorkingURL.substring(Index, WorkingURL.length);
        if (Protocol == "file") {
            if ( $.browser.msie ) {
                if (Pathname.length > 1) {
                    Pathname = unescape(Pathname);
                    Pathname = Pathname.split("/").join("\\");
                    if (Pathname.indexOf("\\") == 0) {
                        Pathname = "/" + Pathname.substring(1, Pathname.length);
                    }
                }
            }
        } else {
            Index = Pathname.indexOf("/", Index);
            if (Index != -1) {
                Pathname = Pathname.substring(Index, Pathname.length);
            } else {
                Pathname = "/";
            }
        }
    }
    mCookiePath = Pathname;
}

function SetCookie( ParamName, ParamValue, ParamExpiration )
{
    // IE does not seems to like cookies from specific domains on the local file system
    // In 2.1, we just set cookies for the entire local infohub. Here, let's only do that when the
    // using the local file system, and the browser is MSIE.
    var VarFormattedCookie, VarPath, VarExpirationDate;
    VarFormattedCookie = escape(ParamName) + "=" + escape(ParamValue);
    if ( $.browser.msie && /file:\/\//.test(location.href) ) {
        // Add path, disregard real path so cookie applies to all local infohubs
        VarFormattedCookie += "; path=/";
    } else {
        SetCookiePath()
        VarFormattedCookie += "; path=" + this.mCookiePath;
    }
    // Add expiration day, if specified
    if ((typeof(ParamExpiration) != "undefined") && (ParamExpiration != null) && (ParamExpiration != 0)) {
        VarExpirationDate = new Date();
        VarExpirationDate.setTime(VarExpirationDate.getTime() + (ParamExpiration * 1000 * 60 * 60 * 24));
        VarFormattedCookie += "; expires=" + VarExpirationDate.toGMTString();
    } else if ( ParamExpiration != 0 ) {
        VarExpirationDate = new Date();
        VarExpirationDate.setTime(VarExpirationDate.getTime() + ( 5 * 365 * 1000 * 60 * 60 * 24));  // 5 years
        VarFormattedCookie += "; expires=" + VarExpirationDate.toGMTString();
    }
    document.cookie = VarFormattedCookie
}

function GetCookie( ParamName )
{
    var VarValue, VarCookies, VarKey, VarStartIndex, VarEndIndex;
    VarValue = "";
    VarCookies = document.cookie;
    VarKey = escape(ParamName) + "=";
    VarStartIndex = VarCookies.indexOf(VarKey);
    if (VarStartIndex != 0) {
        VarKey = "; " + escape(ParamName) + "=";
        VarStartIndex = VarCookies.indexOf(VarKey);
    }
    if (VarStartIndex != -1) {
        VarStartIndex += VarKey.length;
        VarEndIndex = VarCookies.indexOf(";", VarStartIndex);
        if (VarEndIndex == -1) {
            VarEndIndex = VarCookies.length;
        }
        VarValue = unescape(VarCookies.substring(VarStartIndex, VarEndIndex));
    }
    return VarValue;
}

function DeleteCookie(ParamName)
{
    // Set cookie to expire yesterday
    SetCookie(ParamName, "", -1);
}

function CookiesEnabled()
{
    // Cache result
    if ( mbCookiesEnabled == null ) {
        // Default to disabled
        mbCookiesEnabled = false;

        // WebKit browsers on filesystem don't allow cookies
        // TODO: Ask Scott - Why the special test for WebKit. 
        if( /WebKit/.test(navigator.userAgent) && /file:\/\//.test(location.href) ) {
            return false;
        }
        // Try setting a cookie
        SetCookie("MGC_IHCookiesEnabled", "True");
        // Retrieve the cookie
        if ( GetCookie("MGC_IHCookiesEnabled") != "" ) {
            // Delete the test cookie
            DeleteCookie("MGC_IHCookiesEnabled");
            // Success!
            mbCookiesEnabled = true;
        }
    }
    return mbCookiesEnabled;
}

function CookieWarningMessage()
{
    var msg = '<div class="notice">You are accessing this InfoHub through the local file system.<br />';
    msg += 'The InfoHub cannot store your settings once you close the browser tab/window. ';
    msg += 'To avoid this, access this InfoHub through a web server.<br />';
    msg += 'For more information, refer to <a href="htmldocs/mgchelp.htm#context=mgc_html_help&amp;topic=mgc_help_018" target="blank">"Hosting Documentation on an Internal HTTP Server"</a>.</div>';
    return msg;
}


///////////////////////////////////////////////////////////////////////////
//                                                                       //
//  INFOHUB API                                                          //
//                                                                       //
//  The following functions use object-oriented JavaScript to load data  //
//  from doclist.js files that define the content of each scope.         //
//                                                                       //
///////////////////////////////////////////////////////////////////////////

/////////////////////////
//  TabContent Object  //
/////////////////////////
function TabContent_Object( Name, Title )
{
    this.mEntryCount = 0;
    this.mEntries = [];
    this.mbVisible = false;
    this.mName = Name;
    this.mTitle = Title;
    this.mExpandCount = 0;
    this.mHTMLSrc = null;

    this.fAddEntry = TabContent_AddEntry;
    this.fReplaceEntry = TabContent_ReplaceEntry;
    this.fGetHTML = TabContent_GetHTML;
    this.fVisible = TabContent_Visible;
    this.fSetTitle = TabContent_SetTitle;
    this.fSetHTMLSrc = TabContent_SetHTMLSrc;
}

function TabContent_AddEntry( Entry )
{
    if ( typeof Entry != "undefined" && Entry.mItemCount > 0 ) {
        this.mEntries[this.mEntryCount] = Entry;
        this.mEntries[this.mEntryCount].mTab = this;
        if ( this.mEntries[this.mEntryCount].mbExpand ) {
            this.mEntries[this.mEntryCount].mExpandID = this.mExpandCount++;
        }
        this.mEntryCount++;
    }
}

function TabContent_ReplaceEntry( Entry, EntryToReplace )
{
    if ( typeof Entry != "undefined" && Entry.mItemCount > 0 ) {
        this.mEntries[EntryToReplace] = Entry;
        this.mEntries[EntryToReplace].mTab = this;
        if ( this.mEntries[EntryToReplace].mbExpand ) {
            this.mEntries[EntryToReplace].mExpandID = this.mEntryCount = this.mEntries.length;;
        }
        this.mEntryCount = this.mEntries.length;
    }
}

function TabContent_Visible( Bool )
{
    if ( this.mName == "custom" ) this.customerSpecified = true;
    if ( this.mName == "beta" ) this.betaSpecified = true;
    switch ( typeof(Bool) ) {
        case "boolean":
            this.mbVisible = Bool;
            break;
        case "string":
            if ( Bool == "true" ) {
                this.mbVisible = true;
            } else if ( Bool == "false" ) {
                this.mbVisible = false;
            }
            break;
    }
}

function TabContent_GetHTML()
{
    Count = 0;
    var HTML = "";
    if ( this.mHTMLSrc ) {
        HTML += '<iframe id="IHTabSrcPane" name="IHTabSrcPane" class="tabPane" src="' + this.mHTMLSrc + '">';
    } else {
        //if this is the search tab, we don't need a table for organizing, just write out a div for us to put a table in
        if(/tab=search/.test(mPreviousHash)){
            return '<div id="search_results"></div>';
        }
        HTML += '<div class="tabContent">';
        HTML += '<table id="tabTable" align="left" border="0" cellpadding="0" cellspacing="0">';
        if ( this.mEntryCount > 0 ) {
            // loop thru each entry and retrieve HTML
            for ( var i = 0; i < this.mEntryCount; i++ ) {
                HTML += this.mEntries[i].fGetHTML();
                HTML += "\n\n";
            }
        }
        HTML += '</table>';
        HTML += '</div>';
    }

    return HTML;
}

function TabContent_SetTitle( Title )
{
    if ( Title && Title != "" ) {
        this.mTitle = Title;
    }
}

function TabContent_SetHTMLSrc( Src )
{
    if ( typeof Src == "string" && Src.length > 0 ) {
        alert("The SetHTMLSrc function has been deprecated. The InfoHub system no longer supports this feature due to browser security policies.");
        //this.mHTMLSrc = Src;
    }
}


///////////////////////
//  TabEntry Object  //
///////////////////////
function TabEntry_Object( Title, Icon, ID )
{
    this.mTab        = null;
    this.mTitle      = Title;
    this.mIcon       = Icon;
    this.mID         = "";
    this.mBodyText   = "";
    this.mIconURL    = "";
    this.mItemCount  = 0;
    this.mItems      = [];
    this.mbList      = false;
    this.mbVisible   = true;
    this.mbExpand    = false;
    this.mExpandID   = null;
    this.mHTML       = "";

    // functions
    this.fVisible      = TabEntry_Visible;
    this.fSetBodyText  = TabEntry_SetBodyText;
    this.fSetIconURL   = TabEntry_SetIconURL;
    this.fExpandable   = TabEntry_Expandable;
    this.fAddItem      = TabEntry_AddItem;
    this.fAddLink      = TabEntry_AddLink;
    this.fAddText      = TabEntry_AddText;
    this.fAddList      = TabEntry_AddList;
    this.fAddHTML      = TabEntry_AddHTML;
    this.fGetHTML      = TabEntry_GetHTML;

    if ( typeof(ID) == "string" && ID.length > 0 ) {
        this.mID = ID;
    }
}

function TabEntry_Visible( Bool )
{
    switch ( typeof Bool ) {
        case "boolean":
            this.mbVisible = Bool;
            break;
        case "string":
            if ( Bool == "true" ) {
                this.mbVisible = true;
            } else if ( Bool == "false" ) {
                this.mbVisible = false;
            }
            break;
    }
}

function TabEntry_Expandable( Bool )
{
    switch ( typeof Bool ) {
        case "boolean":
            this.mbExpand = Bool;
            break;
        case "string":
            if ( Bool == "true" ) {
                this.mbVisible = true;
            } else if ( Bool == "false" ) {
                this.mbVisible = false;
            }
            break;
    }
}

function TabEntry_SetBodyText( Text )
{
    if ( typeof Text == "string" && Text.length > 0 ) {
        this.mBodyText = Text;
    }
}

function TabEntry_SetIconURL( URL )
{
    if ( typeof URL == "string" && URL.length > 0 ) {
        this.mIconURL = "" + URL;
    }
}

function TabEntry_AddItem( Item )
{
    if ( (typeof Item != "undefined" && Item.mItemCount > 0) || Item.mListType == "mydocs" ) {
        this.mItems[this.mItemCount] = Item;
        this.mItems[this.mItemCount].mEntry = this;
        if ( this.mItemCount >= 1 ) {
            this.mbList = true;
        } else if ( typeof Item.mTitle == "string" && Item.mTitle.length > 0 ) {
            this.mbList = true;
        }
        this.mItemCount++;
    }
}

function TabEntry_AddLink( Text, Link, BodyText )
{
    if ( typeof Text != "undefined" && Text != "" && Link && Link != "" ) {
        this.fAddItem( new Link_Object( Text, Link, BodyText ) );
        this.mbList = true;  // always a list when a link is added
    }
}

function TabEntry_AddText( Text )
{
    if ( typeof Text != "undefined" && Text != "" ) {
        this.fAddItem( new Text_Object( Text ) );
    }
}

function TabEntry_AddList( ListObject )
{
    ListObject.fPrep();
    this.fAddItem( ListObject );
}

function TabEntry_AddHTML( HTML )
{
    if ( typeof(HTML) != "undefined" && HTML != "" ) {
        this.mHTML += HTML;
        this.mItemCount = 1;
    }
}

function TabEntry_GetHTML()
{
    var HTML = "";
    var DivID = "";
    if ( this.mID.length > 0 ) {
        DivID = " name=\"Entry_"+this.mID+"\" ";
        if ( ! this.mbVisible ) {
            DivID += "style=\"display:none;\" ";
        }
    }
    // if custom HTML specified, use it
    if ( this.mHTML != "" ) {
        HTML += "<tr valign='top'><td class='doclist_html'><div "+DivID+">";
        HTML += this.mHTML;
        HTML += "</div></td></tr>";
        return HTML;
    }
    // if no items, return empty string
    if ( this.mItemCount < 1 ) {
        return "";
    }
    HTML += "<tr valign='top'><td width='100%' class='doclist_title'><div "+DivID+">";
    if ( this.mTitle == "All Locally Installed Documentation" ) {
        HTML += "<h2> All Locally Installed Documents for " + mReleaseName + "</h2>";
    } else {
        HTML += "<h2>" + this.mTitle + "</h2>";
    }
    if ( this.mBodyText.length > 0 ) {
        HTML += "<p class='H1BodyText'>" + this.mBodyText + "</p>";
    }
    HTML += "</div></td></tr>";
    HTML += "<tr valign='top'>";
    HTML += "<td class='doclist'><div "+DivID+">";
    if ( this.mbExpand ) {
        HTML += "<div id=\"ExpButton_" + this.mExpandID + "\" >";
        HTML += "<input type=\"image\" id=\"ExpButtonSrc_" + this.mExpandID + "\" src=\"../graphics/show_tasks.png\" onClick=\"ToggleExpContentsById('"+ this.mExpandID + "')\" onMouseOver=\"this.src='../graphics/show_tasks_h.png';\" onMouseOut=\"this.src='../graphics/show_tasks.png';\" class=\"showtask\" >";
        HTML += "</div>";
        HTML += "<div id=\"ExpContents_" + this.mExpandID + "\" style=\"display:none;\" >";
    }
    if ( this.mbList ) {
        HTML += "<ul class='listbull'>";
        // loop thru each item in entry
        for ( var i = 0; i < this.mItemCount; i++ ) {
            HTML += "<li class='listbull'>";
            HTML += this.mItems[i].fGetHTML();
            HTML += "</li>";
        }
        HTML += "</ul>";
    } else {
        HTML += this.mItems[0].fGetHTML();
    }
    if ( this.mbExpand ) {
        HTML += "   </div>";
    }
    HTML += "  </div></td>";
    HTML += "</tr>";
    return HTML;
}


///////////////////
//  Link Object  //
///////////////////
function Link_Object( Text, Link, BodyText )
{
    // properties
    this.mEntry      = null;
    this.mItemCount  = 1;
    this.mText       = Text;
    this.mLink       = Link;
    this.mBodyText   = BodyText;

    // functions
    this.fSetBodyText  = Link_SetBodyText;
    this.fGetHTML      = Link_GetHTML;
}

function Link_SetBodyText( Text )
{
    if ( typeof Text == "string" && Text.length > 0 ) {
        this.mBodyText = Text;
    }
}

function Link_GetHTML()
{
    var HTML = "";
    var Class = ( mbWebAccess ) ? "weblink" : "noweb";
    var URL = GetLinkURL( this.mLink );
    HTML += "<p class='listbull'>";
    HTML += "<a href='" + URL + "' class='" + Class + "' target='_blank' title='" + LinkHoverText + "' >" + this.mText + "</a>";
    HTML += "</p>";
    if ( typeof this.mBodyText == "string" && this.mBodyText.length > 0 ) {
        HTML += "<p class='H2BodyText'>" + this.mBodyText + "</p>";
    }
    return HTML;
}


///////////////////
//  Text Object  //
///////////////////
function Text_Object( Text )
{
    // properties
    this.mEntry      = null;
    this.mItemCount  = 1;
    this.mText       = Text;

    // functions
    this.fGetHTML = Text_GetHTML;
}

function Text_GetHTML()
{
    return "<p class='textbull'>" + this.mText + "</p>";
}


///////////////////
//  List Object  //
///////////////////
function List_Object( Type, Sort )
{
    // properties
    this.mEntry           = null;
    this.mItemCount       = 0;
    this.mItems           = [];
    this.mNames           = [];
    this.mLinks           = [];
    this.mTitle           = "";
    this.mTitleLink       = "";
    this.mTitleLinkClass  = ( mbWebAccess ) ? "weblink" : "noweb";
    this.mBodyText        = "";
    this.mID              = "";
    this.mbVisible        = true;
    this.mbIsDocList      = false;
    this.mbSort           = true;
    this.mListType        = "";
    this.mMaxSize         = mMaxListSize;

    // functions
    this.fAddItem      = List_AddItem;
    this.fSetTitle     = List_SetTitle;
    this.fSetBodyText  = List_SetBodyText;
    this.fPrep         = List_Prep;
    this.fSetDocList   = List_SetDocList;
    this.fSetID        = List_SetID;
    this.fSetMaxSize   = List_SetMaxSize;
    this.fVisible      = List_Visible;
    this.fGetHTML      = List_GetHTML;

    if ( typeof(Type) == "string" && Type.length > 0 ) {
        switch ( Type.toLowerCase() ) {
            case "noorder":
            case "nosort":
                this.mbSort = false;
                break;
            default:
                this.mListType = Type;
        }
    }
    if ( typeof(Sort) == "string" && Sort.length > 0 ) {
        switch ( Sort.toLowerCase() ) {
            case "noorder":
            case "nosort":
                this.mbSort = false;
                break;
            default:
                if ( this.mListType == "" ) {
                    this.mListType = Type;
                }
        }
    }
}

function List_AddItem( Title, Link, Topic, Type )
{
    if ( (typeof mLibraryList != "undefined") && this.mListType == "doclist" && !(mLibraryList.length == 1 && mLibraryList[0][1]=="mgc_html_help") ) {
        var manualInLibList = false;
        for ( var test = 0; test < mLibraryList.length; test++ ) {
            if ( mLibraryList[test][1] == Link ) {
                if ( typeof Topic == "undefined" ) {
                    Topic = typeof mLibraryList[test][2] == "string" ? mLibraryList[test][2] : null;
                }
                manualInLibList = true;
                break;
            }
        }
        if ( ! manualInLibList) {
            return;
        }
    }
    var Item = "";
    if ( typeof(Title) == "string" && Title != "" && typeof(Link) == "string" && Link != "" ) {
        Item = Title + "@@" + Link;
        if ( typeof(Topic) == "string" && Topic.length > 0 ) {
            switch ( Topic.toLowerCase() ) {
                case "pdf":
                case "htm":
                case "html":
                    Item += "::" + Topic;
                    break;
                default:
                    Item += "&&" + Topic;
                    if ( typeof(Type) == "string" && Type.length > 0 ) {
                        Item += "::" + Type;
                    }
            }
        }
        this.mItems[this.mItemCount++] = Item;
    }
}

function List_SetTitle( Title, Link )
{
    if ( typeof Title == "string" && Title.length > 0 ) {
        this.mTitle = Title;
        if ( typeof Link == "string" && Link.length > 0 ) {
            this.mTitleLink = GetLinkURL( Link );
        }
    }
}

function List_SetBodyText( Text )
{
    if ( typeof Text == "string" && Text.length > 0 ) {
        this.mBodyText = Text;
    }
}

function List_Prep()
{
    if ( this.mbSort ) {
        this.mItems.sort( SortAscendingAlpha );
    }
    for ( var i = 0; i < this.mItemCount; i++ ) {
        var Parts = this.mItems[i].split("@@");
        this.mNames[i] = Parts[0];
        this.mLinks[i] = Parts[1];
    }
}

function List_SetDocList( bValue )
{
    if ( typeof(bValue) != "undefined" && bValue ) {
        this.mListType = "doclist";
    }
}

function List_SetID( ID )
{
    if ( typeof ID != "undefined" ) {
        this.mID = "" + ID;
    }
}

function List_SetMaxSize( Size )
{
    if ( typeof Size != "undefined" ) {
        this.mMaxSize = Size;
    }
}

function List_Visible( Bool )
{
    switch ( typeof Bool ) {
        case "boolean":
            this.mbVisible = Bool;
            break;
        case "string":
            if ( Bool == "true" ) {
                this.mbVisible = true;
            } else if ( Bool == "false" ) {
                this.mbVisible = false;
            }
            break;
    }
}

function List_GetHTML()
{
    var HTML = "";
    var Count = IHDoclistCount++;  // increments AFTER setting Count
    var ListType = this.mListType.toLowerCase();
    var DivID = "";
    if ( this.mID.length > 0 ) {
        DivID = " name='List_" + this.mID + "' ";
        if ( ! this.mbVisible ) {
            DivID += " style='display:none' ";
        }
    }
    var ListMax = this.mMaxSize;
    if ( ListType == "infohub" ) {
        ListMax = 25;
    }
    // get number of items to determine list size (max 6)
    var Size = this.mItemCount + 1;
    if ( Size > ListMax ) {
        Size = ListMax;
    }
    var Class = "doclist";
    if ( this.mEntry.mItemCount > 1 ) {
        Class = "doclist_indent";
    }
    // add doclist title, if specified
    if ( this.mTitle.length > 0 ) {
        HTML += "<p class='listbull'>";
        if ( this.mTitleLink.length > 0 ) {
            HTML += "<a href='" + this.mTitleLink + "' class='" + this.mTitleLinkClass + "' target='_blank' title='" + LinkHoverText + "' >" + this.mTitle + "</a>";
        } else {
            HTML += this.mTitle;
        }
        HTML += "</p>";
    } else if ( this.mEntry.mItemCount > 1 ) {
        // doclist without title in entry with multiple items, add blank title so bullet is positioned somewhat properly
        HTML += "<div>&nbsp;</div>";
    }
    // add body text, if specified
    if ( typeof this.mBodyText == "string" && this.mBodyText.length > 0 ) {
        HTML += "<p class='H2BodyText'>" + this.mBodyText + "</p>";
    }
    HTML += "<div " + DivID + " >";
    switch ( ListType ) {
        case "mydocs":
            cookieString = GetCookie("MGC_mydoclist").split(",");
            if ( cookieString == "" ) {
                // backup for browsers that don't support cookies
                cookieString = mydoclist_cookie.split(",");
            }
            if ( cookieString.length > 0 && cookieString[0] != "" ) {
                HTML += "<select class='"+Class+"' id='doclist"+Count+"' name='doclist' size='" + ( (cookieString.length+1) <= 25 ? (cookieString.length+1) : 25 );
                HTML += "' ondblclick='ViewDoc("+Count+");' onclick='Doclist_OnChange("+Count+")' onkeyup='Doclist_OnChange("+Count+")' title='Select, then click Open HTML/PDF OR double-click to View.'>";
            } else {
                // if no cookie is defined, add some default placeholder text instructing users to click "Edit List"
                HTML += "<select class='"+Class+"' id='doclist"+Count+"' name='doclist' size='10' ' title='Click \"Edit List\" to add documents to this list.'>";
                HTML += "<option disabled=\"true\" value=\"false\"" + ">Click \"Edit List\" to add items to this list</option></select>";
            }
            break;
        case "doclist":
        case "infohub":
            HTML += "<select class='"+Class+"' id='doclist"+Count+"' name='doclist' size='"+Size+"' ondblclick='ViewDoc("+Count+");' onclick='Doclist_OnChange("+Count+")' onkeyup='Doclist_OnChange("+Count+")' title='Select, then click Open HTML/PDF OR double-click to View.'>";
            break;
        default:
            HTML += "<select class='"+Class+"' id='doclist"+Count+"' name='doclist' size='"+Size+"' ondblclick='OpenDoc("+Count+");' title='Select, then click Open OR double-click.'>";
    }
    for ( var i = 0; i < this.mItemCount; i++ ) {
        var Class = "";
        var Selected = "";
        if ( ListType == "infohub" ) {
            if ( this.mLinks[i].indexOf("infohub="+mInfoHub) != -1 ) {
                // highlight current InfoHub
                Class = "class=\"current\" selected=\"selected\"";
            }
        } else {
            var parts = this.mLinks[i].split("::");
            var pdfhtmlonly = "";
            if ( typeof parts[1] != "undefined" ) {
                if ( parts[1].match(/^pdf$/i) ) {
                    Class = 'class="pdfonly"';
                    pdfhtmlonly = " (PDF)";
                } else if ( parts[1].match(/^html?$/i) ) {
                    Class = 'class="htmlonly"';
                    pdfhtmlonly = " (HTML)";
                }
            }
            if ( i == 0 ) Selected = " selected=\"true\" ";
        }
        HTML += "<option value=\"" + this.mLinks[i] + "\" " + Class + Selected + ">" + this.mNames[i] + pdfhtmlonly + "</option>";
    }
    HTML += "</select>";
    switch ( ListType ) {
        case "doclist":
        case "infohub":
            HTML += "<div id='button_container_div'><div class='textButtons left_justify' alt='Open HTML' value='Open HTML' id='btnHTML"+Count+"' onClick='ViewDoc("+Count+");'><span title='Select item, then click Open HTML for browsing.' >Open HTML</span></div>";
            HTML += "<div class='textButtons left_justify' alt='Open PDF' value='Open PDF' id='btnPDF"+Count+"' onClick='PrintDoc("+Count+");'><span title='Select item, then click Open PDF for browsing or printing.'>Open PDF</span></div></div>";
            break;
        case "mydocs":
            HTML += "<div id ='button_container_div'><div class='textButtons left_justify' alt='Open HTML' value='Open HTML' id='btnHTML"+Count+"' onClick='ViewDoc("+Count+");' title='Select item, then click Open HTML for browsing.'><span>Open HTML</span></div>";
            HTML += "<div class='textButtons left_justify' alt='Open PDF' value='Open PDF' id='btnPDF"+Count+"' onClick='PrintDoc("+Count+");' title='Select item, then click Open PDF for browsing or printing.'><span>Open PDF</span></div>";
            HTML += "<div class='textButtons list_btn left_justify' alt='Edit Doc List' style='margin-left: 330px' value='Edit My Doc List' id='editList' 'title='Opens MyDoc list for editing' onClick='EditList("+Count+");'><span>Edit List</span></div></div>";
            break;
        case "":
            HTML += "<div class='textButtons left_justify' alt='Open' value='Open' id='btnHTML"+Count+"' onclick='OpenWin("+Count+");' title='Select item, then click Open.'><span>Open</span></div>";
            break;
        default:
            HTML += "<div class='textButtons left_justify' alt='Open' value='Open' id='btnHTML"+Count+"' onclick='OpenDoc("+Count+");' title='Select item, then click Open.'><span>Open HTML</span></div>";
    }
    HTML += "</div>";
    return HTML;
}

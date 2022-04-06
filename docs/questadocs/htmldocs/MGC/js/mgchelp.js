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
// mgchelp.js - JavaScript framework for mgchelp
//

// global variables
var GlobalsVersion = "mgc_html_v4.2.008";  // also update version in htmldocs/MGC/version
var MGCFrame = window.self;
var KeyboardShortcuts = false;
var locale = "us_en";
var LastTopic = { handle:"", ID:1, tag:"" };
var mCurrentTab = 0;
var mCurrInfoHubHandle = "mgc_ih";
var mCurrInfoHubName = "Mentor Graphics";
var mDocumentWidth = "";
var mForceSearch = false;
var mHandle = "";
var mHash = location.hash;
var mID = "";
var mInfoHubName = "Mentor Graphics";
var mPage = "";
var mSource = "doc";
var mTab = 0;
var mTag = "";
var mTopic = "";
var mSearchWords = "";
var mSidebarCollapse = false;
var mSidebarWidth = "";
var mbBasicMode = null;
var mbWebKitFile = null;
var isFileSystem = null;
var onSupportNet = false;
var Popup = false;
var HasIndex = false;
var HighlightDocumentTopic = false;
var HighlightSearchTerms = false;
var HighlightSword = "";
var HighlightSyn = "";
var SearchTitlesOnly = false;
var fromQuickSearch = false;
var ScrollDiv = "";
var TopicToHighlight = "";
var SidebarFraction = .26;
var MaxSidebarFraction = .4;
// var MinSidebarSize = 250;
var MinSidebarSize = 350;
var SearchHighlight = {
    enabled:      true,
    exactMatch:   false,
    preWildcard:  false,
    postWildcard: true,
    titlesOnly:   false,
    searchWord:   '',
    scrollId:     'SString1',
    synonymList:  [],
    charsAllowed:         '\\?"=:;~_<>%/\\*\\.\\,\\(\\)\\|\\s\\[\\]\\$\\\\\\-\\^',
    wildcardCharsAllowed: '\\?"=:;~_<>%/\\*\\.\\,\\(\\)\\|\\[\\]\\$\\\\\\-\\^'
};
var mExpandTOC = false;

/*** PDF Popup ***/
var popupStatus = 0;
var popupDiv = "";

window.name = "MGCFrame";

// if jQuery didn't load, redirect to basic mode
if ( typeof jQuery == "undefined" ) {
    ParseURLParams();
    if ( !mHandle ) mHandle = "mgc_html_help";
    location.replace( mHandle + "/nsmgchelp.htm");
}

// replace search params (?) with hash (#), use location.replace to not affect history
if ( location.href.indexOf("?") != -1 ) location.replace( location.href.replace("?", "#") );

// initialize javascript framework for document
$(document).ready( function() {
    MGCTreeLoc = location.href.replace(/\/mgchelp\.htm.*/, "");

    // MGCLangOptions is now loaded dynamically in mgchelp.htm, based on the user's language setting.
    // The MGCSetLangOptions() function must now be called from the onLoaded callback, using the GetScript() function.
    // MGCSetLangOptions();

    DetectOS();
    MGCFontSize();

    // if LibList.js didn't load, populate mLibraryList with the default mgc_html_help manual
    var add_book_to_list = false;
    if ( typeof mLibraryList == "undefined" ) {
        mLibraryList = [];
        mLibraryList.push(["Mentor Graphics Documentation System", "mgc_html_help"]);
        add_book_to_list = true;
        var msg = "The htmldocs/MGC/lib/LibList.js file does not exist because DocMerge has not been run on this doc tree. ";
        msg += "You can continue to test this HTML document. However, links between HTML documents will not function.";
        alert(msg);
    }

    ParseURLParams();
    
    // determine default book to load if mHandle not set yet
    if ( !mHandle ) {
        // if only 1 book in library, open it
        if ( mLibraryList.length == 1 ) {
            mHandle = mLibraryList[0][1];
        }
        // if only 2 books in library, choose the one that is not mgc_html_help
        if ( mLibraryList.length == 2 ) {
            mHandle = mLibraryList[1][1];
            if ( mHandle == "mgc_html_help" ) {
                mHandle = mLibraryList[0][1];
            }
        }
        if ( !mHandle ) mHandle = "mgc_html_help";
    }

    var book_exists = false;
    for ( var k = 0; k < mLibraryList.length; k++ ) {
        if ( mHandle == mLibraryList[k][1] ) {
            book_exists = true;
            break;
        }
    }
    if ( !book_exists ) {
        add_book_to_list = true;
        var msg = "The requested document (" + mHandle + ") is not installed in the documentation library.\n\n";
        msg += "This condition can result from following a link to a document that has not been installed or has been removed. ";
        msg += "The document will attempt to open but may not be functional.";
        alert(msg);
    }

    // add current book to library list (except for mgc_html_help)
    if ( add_book_to_list && mHandle != "" && mHandle != "mgc_html_help" ) {
        mLibraryList.push([mHandle, mHandle]);
    }

    BookData = [];
    CreateBookData();

    // The MGCAllData.js file is needed to proceed further.
    // Once data is loaded, use callback function to continue this process.
    GetScript( mHandle + "/MGCdata/MGCAllData.js", "AllDataFile", function() {
        // use onhashchange function if available
        if ( window.onhashchange !== undefined ) {
            window.onhashchange = HashChanged;
        } else {
            // for older browsers, check for hash change every 100 miliseconds
            window.setInterval( function() {
                if ( location.hash != mHash ) {
                    HashChanged();
                }
            }, 100);
        }

        if ( mForceSearch ) {
            mCurrentTab = 2;
        }
        if ( mTab == "" ) {
            mTab = mCurrentTab;
        }

        // determine topic to open and id
        var TopicToOpen = BookData[mHandle].FirstTopic;
        var TopicFile = "";
        if ( mID == "" ) {
            if ( mTopic == "" ) {
                if ( mPage == "" ) {
                    // use default topic
                    TopicToOpen = MGC_MatchTopic(mHandle, BookData[mHandle].FirstTopic);
                    mID = MGC_File_to_ID(mHandle, MGC_MatchTopic(mHandle, mTopic));
                } else {
                    // use href param
                    TopicToOpen = mPage;
                    mID = MGC_File_to_ID(mHandle, mPage);
                }
            } else {
                // JCB
                // Version check to see if the alldata file is FM8, or FM12. 
                // If FM12, then we don't want MGC_MatchTopic to add the "wp" to the URL params.
                // NB in FM8 days, the TemplateVer value had the form: mgc_ww_v3.2.203.
                // mgc_ww_v3.2.210
                var versionCompare = BookData[mHandle].TemplateVer.indexOf("mgchelp");
                TopicToOpen = MGC_MatchTopic(mHandle, mTopic, versionCompare);
                mID = MGC_File_to_ID(mHandle, MGC_MatchTopic(mHandle, mTopic, versionCompare));
            }
            TopicFile = mHandle + "/" + TopicToOpen;
        } else {
            // use id param
            TopicToOpen = MGC_ID_to_File(mHandle, mID) + ".html";
            TopicFile = GetTopicURL( mID, mTag );
        }
        LastTopic.ID = mID;

        // redirect to topic file if basic mode
        if ( DetectBasicMode() ) {
            // use location.replace() to not affect browsing history
            location.replace(TopicFile);
        }

        // insert iframe for topic
        if ( $.browser.msie ) {
            // IE8 and prior need frameBorder attribute, which isn't valid HTML5
            $("#main").append('<iframe id="TopicFrame" name="TopicFrame" frameBorder="0"></iframe>');
        } else {
            $("#main").append('<iframe id="TopicFrame" name="TopicFrame"></iframe>');
        }

        // adjust browser css and default font size
        ChangeBrowserCSS();
        if ( MGCCookiesEnabled() ) {
            var text_size = MGCGetCookie("MGCBaseBodyFontSizeID")
            if ( text_size != null ) {
                MGCChangeBaseFontSize(text_size)
            } else {
                MGCChangeBaseFontSize(1);
            }
        } else {
            MGCChangeBaseFontSize(1);
        }

        // Set initial doc title
        document.title = BookData[mHandle].DocTitle;
        $(".DocTitle a").text(BookData[mHandle].DocTitle);

        // load TOC
        $("#sidebarTOC").html(GetTOC());

        // Version check and remove the index tab for FM12 docs
        // Index tab has id of "tab1".
        var versionCompare = BookData[mHandle].TemplateVer.indexOf("mgchelp");
        if(versionCompare > -1) {
           $("#tab1").remove();
        }
        else {
           $("#lettersections").append(GetIndex());
           $("#tab1").css("display", "block");
        }

        ExpandTOC(0, mHandle);

        HighlightTOC(GetTOCIndex(mID, mTag, mHandle), mHandle);

        // If the book is English, or if there is no language defined (meaning it's an old book, pre-translation),
        // then show the Search tab.
        var bookLang = BookData[mHandle].Language;
        if(typeof bookLang === 'undefined' || (bookLang.indexOf("en") >= 0)) {
            $("#tab2").css("display", "block");
        }

        // Can't highlight search terms when docs are opened from file system. 
        // Only turn the highlight button on if we're hosted.
        if(!DetectOnFileSystem()) {
            $("#HighlightContent").css("display", "block");
        }

        SwitchTab(mTab);

        // set window resize handler
        $(window).resize( function(e) {
            $("#sidebarContent").css("height", $(window).height() - 72);
            mDocumentWidth = $(document).width();
            mSidebarWidth = $("#sidebar").width();
            if ( document.getElementById("showhidetabs").onclick != ExpandSidebar ) {
                // If percent width is < MinSidebarSize, force the sidebar to be MinSidebarSize.
                var percentWidth = parseInt(mDocumentWidth * SidebarFraction);
                if ( mSidebarWidth <= MinSidebarSize && percentWidth <= MinSidebarSize ) {
                    $(".fw_size").css( "left", MinSidebarSize + "px" );
                    $("#sidebar").css( "width", MinSidebarSize + "px" );
                } else if ( mSidebarWidth > MinSidebarSize && percentWidth > MinSidebarSize ) {
                    $(".fw_size").css( "left", percentWidth );
                    $("#sidebar").css( "width", percentWidth );
                }
            }
            if ( $.browser.msie && $.browser.version == "7.0" ) {
                $("#TopicFrame").css( "height", $(window).height() - 92 + "px" );
            }
        });

        // set mousedown/mouseup handlers for resizing sidebar
        $('#dragbar').mousedown( function(e) {
            e.preventDefault();
            $('body').css("cursor", "col-resize");
            $('#dragdetector').css("z-index", "100");
            $(document).mousemove(function(e) {
                // Check for appropiate width on both sides: MinSidebarWidth and MaxSidebarFraction of the page.
                newWidth = (e.pageX +2);
                screenPercent = newWidth / $(document).width();
                if ( e.pageX > MinSidebarSize && screenPercent < MaxSidebarFraction ) {
                    $('#sidebar').css( "width", newWidth + "px" );
                    $(".fw_size").css( "left", newWidth + "px" );
                }
                else if( e.pageX <= MinSidebarSize ) {
                    $(".fw_size").css( "left", MinSidebarSize + "px" );
                    $("#sidebar").css( "width", MinSidebarSize + "px" );
                }
            })
        });
        $(document).mouseup( function() {
            $("#dragdetector").css("z-index", "-1");
            $("body").css("cursor", "default");
            $(document).unbind('mousemove');
        });

        // bind keyboard shortcuts
        KeyboardShortcuts = true;
        $(document).keydown(checkKey);

        // Detect if hosted on supportnet by looking for supportnet.mentor.com or
        // support.mentor.com in the url
        onSupportNet = false;
        if( /^https?:\/\/[^/:]*support(?:net)?\.mentor\.com/.test(location.href) ) {
            onSupportNet = true;
        }

        // collapse sidebar if necessary
        if ( mSidebarCollapse ) {
            CollapseSidebar(0);
        }

        if ( Popup ) {
            // hide framework for popup mode
            $(window).unbind("resize");
            $("#sidebar, #footer").hide();
            $("#header").css("left", "0px");
            $("#main").css("bottom", "2px").css("left", "0px");
            // hide the toolbar buttons
            $("#showhidetabs").hide();
        }

        // InfoHub link should be turned off in the following circumstances:
        // 1) this manual has been brought up on SupportNet
        // 2) The "InfoHub" book variable has been set to "none"
        if( BookData[mHandle].IHUBHandle[0].toLowerCase() == "none" || onSupportNet ) {
            $("#InfoHubLibListLink").hide();
            $("#LibListLibraryContents").css("height", 326);
        }

        if ( mLibraryList.length < 18 ) {
            var divHeight = $("#LibListLibraryContents").height();
            var listHeight = $("#LibListLibraryLinks").height();
            var adjust = ((18-mLibraryList.length) * 15);
            divHeight -= adjust;
            listHeight -= adjust;
            $("#LibListLibraryContents").css("height", divHeight);
            $("#LibListLibraryLinks").css("height", listHeight);
        }

        // load topic in iframe
        if ( mForceSearch ) {
            // Perform search if url contains query param
            mForceSearch = false;
            $("#query").val(mSearchWords);
            SwitchTab(2);
            SearchBook();
        } else if ( $.browser.msie ) {
            TopicFrame.location.replace(TopicFile);
        } else {
            TopicFrame.location.href = TopicFile;
        }

        // trigger window resize event to adjust layout to initial size
        $(window).resize();

        $("#TopicFrame").load(function(){
            if(HighlightDocumentTopic && TopicToHighlight!=""){
                RemoveBookTopicHighlight();
                $(TopicToHighlight, TopicFrame.document).addClass("BookTopicHighlight");
                HighlightDocumentTopic = false;
                TopicToHighlight = "";
            }
        });
    });
});

function ParseURLParams()
{
    var Hash = location.hash.replace("#","");
    if ( Hash ) {
        var Params = {};
        // store hash parameters in Params object
        Hash.replace(/([^=&]+)=([^&]*)/g, function(m, key, val) {
            Params[decodeURIComponent(key)] = decodeURIComponent(val);
        });

        if ( Params.context ) mHandle = Params.context;
        if ( Params.topic ) mTopic = Params.topic;
        if ( Params.id ) mID = Params.id;
        if ( Params.tab ) {
            switch ( Params.tab ) {
                case "1":
                case "index":
                    mTab = 1;
                    break;
                case "2":
                case "search":
                    mTab = 2;
                    break;
                case "0":
                case "topics":
                default:
                    mTab = 0;
                    break;
            }
        }
        if ( Params.tag ) mTag = Params.tag;
        if ( Params.single == "true" ) mSidebarCollapse = true;
        if ( Params.single == "popup" ) Popup = true;
        if ( Params.href ) mPage = Params.href;
        if ( Params.exact ) SearchHighlight.exactMatch = (Params.exact == "true");
        if ( Params.ihub ) mCurrInfoHubHandle = Params.ihub;
        if ( Params.src ) mSource = Params.src;
        if ( Params.scrollid ) SearchHighlight.scrollId = "MGC" + Params.scrollid;
        if ( Params.topiconly ) SearchHighlight.titlesOnly = (Params.topiconly == "true");
        if ( Params.query ) {
            mSearchWords = Params.query;
            mForceSearch = true;
        }
        if ( Params.Sword ) {
            HighlightSword = Params.Sword.replace("+", " ");
            SearchHighlight.enabled = true;
            mForceSearch = false;
            $("#query").val(Params.Sword);
        }
        if ( Params.Syn ) {
            HighlightSyn = Params.Syn.replace(/\+|%20/g, " ");
            mForceSearch = false;
        }
        if ( Params.expandtoc )
            mExpandTOC = Params.expandtoc.toLowerCase() == 'true';
        else
            mExpandTOC = false;
    }
}

function HashChanged()
{
    var Params = {};
    var Hash = location.hash.replace("#","");
    var storedParams = {};
    var storedHash = mHash.replace("#", "");
    mHash = location.hash;

    // store old hash parameters in storedParams object
    storedHash.replace(/([^=&]+)=([^&]*)/g, function(m, key, val) {
        storedParams[decodeURIComponent(key)] = decodeURIComponent(val);
    });

    // store new hash parameters in Params object
    Hash.replace(/([^=&]+)=([^&]*)/g, function(m, key, val) {
        Params[decodeURIComponent(key)] = decodeURIComponent(val);
    });

    // if handle changed, load book with window.open
    if ( Params.context && Params.context != storedParams.context ) {
        var url = "#context=" + Params.context;
        if ( Params.topic ) url += "&topic=" + Params.topic;
        if ( Params.id )    url += "&id="    + Params.id;
        if ( Params.tag )   url += "&tag="   + Params.tag;
        if ( Popup ) url += "&single=popup";
        location.href = url;
    }

    var ID = "", Tag = "";
    if ( Params.id ) {
        ID = parseInt(Params.id);
    } else if ( Params.topic ) {
        ID = MGC_File_to_ID( mHandle, MGC_MatchTopic( mHandle, mTopic ) );
    } else {
        // no id or topic param, load default topic
        ID = MGC_File_to_ID(mHandle, MGC_MatchTopic(mHandle, BookData[mHandle].FirstTopic));
    }
    if ( Params.tag ) {
        Tag = Params.tag;
    }
    if ( ID ) {
        // IE on the file system needs to update the hash for back/forward to work
        if ( $.browser.msie && /file:\/\//.test(location.href) ) {
            TopicDisplay( ID, Tag );
        } else {
            LoadTopic( ID, Tag );
        }
    }
    if ( Params.tab != storedParams.tab ) {
        SwitchTab(parseInt(Params.tab));
    }
}

function checkKey(e)
{
    if ( KeyboardShortcuts ) {
        switch (e.keyCode) {
            // Page Up
            case 33:
                PrevTopic();
                break;
            // Page Down
            case 34:
                NextTopic();
                break;
            // Home
            case 36:
                Home();
                break;
            // Up Arrow
            case 38:
                PrevTopic();
                break;
            // Down Arrow
            case 40:
                NextTopic();
                break;
            // j
            case 74:
                NextTopic();
                break;
            // k
            case 75:
                PrevTopic();
                break;
            // n
            case 78:
                NextTopic();
                break;
            // p
            case 80:
                PrevTopic();
                break;
        }
    }
}


/////////////
// Sidebar //
/////////////

function SwitchTab( tab )
{
    // default to Topics tab
    defaultTab = 0;
    if ( !isNaN(mCurrentTab) ) defaultTab = parseInt(mCurrentTab);
    if ( isNaN(tab) ) tab = defaultTab;
    if ( tab < 0 || tab > 2 ) tab = defaultTab;

    // disable index for some books
    var includeIndex = true;
    if ( BookData[mHandle].IncludeIndex == "false" || !HasIndex ) includeIndex = false;
    if ( !includeIndex && tab == "1" ) tab = defaultTab;

    //mHash = location.hash;
    //if ( /tab=/.test(mHash) ) {
    //    mHash = mHash.replace(/tab=[^&]*/, "tab=" + tab);
    //} else {
    //    mHash += "&tab=" + tab
    //}
    //location.hash = mHash;

    $('#sidebarTOC,#sidebarIndex,#sidebarSearch').css("display", "none");
    $('.fg_tab').addClass("bg_tab").removeClass("fg_tab");

    switch (tab) {
        case 0:
            $('#sidebarTOC').css("display", "block");
            $("#tab0").removeClass("bg_tab").addClass("fg_tab");

            // See MGCLangOptions.js
            $("#tab0").attr("title", ActiveToolTip);

            // Note the following is not translated because the Index tab is not available in HTML.
            if ( includeIndex ) {
                $("#tab1").attr("title","Switch to Index tab");
            } else {
                $("#tab1").removeClass("bg_tab").addClass("no_tab").attr("title","Index not available for this document");
            }

            // Note Search tab will be hidden in all languages except English. (See <lang>/MGCLangOptions.js)
            $("#tab2").attr("title","Switch to Search tab");
            
            if ( $('.TOCHighlight').length == 1 ) {
                // if user has selected another topic using the TOC or search results and then clicks back to the "Topics" tab,
                // the highlighted topic will not be centered in the window, and possibly can be off screen, depending on the
                // length of the TOC. This line will ensure that the highlighted topic is centered in the window.
                $('#sidebarContent').stop().scrollTo($('.TOCHighlight'), 10, {
                    axis: 'y',
                    offset: ($('#sidebarContent').height() / 2 * -1)
                });
            }
            break;
        case 1:
            $('#sidebarIndex').css("display", "block");
            $("#tab1").removeClass("bg_tab").addClass("fg_tab");
            $("#tab1").attr("title","Index tab is active");
            $("#tab0").attr("title","Switch to Topics tab");
            $("#tab2").attr("title","Switch to Search tab");
            break;
        case 2:
            $('#sidebarSearch').css("display", "block");
            $("#tab2").removeClass("bg_tab").addClass("fg_tab");
            $("#tab2").attr("title","Search tab is active");
            $("#tab0").attr("title","Switch to Topics tab");
            if ( includeIndex ) {
                $("#tab1").attr("title","Switch to Index tab");
            } else {
                $("#tab1").removeClass("bg_tab").addClass("no_tab").attr("title","Index not available for this document");
            }
            $("#query").focus();
            PaginateSearchResults();
            break;
    }
    mCurrentTab = tab;
}

function CollapseSidebar(speed)
{
    // default to 1/2 second for sidebar animation, unless speed argument specified
    if ( typeof speed != "number" ) speed = 500;
    // var collapsedWidth = 12;
    var collapsedWidth = 15;
    $("#dragbar").hide();
    $("#sidebar").css("min-width", collapsedWidth+"px");
    $("#footer").css("max-width","100%");
    $("#sidebarContent, #sidebarTabs").hide(speed);
    $("#sidebar").animate( {width: collapsedWidth+"px"}, speed, function() {
        $('#sidebar').css("border-right", "1px solid #C8CED2").attr("title", Button.Titles["showtabsX"]);
        $('#sidebar').click(ExpandSidebar);
        $('#midarrow').show();
    });
    $(".fw_size").animate( {left: (collapsedWidth+1)+"px"}, speed );
    $("div.TABSButton").addClass("TABSButtonX").removeClass("TABSButton");
    $("#showhidetabs").attr("title", Button.Titles["showtabsX"]);
    document.getElementById("showhidetabs").onclick = ExpandSidebar;
    $("#midarrow").click(ExpandSidebar);
    $('#sidebar,#midarrow').hover(function () {
        $("#midarrow").addClass("sidearrowsmallx").removeClass("sidearrowsmall");
        $("#sidebar").css("background-color", "#D9DFE3").css("border-right", "1px solid #A8AEB2");
    },  function(){
        $("#midarrow").addClass("sidearrowsmall").removeClass("sidearrowsmallx");
    
        // License check for Siemens colors.
        if(BookData[mHandle]["LicenseType"].toLowerCase().indexOf("siemens") >= 0) {
            $("#sidebar").css("background-color","#fff").css("border-right", "1px solid #C8CED2");
        }
        else {
            $("#sidebar").css("background-color","#E8EEF2").css("border-right", "1px solid #C8CED2");
        }
    });
}

function ExpandSidebar()
{
    var sidebarWidth = parseInt(mDocumentWidth * SidebarFraction);
    //adjust size of sidebar if it's too small
    if($(document).width() * SidebarFraction < MinSidebarSize ){
        sidebarWidth = MinSidebarSize + "px";
    }
    $("#midarrow").addClass("sidearrowsmall").removeClass("sidearrowsmallx");

    // License check for Siemens colors.
    if(BookData[mHandle]["LicenseType"].toLowerCase().indexOf("siemens") >= 0) {
        $("#sidebar").css("background-color","#fff").css("border-right", "0").removeAttr("title");
    }
    else {
        $("#sidebar").css("background-color","#E8EEF2").css("border-right", "0").removeAttr("title");
    }

    $("#sidebar").animate( {width: sidebarWidth}, 500 );
    $("#dragbar").show();
    $(".fw_size").animate( {left: sidebarWidth}, 500, function() {
        $("#sidebar").css( "min-width", MinSidebarSize+"px" );
    });
    $("#footer").css( "max-width", "85%" );
    $("#sidebarContent, #sidebarTabs").fadeIn(1000);
    $("#sidebar, #midarrow").unbind("click mouseenter mouseleave");
    $("#midarrow").hide();
    $("div.TABSButtonX").addClass("TABSButton").removeClass("TABSButtonX");
    $("#showhidetabs").attr("title", Button.Titles["showtabs"]);
    document.getElementById("showhidetabs").onclick = CollapseSidebar;
}

//hacky version based on experimentation-
//Make sure the the offset is less than the height of the "sidebarTabs" div and the height of the highlighted element
//This makes sure that the highlighted element is fully in view.
function SideBarContentInView(HighlightedDiv, HeaderDiv, containerDiv)
{
    if ( $(HighlightedDiv).offset() == null ) return;
    var HeaderDivHeight = 0;
    $(HeaderDiv).each(function () {
        HeaderDivHeight += $(this).height();
    });
    if ($(HighlightedDiv).offset().top < (HeaderDivHeight + $(HighlightedDiv).height())) {
        if ($(HighlightedDiv).offset().top <= $(containerDiv).height() + HeaderDivHeight) {
            return false;
        } else {
            return true;
        }
    } else {
        if ($(HighlightedDiv).offset().top > $(containerDiv).height() + HeaderDivHeight) {
            return false;
        }
    }
    return true;
}


/////////////
// Toolbar //
/////////////

// display the first topic (title page)
function Home()
{
    TopicDisplay(1);
}

function DisplayInfoHub()
{
    var origWin = window.opener;
    if (origWin != null && !window.opener.closed) {
        var origWinName = window.opener.name;
        if (origWinName == "IHFrame") {
            alert("The InfoHub is already open in another browser window or tab");
            origWin.focus();
            return;
        }
    }
    window.open(MGCTreeLoc + "/../index.html#infohub=" + mCurrInfoHubHandle + "&tab=docs");
}

// The More Manuals button provides quick links to all manuals in the LibList.js file.
// For SupportNet, make sure that the InfoHub link does not show up.
function DisplayLibrary()
{
    if ( $("#LibListLibrary").is(":visible") ) {
        HideLibrary();
    } else {
        if ( $(".LibListLibraryIndent").length == 0 ) {
            var LibListHTML = "<ol class='LibListLibraryIndent'>";
            for ( var book in mLibraryList ) {
                LibListHTML += "<li><a href='#context=" + mLibraryList[book][1] + "' onclick='HideLibrary();' target='_blank'>" + mLibraryList[book][0] + "</a></li>";
            }
            LibListHTML += "</ol>";
            $("#LibListLibraryLinks").html(LibListHTML);
        }
        $("#LibListLibraryContents").slideDown();
        $("#LibListLibrary").fadeIn(600);
    }
}

function HideLibrary()
{
    $("#LibListLibraryContents").slideUp();
    $("#LibListLibrary").fadeOut(600);
}

function DisplayPDF()
{
    var openFunc = function() {

        var NewPDFLink = "";

        // Chrome cannot access TopicFrame.document.title because of cross-site scripting security.
        // On Chrome we can only go to the manual title page, not to the exact topic being viewed.
        if(DetectOnFileSystem() == true) {
            NewPDFLink = document.title.replace(/[^A-Za-z0-9 _]/g, "").replace(/-/g, "").replace("\)", "").replace("\(", "").replace(/ /g, "\.");
        }
        else {
            NewPDFLink = TopicFrame.document.title.replace(/[^A-Za-z0-9 _]/g, "").replace(/-/g, "").replace("\)", "").replace("\(", "").replace(/ /g, "\.");
        }

        window.open(MGCTreeLoc + "/../pdfdocs/" + mHandle + "\.pdf#M8.newlink." + NewPDFLink);
    }


    if(shouldWarnOnPDF() == true) {

        $("#pdflinkPopup").css("display", "block");
        if ( MGCGetCookie("MGC_PDFWarning") == "true" ) {
            $("#pdflink_noprompt").prop("checked", true);
            $("#pdflink_noprompt").next().addClass("checkbox_selected");
        } else {
            $("#pdflink_noprompt").prop("checked", false);
            $("#pdflink_noprompt").next().removeClass("checkbox_selected");
        }

        loadPopup("#pdflinkPopup");
        setupPopupEvents(openFunc);
    }
    else {
        openFunc();
    }

    /*
    var NewPDFLink = TopicFrame.document.title.replace("[^A-Z,a-z,0-9,_]", " ").replace(/-/g, "").replace("\)", "").replace("\(", "").replace(/ /g, "\.");
    window.open(MGCTreeLoc + "/../pdfdocs/" + mHandle + "\.pdf#M8.newlink." + NewPDFLink);
    */
}

function PrintTopic()
{
    TopicFrame.window.focus();
    TopicFrame.window.print();
}

function SubmitFeedback()
{
    var CurrentTopic = TopicFrame.PageTitle.replace("\&\#8482\;", "");
    var CurrentHandle = TopicFrame.DocHandle;
    var CurrentFile = TopicFrame.CurrentFile;
    var CurrentTitle = BookData[CurrentHandle].DocTitle;
    var SWRelease = BookData[CurrentHandle].SWRelease;
    window.open("https://support.sw.siemens.com/doc_feedback_form?doc_title\=" + CurrentTitle + " \(Topic is " + CurrentTopic + "\, File is " + CurrentFile + "\)&version\=" + SWRelease);
}

// update next/prev topic buttons based on last topic
function UpdateNavButtons()
{
    //if this is not the first file/topic on the list
    if ( LastTopic.ID > 1 ) {
        //remove any previous highlighting, add new class & button
        $("#PrevTopic div").removeClass("PrevButtonX").addClass("PrevButton").attr("title", Button.Titles["prevtopic"]);
    } else {
        $("#PrevTopic div").removeClass("PrevButton").addClass("PrevButtonX").attr("title", Button.Titles["prevtopicX"]);
    }
    //if this is not the last file/topic on the list
    if ( LastTopic.ID != BookData[mHandle].files.length - 1 ) {
        //remove any previous highlighting, add new class & button
        $("#NextTopic div").removeClass("NextButtonX").addClass("NextButton").attr("title", Button.Titles["nexttopic"]);
    } else {
        $("#NextTopic div").removeClass("NextButton").addClass("NextButtonX").attr("title", Button.Titles["nexttopicX"]);
    }
}

// This function is called from page.js each time a topic page is loaded.
// Updates the TOC, Breadcrumbs, prev/next buttons, footer, and document title.
// If search highlight is set, also highlights the last searched word.
function MGCUpdateNavPane()
{
    UpdateNavButtons();
    UpdateCurrentTopic();
    UpdateBreadcrumbs();

    // Highlight search word/synonym coming from InfoHub
    if ( HighlightSyn ) {
        SearchHighlight.synonymList = HighlightSyn.split(" ");
    }

    // HighlightSword is set when the page is first loaded, and the inital parameters are parsed
    // this should be able to be condensed with the code that does this below, but for some reason isn't.
    if ( HighlightSword ) {
        MGCHighlightSearchTerms( HighlightSword );
        //since we might have multiple words to highlight, we can't number the sstring ids as we encounter them.
        //instead, when we're highlighting the words, we'll use a temp name of sstring, then after all the words are highlighted
        //we'll go and remove the "name=sstring" attribute and replace it with an id of SString(id)
        //by using the each() function, we'll process each of the name=sstring attributes in a serial function, starting at head of
        //the document.
        var hlCount = 1;
        $('[name="SString"]', TopicFrame.document).each(function () {
            $(this).removeAttr("name").attr("id", "SString" + hlCount++);
        });
        MGCDocumentScrollTo("#" + SearchHighlight.scrollId);
    }

    HighlightSword = "";
    HighlightSyn = "";
    // End of highlight from InfoHub
    if ( HighlightSearchTerms && !SearchTitlesOnly ) {
        MGCHighlightSearchTerms( mSearchWords );
    }

    // why is this in here twice??? There needs to be a neater way to do this...
    if ( HighlightSearchTerms ) {
        var hlCount = 1;
        $('[name="SString"]', TopicFrame.document).each(function () {
            $(this).removeAttr('name').attr('id', 'SString' + hlCount++);
        });
        MGCDocumentScrollTo("#" + SearchHighlight.scrollId);
    }
    HighlightSearchTerms = false;


    // JCB
    // Version check here to look for landing on the title page. Don't insert the title in parens.
    // NB in FM8 days, the TemplateVer value had the form: mgc_ww_v3.2.203.
    var versionCompare = BookData[mHandle].TemplateVer.indexOf("mgchelp");
    if(versionCompare > -1 && TopicFrame.PageTitle == BookData[mHandle].DocTitle) {
        // use jQuery .html().text() functions to decode html entities
        document.title = $("<div/>").html(TopicFrame.PageTitle).text();
    }
    else
        document.title = $("<div/>").html(TopicFrame.PageTitle).text() + " (" + BookData[mHandle].DocTitle + ")";
}

// build html for breadcrumbs in the header
function UpdateBreadcrumbs()
{
    if ( typeof TopicFrame.BC == "undefined" ) return;
    // copy the BC array using the slice function (not an array reference)
    var BreadcrumbArray = TopicFrame.BC.slice(0);
    var HomeButton = '<div class="HomeButton" title="' + Button.Titles["home"] + BookData[mHandle].DocTitle + '" onclick="javascript:Home();"></div>';

    var TopicTitle = BreadcrumbArray.shift();
    var TopicID = MGC_File_to_ID(mHandle, BreadcrumbArray.shift());
    var breadcrumbs = "<a href=\"#context=" + mHandle + "&amp;id=" + TopicID + "\" onclick=\"javascript:TopicDisplay('" + TopicID + "','','" + mHandle + "'); return false;\">" + TopicTitle + '</a> > ';

    if( BreadcrumbArray[0] == "naV" ) {
        // If this is a top-level topic, remove the ' > ' character
        breadcrumbs = breadcrumbs.slice(0,breadcrumbs.length-2);
    } else {
        var CurrentTopicTitle = $(".TOCHighlight").text();
        // add the remaining levels of breadcrumbs
        while ( BreadcrumbArray.length > 2 && BreadcrumbArray[0] != "naV" ) {
            TopicTitle = BreadcrumbArray.shift();
            TopicID = MGC_File_to_ID(mHandle, BreadcrumbArray.shift());
            if ( $("<div/>").html(TopicTitle).text() == CurrentTopicTitle ) break;
            breadcrumbs += "<a href=\"#context=" + mHandle + "&amp;id=" + TopicID + "\" onclick=\"javascript:TopicDisplay('" + TopicID + "','','" + mHandle + "'); return false;\">" + TopicTitle + '</a> > ';
        }
        // the final breadcrumb comes from the highlighted TOC entry, not the breadcrumbs file
        breadcrumbs += CurrentTopicTitle;
    }

    // JCB
    // Need to do a version check here to turn off breadcrumbs in FM11 documents.
    // In FM11 documents we keep the home button but don't insert the breadcrumbs link.
    // NB this is intended to be a temporary workaround.
    var versionCompare = BookData[mHandle].TemplateVer.indexOf("mgchelp");
    if(versionCompare > -1) {
      $("#Breadcrumb").html(HomeButton);
    }
    else {
      $("#Breadcrumb").html( HomeButton + breadcrumbs);
    }

}

function DocProperties()
{
    var documentProperties = "Document Title: " + BookData[mHandle].DocTitle + "\n";
    documentProperties += "Handle: " + mHandle + "\n";
    documentProperties += "Software Release: " + BookData[mHandle].SWRelease + "\n";
    documentProperties += "Copyright Date: " + BookData[mHandle].Copyright + "\n";
    documentProperties += "HTML Output Version: " + BookData[mHandle].TemplateVer + "\n";
    documentProperties += "HTML Globals Version: " + GlobalsVersion + "\n";
    documentProperties += "Conversion Date: " + BookData[mHandle].ConvDate + "\n";
    alert(documentProperties);
}


////////////
// Topics //
////////////

function GetTOC()
{
    var TOC = [];
    MGCFrame.TOCHandle = MGCFrame.mHandle;
    var TOCLength = MGCFrame.BookData[MGCFrame.mHandle].toc.length;
    for (var Index = 0; Index < TOCLength; Index++) {
        var ID = MGCFrame.BookData[MGCFrame.mHandle].toc[Index][1];
        var Tag = MGCFrame.BookData[MGCFrame.mHandle].toc[Index][3];
        var TOCLevel = MGCFrame.BookData[MGCFrame.mHandle].toc[Index][0];
        var Class = "TOCdoc";
        var NextIndex = Index + 1;
        if (NextIndex < TOCLength) {
            var NextTOCLevel = MGCFrame.BookData[MGCFrame.mHandle].toc[NextIndex][0];
            if (NextTOCLevel > TOCLevel) {
                Class = mExpandTOC ? "TOCminus" : "TOCplus";
                // check for jump in TOC level greater than one, this is an error and needs to be corrected
                var Diff = NextTOCLevel - TOCLevel;
                if (Diff > 1) {
                    // loop thru trailing TOC entries and correct for jump in TOC level
                    for (var Offset = NextIndex; Offset < TOCLength && MGCFrame.BookData[MGCFrame.mHandle].toc[Offset][0] >= NextTOCLevel; Offset++) {
                        MGCFrame.BookData[MGCFrame.mHandle].toc[Offset][0] = MGCFrame.BookData[MGCFrame.mHandle].toc[Offset][0] - Diff + 1;
                    }
                }
            }
        }
        var Link = MGCFrame.GetTopicURL(ID, Tag);
        var HTML = "<p class='pMGCtoc" + TOCLevel + "' id='TOC" + Index + "'>";
        if (Class == "TOCdoc") {
            HTML = HTML + "<a class='" + Class + "' id='aTOCicon" + Index + "' href='" + Link + "' onclick='MGCFrame.TOCLink(" + Index + "," + ID + ",\"" + Tag + "\");return false;' target='MGCDocumentContent'>&#160;</a>";
        } else {
            HTML += "<a class='" + Class + "' id='aTOCicon" + Index + "' href='javascript:MGCFrame.ToggleTOC(" + Index + ");'>&#160;</a>";
        }
        HTML += "<a class='TOClink' id='aTOC" + Index + "' href='" + Link + "' ondblclick='MGCFrame.ToggleTOC(" + Index + ");return false;' onclick='MGCFrame.TOCLink(" + Index + "," + ID + ",\"" + Tag + "\");return false;' target='MGCDocumentContent'>";
        HTML += MGCFrame.BookData[MGCFrame.mHandle].toc[Index][2] + "</a></p>";
        TOC.push(HTML);
    }
    return TOC.join("\n");
}

// Remove highlighting Search hits
// Replaces RemoveSBHighlight and AddSBHighlight functions
function HighlightSidebar( container, hl_id, hl_class )
{
    // clear all TOC highlighting
    // the window.parent === window check is done for compatibility with different browsers.
    if ( window.parent === window ) {
        $("#" + container + " ." + hl_class).each( function() {
            $(this).removeClass(hl_class);
        });
        // highlight TOC entry
        $("#" + container + " #" + hl_id).addClass(hl_class);
    } else {
        parent.$("#" + container + " ." + hl_class).each( function() {
            $(this).removeClass(hl_class);
        });
        // highlight TOC entry
        parent.$("#" + container + " #" + hl_id).addClass(hl_class);
    }
}

function SearchTopicDisplay( ListID, ID, Tag, Handle, Highlight, Word, titles_only )
{
    // Remove any existing highlighting & add highlighting to the current hit
    var TopicID = "SearchHit" + ListID;
    HighlightSidebar("sidebarSearch", TopicID, "HighlightedResult");
    UpdateSearchButtons();
    TopicDisplay(ID, "", Handle, Highlight, Word, titles_only)
    CurrentQSearchHit = ListID;
}

// Handle updating the hash, and changing the source of the iframe to the appropiate document.
function TopicDisplay( ID, Tag, Handle, Highlight, Word, titles_only )
{
    if ( isNaN(ID) ) {
        ID = MGC_File_to_ID(Handle, MGC_MatchTopic(mHandle, BookData[mHandle].FirstTopic));
    }
    if ( typeof Tag == "undefined" || Tag == "" ) {
        Tag = MGCID_to_Topic(ID);
    }
    if ( typeof Handle == "undefined" || Handle == "" ) {
        Handle = mHandle;
    }
    if ( typeof Highlight != "undefined" && Highlight == 1 ) {
        HighlightSearchTerms = SearchHighlight.enabled;
    }
    if ( typeof titles_only != "undefined" && titles_only == true ) {
        SearchHighlight.titlesOnly = true;
    } else {
        SearchHighlight.titlesOnly = false;
    }

    // update browser hash
    mHash = "#context=" + Handle + "&id=" + ID;
    if ( Tag ) mHash += "&tag=" + Tag;
    if ( Popup ) mHash += "&single=popup";
    location.hash = mHash;

    // load topic
    LoadTopic( ID, Tag );
}

// Load topic in iframe and update TOC
function LoadTopic( ID, Tag )
{
    if ( isNaN(ID) ) {
        ID = MGC_File_to_ID(Handle, MGC_MatchTopic(mHandle, BookData[Handle].FirstTopic));
    }
    if ( typeof Tag == "undefined" || ! Tag ) {
        Tag = MGCID_to_Topic(ID);
    }

    // Update the TOC so that the current topic is expanded and highlighted
    var TOCIndex = GetTOCIndex(ID, Tag, mHandle);

    HighlightTOC(TOCIndex);
    if ( TOCIndex != null ) {
        // expand previous parent TOC entry if current TOC entry is hidden
        if ( TOCIndex > 0 ) {
            var PrevTOCIndex = TOCIndex - 1;
            var PrevTOCElement = document.getElementById("aTOCicon" + PrevTOCIndex);
            if ( typeof PrevTOCElement != "undefined" && PrevTOCElement && PrevTOCElement.className == "TOCplus" ) {
                ExpandTOC(PrevTOCIndex);
            }
        }
    }

    // reload iframe if search hit is already on last topic
    if ( fromQuickSearch && ID == LastTopic.ID && ! $.browser.msie && !DetectOnFileSystem()) {
        TopicFrame.location.reload();
    }

    LastTopic.ID = ID;
    LastTopic.tag = Tag;
    LastTopic.handle = mHandle;

    // load topic in iframe, use location.replace to not affect history
    var TopicFile = GetTopicURL(ID, Tag, mHandle);
    TopicFrame.location.replace(TopicFile);
}

function GetTopicURL( ID, Tag, Handle )
{
    if ( typeof (Handle) == "undefined" ) {
        Handle = mHandle;
    }
    if ( typeof Tag != "undefined" && Tag ) {
        if (Tag == "NoTaG") {
            Tag = "";
        }
        // JCB Account for "wp" vs. "id" in FM11/structured docs
        if (Tag.charAt(0) != "#") {
            // If it was built with FM11/DITA-OT, we do not use the "wp" prefix.
            var versionCompare = BookData[Handle].TemplateVer.indexOf("mgchelp");
            if(versionCompare > -1) {
              Tag = "#" + Tag;
            }
            else {
              Tag = "#wp" + Tag;
            }
        }
    } else {
        Tag = "";
    }
    var TopicFile = MGCTreeLoc + "/" + Handle + "/" + BookData[Handle].files[ID][0] + ".html" + Tag;
    return TopicFile;
}

function GetTOCIndex( ID, Tag, Handle )
{
    var TOCIndex = null;
    if (typeof (Handle) == "undefined") {
        Handle = mHandle;
    }

    if (typeof (Tag) != "undefined" && Tag) {
        Tag = Tag.replace(/^#wp/, "");
    } else {
        Tag = null;
    }
    var TOCLength = BookData[Handle].toc.length;
    var FoundIndex = -1;
    for (var Index = 0; Index < TOCLength; Index++) {
        var TopicID = BookData[Handle].toc[Index][1];
        if (TopicID == ID) {
            if (Tag) {
                if (BookData[Handle].toc[Index][3] == Tag) {
                    TOCIndex = Index;
                    break;
                } else if (FoundIndex < 0) {
                    FoundIndex = Index;
                }
            } else {
                // no requested tag, return first topic id that matches
                TOCIndex = Index;
                break;
            }
        } else if (TopicID > ID) {
            if (FoundIndex >= 0) {
                // didn't find tag, return first topic id that matches
                TOCIndex = FoundIndex;
            }
            break;
        }
    }
    return TOCIndex;
}

function TOCLink( TOCIndex, ID, Tag )
{
    // if the topic we're switching to is in the same file we're currently viewing,
    // a manual call to update the breadcrumbs is necessary.
    var update_breadcrumbs = (ID == LastTopic.ID) ? true : false;
    if ( DetectOnFileSystem() ) {
        TopicDisplay(ID,Tag);
        ShowTOC(TOCIndex);
    } else {
        // clicking on any topic should remove the book-level topic highlighting
        RemoveBookTopicHighlight();
        ShowTOC(TOCIndex);
        TopicDisplay(ID, Tag);
        if ( update_breadcrumbs ) {
            UpdateBreadcrumbs();
        }
    }
}

function ToggleTOC( ID, Handle )
{
    if (typeof (Handle) == "undefined") {
        Handle = mHandle;
    }
    var TOCElement = document.getElementById("aTOCicon" + (ID));
    if (typeof TOCElement != "undefined" && TOCElement) {
        var className = TOCElement.className;
        if (className == "TOCplus") {
            ExpandTOC(ID, Handle);
        } else if (className == "TOCminus") {
            CollapseTOC(ID, Handle);
        }
    }
}

function ExpandTOC( ID, Handle )
{
    if (typeof (Handle) == "undefined") {
        Handle = mHandle;
    }
    var TOCLevel = BookData[Handle].toc[ID][0];
    // change plus to minus
    var TOCElement = document.getElementById("aTOCicon" + ID);
    if (typeof TOCElement != "undefined" && TOCElement) {
        if (TOCElement.className == "TOCdoc") {
            if(mExpandTOC == false)
                return;
        }
        else {
            TOCElement.className = "TOCminus";
        }
    } else {
        return;
    }
    for (var Index = ID + 1; Index < BookData[Handle].toc.length; Index++) {
        var Level = BookData[Handle].toc[Index][0];
        // expand all subsequent TOC elements that are one level down
        if (Level == TOCLevel + 1) {
            TOCElement = document.getElementById("TOC" + Index);
            if (typeof TOCElement != "undefined" && TOCElement) {
                TOCElement.style.display = "block";
            }
        }
        // if element was previously expanded (has minus sign), re-expand it now
        var TOCElementIcon = document.getElementById("aTOCicon" + Index);
        if (typeof TOCElementIcon != "undefined" && TOCElementIcon && TOCElementIcon.className == "TOCminus") {
            ExpandTOC(Index);
        }
        // stop when we reach the next TOC element at the same level or higher
        if (Level <= TOCLevel) {
            break;
        }
    }
}

function CollapseTOC( ID, Handle )
{
    if (typeof (Handle) == "undefined") {
        Handle = mHandle;
    }
    var TOCLevel = BookData[Handle].toc[ID][0];
    var TOCElement = document.getElementById("aTOCicon" + ID);
    if (typeof TOCElement != "undefined" && TOCElement) {
        if (TOCElement.className == "TOCdoc") {
            return;
        }
        TOCElement.className = "TOCplus";
    } else {
        return;
    }
    for (var Index = ID + 1; Index < BookData[Handle].toc.length; Index++) {
        var Level = BookData[Handle].toc[Index][0];
        // collapse all subsequent TOC elements that are one or more levels down (higher number)
        if (Level > TOCLevel) {
            TOCElement = document.getElementById("TOC" + Index);
            if (typeof TOCElement != "undefined" && TOCElement) {
                TOCElement.style.display = "none";
            }
        }
        // stop when we reach the next TOC element at the same level
        if (Level == TOCLevel) {
            break;
        }
    }
}

function ShowTOC( ID, Handle )
{
    if ( ID == null ) {
        return;
    }
    if ( typeof (Handle) == "undefined" ) {
        Handle = mHandle;
    }
    var TOCLevel = BookData[Handle].toc[ID][0];
    if ( TOCLevel > 1 ) {
        // find parent elements and expand them
        var ParentLevel = TOCLevel - 1;
        for (var Index = ID - 1; Index >= 0; Index--) {
            var Level = BookData[Handle].toc[Index][0];
            // expand all parent TOC elements
            if ( Level == ParentLevel ) {
                ExpandTOC(Index);
                if ( ParentLevel > 1 ) {
                    ParentLevel--;
                } else {
                    break;
                }
            }
        }
    }
    ExpandTOC(ID);
}

function HighlightTOC( ID, Handle )
{
    if( DetectOnFileSystem() ) {
        return;
    }
    // if user is clicking on the title page, the title page does not have a TOC entry, so the ID will be null
    if ( ID == null ) {
        if (parent.window == window) {  // This check is done for browser compatibility
            $('#sidebarContent .TOCHighlight').each(function () {
                $(this).removeClass("TOCHighlight");
            });
        } else {
            parent.$('#sidebarContent .TOCHighlight').each(function () {
                $(this).removeClass("TOCHighlight");
            });
        }
        return;
    }
    // If the user isn't on the title page, then highlight the correct topic in the "Topics" bar.
    if ( typeof Handle == "undefined" ) {
        Handle = mHandle;
    }

    // clear all TOC highlighting
    if ( parent.window == window ) {  // This check is done for browser compatibility
        $('#sidebarContent .TOCHighlight').each(function () {
            $(this).removeClass("TOCHighlight");
        });

        // highlight TOC entry
        $('#aTOC' + ID).addClass("TOCHighlight");
    } else {
        parent.$('#sidebarContent .TOCHighlight').each(function () {
            $(this).removeClass("TOCHighlight");
        });

        // highlight TOC entry
        parent.$('#aTOC' + ID).addClass("TOCHighlight");
    }
}

function UpdateCurrentTopic()
{
    var FileID = null;
    var File = TopicFrame.CurrentFile;
    var TopicURL = TopicFrame.location.href;
    var Tag = null;
    // strip .html from filename
    if (File.indexOf(".html") > 0) {
        var Parts = File.split(".html");
        File = Parts[0];
    }
    // get current tag from content frame url
    if (TopicURL.indexOf("#") > 0) {
        var Parts = TopicURL.split("#");
        Tag = "#" + Parts[1];
    }
    // lookup file id from name
    var FilesLength = BookData[mHandle].files.length;
    for (var Index = 0; Index < FilesLength; Index++) {
        if (BookData[mHandle].files[Index][0] == File) {
            FileID = Index;
            break;
        }
    }
    // lookup topic id based on file id and tag
    var TopicID = GetTOCIndex(FileID, Tag);

    // refresh current topic in TOC using TopicID
    ShowTOC(TopicID);

    // JCB
    // For FM12 docs, explicitly highlight the current topic in the TOC tree.
    // Version check is needed because this used to work in FM8 and broke in FM12.
    // NB in FM8 days, the TemplateVer value had the form: mgc_ww_v3.2.203.
    var versionCompare = BookData[mHandle].TemplateVer.indexOf("mgchelp");
    if(versionCompare > -1)
      HighlightTOC(TopicID);
}

function RemoveBookTopicHighlight() {
    if (parent.window == window) {  // This check is done for browser compatibility
        $('.BookTopicHighlight', TopicFrame.document).each(function() {
            $(this).removeClass("BookTopicHighlight");
        });
    } else {
        parent.$('.BookTopicHighlight', TopicFrame.document).each(function() {
            $(this).removeClass("BookTopicHighlight");
        });
    }
}

function NextTopic()
{
    if ( LastTopic.ID < BookData[mHandle].files.length - 1 ) {
        // Get the next element in the TOC. On failure, fall back to the next file by using the old ID method of traversing the TOC
        //first, make sure that the .TOCHighlight class even exists
        next_toc_element = undefined;
        if ($('.TOCHighlight').length > 0) {
            next_toc_element = $('#aTOC' + (parseInt($('.TOCHighlight').attr("id").split("aTOC")[1]) + 1));
        }
        if (typeof next_toc_element != "undefined" && next_toc_element.length > 0) { //make sure we don't try going to an undefined TOC element if some error occurs here
            var elementID = parseInt($('.TOCHighlight').attr("id").split("aTOC")[1]) + 1;
            var BookDataElement = BookData[mHandle].toc[elementID];
            TOCLink(elementID, BookDataElement[1], BookDataElement[3]);
            RemoveBookTopicHighlight(); //remove any previous book topic highlights
            $('#MGC' + parseInt(next_toc_element.attr("href").split("#wp")[1]), TopicFrame.document).addClass("BookTopicHighlight");
            HighlightDocumentTopic = true;
            TopicToHighlight = "#MGC"+parseInt(next_toc_element.attr("href").split("#wp")[1]); //if document hasn't been loaded yet, we can't highlight anything.   This will apply the topic highlighting once the page is loaded
        } else {
            TopicDisplay(LastTopic.ID + 1);
        }
        UpdateNavButtons();

        if ( !DetectOnFileSystem() ) {
            // If the highlighted entry in the sidebar isn't fully in view, scroll highlighted up.
            if ( !SideBarContentInView('.TOCHighlight', '#sidebarTabs', '#sidebarContent') ) {
                $('#sidebarContent').stop().scrollTo($('.TOCHighlight'), 10, {
                    axis: 'y',
                    offset: ($('#sidebarContent').height() / 2 * -1)
                });
            }
        }
    }
}

function PrevTopic()
{
    if ( LastTopic.ID > 1 ) {
        // Get the previous element in the TOC. On failure, fall back to the next file by using the old ID method of traversing the TOC
        next_toc_element = undefined;
        if ($('.TOCHighlight').length > 0) {
            next_toc_element = $('#aTOC' + (parseInt($('.TOCHighlight').attr("id").split("aTOC")[1]) - 1));
        }
        if (typeof next_toc_element != "undefined" && next_toc_element.length > 0) {
            //next_toc_element.click();
            var elementID = parseInt($('.TOCHighlight').attr("id").split("aTOC")[1]) - 1;
            var BookDataElement = BookData[mHandle].toc[elementID]
            TOCLink(elementID, BookDataElement[1], BookDataElement[3])
            RemoveBookTopicHighlight();  //remove any previous book topic highlights
            $('#MGC' + parseInt(next_toc_element.attr("href").split("#wp")[1]), TopicFrame.document).addClass("BookTopicHighlight");
            HighlightDocumentTopic = true;
            TopicToHighlight = "#MGC"+parseInt(next_toc_element.attr("href").split("#wp")[1]);  //if document hasn't been loaded yet, we can't highlight anything.   This will apply the topic highlighting once the page is loaded
        } else {
            TopicDisplay(LastTopic.ID - 1);
        }
        UpdateNavButtons();

        // title page does not get highlighted in TOC
        if ( LastTopic.ID != 1 && !DetectOnFileSystem() ) {
            // If the highlighted entry in the sidebar isn't fully in view, scroll highlighted up.
            if (!SideBarContentInView('.TOCHighlight', '#sidebarTabs', '#sidebarContent')) {
                $('#sidebarContent').stop().scrollTo($('.TOCHighlight'), 10, {
                    axis: 'y',
                    offset: ($('#sidebarContent').height() / 2 * -1)
                });
            }
        }
    }
}


/////////////
//  Index  //
/////////////

function GetIndex( Letter )
{
    var IXContents = [];
    // by default, display all index letters
    var IXLetters = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "symbol"];
    if (typeof Letter == "string" && Letter != "" && IXLetters.join(",").indexOf(Letter.toLowerCase) != -1) {
        // valid index letter specified, just display entries that letter
        IXLetters = [];
        IXLetters[0] = Letter;
    }
    for (var IX = 0; IX < IXLetters.length; IX++) {
        Letter = IXLetters[IX];
        IXContents.push("<p class='pMGCindexSection' id='index_" + Letter + "'>" + Letter.toUpperCase() + "</p>");
        var IXArray = BookData[MGCFrame.mHandle]["index"][Letter];
        var IXLength = IXArray.length;
        var IXPrevPrimaryGroup = "";
        var IXPrevSecondaryGroup = "";
        var IXPrevTertiaryGroup = "";
        for (var Index = 0; Index < IXLength; Index++) {
            var IXLevel = IXArray[Index][0];
            var IXEntryName = IXArray[Index][2];
            if (IXLevel == 1) {
                IXPrevPrimaryGroup = "";
                IXPrevSecondaryGroup = "";
                IXPrevTertiaryGroup = "";
            } else if (IXLevel == 2) {
                var Parts = IXEntryName.split(":");
                // only add group name if first entry in group
                if (Parts[0] != IXPrevPrimaryGroup) {
                    IXContents.push("<p class='pMGCindextitle1'>" + Parts[0] + "</p>");
                    IXPrevSecondaryGroup = "";
                }
                IXPrevPrimaryGroup = Parts[0];
                IXEntryName = Parts[1];
            } else if (IXLevel == 3) {
                var Parts = IXEntryName.split(":");
                // only add group name if first primary entry in group
                if (Parts[0] != IXPrevPrimaryGroup) {
                    IXContents.push("<p class='pMGCindextitle1'>" + Parts[0] + "</p>");
                }
                // only add group name if first secondary entry in group
                if (Parts[1] != IXPrevSecondaryGroup) {
                    IXContents.push("<p class='pMGCindextitle2'>" + Parts[1] + "</p>");
                    IXPrevSecondaryGroup = "";
                }
                IXPrevPrimaryGroup = Parts[0];
                IXPrevSecondaryGroup = Parts[1];
                IXEntryName = Parts[2];
            } else if (IXLevel == 4) {
                var Parts = IXEntryName.split(":");
                // only add group name if first primary entry in group
                if (Parts[0] != IXPrevPrimaryGroup) {
                    IXContents.push("<p class='pMGCindextitle1'>" + Parts[0] + "</p>");
                }
                // only add group name if first secondary entry in group
                if (Parts[1] != IXPrevSecondaryGroup) {
                    IXContents.push("<p class='pMGCindextitle2'>" + Parts[1] + "</p>");
                    IXPrevSecondaryGroup = "";
                }
                // only add group name if first tertiary entry in group
                if (Parts[2] != IXPrevTertiaryGroup) {
                    IXContents.push("<p class='pMGCindextitle3'>" + Parts[2] + "</p>");
                    IXPrevTertiaryGroup = "";
                }
                IXPrevPrimaryGroup = Parts[0];
                IXPrevSecondaryGroup = Parts[1];
                IXPrevTertiaryGroup = Parts[2];
                IXEntryName = Parts[3];
            }
            // italicize "see also" and "see" index entries (both are valid)
            if (IXEntryName.match(/^see also/i)) {
                IXEntryName = IXEntryName.replace(/^see also/i, "<i>see also</i>");
            } else if (IXEntryName.match(/^see /i)) {
                IXEntryName = IXEntryName.replace(/^see/i, "<i>see</i>");
            }
            IXContents.push("<p class='pMGCindex" + IXLevel + "'><a href='javascript:MGCFrame.TopicDisplay(" + IXArray[Index][1] + ",\"" + IXArray[Index][3] + "\");'>" + IXEntryName + "</a></p>");
        }
    }
    return IXContents.join("\n");
}

function ScrollIndex( Letter )
{
    MGCSidebarScrollTo("#lettersections","#index_" + Letter);
}


////////////
// Search //
////////////

function SearchBook()
{
    AllSearchResults = [];
    AllSynonyms = [];
    SearchHighlight.synonymList = [];
    var SearchOptions = {
        include_synonyms: true,
        exact_match: false,
        infohubs: false,
        show_topic_titles: false
    };

    // make sure search results are visible
    $('#QSearchResults').css("display", "block");

    if ( $("#Stem").is(":visible") &&  $("#Stem").is(":checked")) {
        SearchOptions.exact_match = true;
    }
    if ( $("#IncSynonyms").is(":visible") &&  $("#IncSynonyms").is(":checked")) {
        SearchOptions.include_synonyms = false;
    }
    if ( $("#TitlesOnly").is(":visible") &&  $("#TitlesOnly").is(":checked")) {
        SearchOptions.show_topic_titles = true;
    }
    SearchHighlight.exactMatch = SearchOptions.exact_match;
    SearchHighlight.titlesOnly = SearchOptions.show_topic_titles;

    // get search words from input field and apply filter
    var query = $("#query");
    mSearchWords = applyWordFilter( query.val() );
    SearchWordArray = mSearchWords.split(" ");
    // update search input field to reflect changes
    query.val( mSearchWords );

    if ( (mSearchWords == "search this document" && query.css("color") == "rgb(119, 136, 153)") || mSearchWords == "" ) {
        return;
    }

    MGCExecuteSearch( mHandle, SearchWordArray, SearchOptions );

    AllSearchResults.sort(compareTotals);
    if ( typeof AllSearchResults[0] != "undefined" ) {
        FirstResult = ".html#SString1";
        CurrentQSearchHit = 0;
        HighlightSearchTerms = SearchHighlight.enabled;
    }

    if ( AllSearchResults.length != 0 ) {
        // Show first search result.
        // Setting the fromQuickSearch variable allows highlighting of the page
        // when the page the user searches from is the same as the page that the
        // first result result is on.  If this variable is not set, then in this case
        // nothing will be highlighted, since the page will not be reloaded
        fromQuickSearch = true;
        TopicDisplay(AllSearchResults[0].handle);
        fromQuickSearch = false;
    }
    DisplaySearchResults();
    HighlightSidebar( "sidebarSearch", "SearchHit0", "HighlightedResult" );
    UpdateSearchButtons();
    MGCSidebarScrollTo( "#QSearchResults", "#SearchHit0" );
}

function DisplaySearchResults()
{
    var resultStart = 0;
    var FramePath = MGCFrame;
    ResultsPerPage = 50;

    // quick results list for testing
    LibResults = [];
    handle = mHandle;
    var ihub = BookData[mHandle].IHUBHandle == "NONE" ? "mgc_ih" : BookData[mHandle].IHUBHandle;

    // Generate formatted list of all hits
    SNETLink = "https://support.sw.siemens.com/infohub.cfm?infohub=" + ihub + "&amp;query="
        + encodeURIComponent(mSearchWords) + "&amp;field=HTML";
    IHUBLink = "../index.html#infohub=" + ihub + "&amp;tab=search&amp;query="
        + encodeURIComponent(mSearchWords);

    // apply highlighting span to search words
    var search_words = "";
    var search_words_array = mSearchWords.split(" ");
    for ( var word in search_words_array ) {
        if ( typeof word != "undefined" ) {
            search_words += ' <span class="yellow_highlight">' + search_words_array[word] + '</span>';
        }
    }

    if ( AllSearchResults.length > 0 ) {
        var synonyms_array = unique(AllSynonyms);
        var synonyms_string = "";
        if ( synonyms_array.length > 0 ) {
            if ( synonyms_array.length > 1 ) {
                synonyms_string = "<span class='synonym_string'>, including these synonyms: ";
            } else {
                synonyms_string = "<span class='synonym_string'>, including this synonym: ";
            }
            for ( var synonym_counter in synonyms_array ) {
                synonyms_string += '<span class="green_highlight">'+synonyms_array[synonym_counter]+'</span>; ';
            }
            synonyms_string = synonyms_string.slice( 0, synonyms_string.length-2 );  //chop off back of string -> "; "
            synonyms_string = synonyms_string+"</span>";
        }

        SearchMessageContent = '<p class="search">' + SearchMessages.Searched4Begin + '<b>'
            + search_words + '</b>' + synonyms_string + '. ' + SearchMessages.SearchedShowing + ' '
            + AllSearchResults.length + SearchMessages.SearchedShowingE + '</p>';
    } else {
        SearchMessageContent = '<p class="search">' + SearchMessages.Searched4Begin + '<b>'
            + search_words + '</b>. ' + SearchMessages.NoSearchResults + '</p>';
        LibResults.push('<div class="NoResults">Search Tips:');
        LibResults.push('<ul><li>Enter keyword(s) to find answers within the <b>current document</b>.</li>');
        LibResults.push('<li>To broaden your search to include multiple documents, <a href="' + IHUBLink + '" target="_blank">resubmit this search within InfoHub</a></li></ul></div>');
    }

    $("#ResultMessage").html( SearchMessageContent );
    var ShowSnip = "Vis";
    if ( !MGCFrame.ShowSnippets ) ShowSnip = "Hid";
    LibResults = GenerateResults( resultStart, ResultsPerPage, LibResults );
    $("#QSearchResults").html( LibResults.join("\n") );
    MoreSearchOpts = SearchMessages.Searched4End;
    MoreSearchOpts += onSupportNet ? "" : "<a class='SearchHit' href='" + IHUBLink + "' title='Initiates the same search locally within InfoHub broadening it to include multiple documents' target='_blank'>InfoHub</a> or ";
    MoreSearchOpts += "<a class='SearchHit' href='" + SNETLink + "' title='Initiates the same search on Support Center broadening it to include the latest documents, TechNotes, AppNotes, and movies' target='_blank'>Support Center</a>.";
    $("#SearchMore").html( MoreSearchOpts ).show();
}

function GenerateResults( resultStart, numberOfResults, LibResults )
{
    if ( AllSearchResults.length > 0 ) {
        var syn = unique(AllSynonyms);
        var searchParams = "&amp;Sword=" + mSearchWords;
        if ( syn.length > 0 ) searchParams += "&amp;Syn=" + syn.join(" ");
        searchParams = encodeURI(searchParams);
        LibResults.push("<ol class='SearchHit'>\n");
        for ( var LSIndex = resultStart, i=0; LSIndex < AllSearchResults.length && i < numberOfResults; LSIndex++, i++ ) {
            LibResults.push("<li value=\"" + (LSIndex+1)
                + "\" class='SearchHit' id='SearchHit" + (LSIndex) + "' name='SearchHit" + (LSIndex)
                + "'><a class='SearchHit' href='#context="+ AllSearchResults[LSIndex].book + "&amp;id=" + AllSearchResults[LSIndex].handle + searchParams
                + "' onclick='SearchTopicDisplay(" + LSIndex + ", " + AllSearchResults[LSIndex].file_link + ";return false;'  title='Found "
                + AllSearchResults[LSIndex].word_count  + " of "+  mSearchWords.split(" ").length+ " words.  Words matched: "
                + AllSearchResults[LSIndex].matching_word.replace(/^\s+|\s+$/g, '').replace("'", "&#39;").replace(/\s/g,", ")+ ".  Relevance: "
                + AllSearchResults[LSIndex].weight + "'>" + AllSearchResults[LSIndex].doc_title
                + "</a><br />"
                + AllSearchResults[LSIndex].snippet +"</li>");
        }
        LibResults.push("</ol>");
        if ( ((resultStart+1) - ResultsPerPage ) > 0 ) {
            LibResults.push("<a style='padding-left:30px' href= javascript:UpdateSearchResults(" + ((resultStart)-ResultsPerPage) + "," + ResultsPerPage + ")>Previous<\a>");
        }
        if ( (LSIndex+1) < AllSearchResults.length ) {
            LibResults.push("<a style='float: right; padding-right: 35px;' href= javascript:UpdateSearchResults(" + (LSIndex) + "," + ResultsPerPage + ")>Next<\a>");
        }
    }
    MGCFrame.resultStart = resultStart;
    return LibResults;
}

function UpdateSearchResults( resultStart, numberOfResults )
{
     $("#QSearchResults").html("");
     LibResults = [];
     LibResults = GenerateResults( resultStart, numberOfResults, LibResults );
     LibResults = LibResults.join("");
     $("#QSearchResults").html(LibResults);

     // Highlight the top of the result list.
     var resultTop = 'SearchHit' + resultStart;
     HighlightSidebar('sidebarSearch', resultTop, 'HighlightedResult');
     UpdateSearchButtons();
     if ( !SideBarContentInView(".HighlightedResult", "#sidebarTabs, #SearchSidebarHeaderWrap", "#QSearchResults") ) {
        $("#QSearchResults").stop().scrollTo($(".HighlightedResult"), 10, {
            axis: "y",
            offset: ($("#QSearchResults").height() / 2 * -1)
        });
    }
}

function UpdateSearchResultBody()
{
    SearchBook();
    DisplaySearchResults();
    HighlightSidebar( 'sidebarSearch', 'SearchHit0', 'HighlightedResult' );
    UpdateSearchButtons();
}

// Search functions, mainly dealing with the "Apply Filters" slidedown menu.
function PaginateSearchResults()
{
    var currentPage = 0;
    var disabledPrev = true;
    var disabledNext = false;
    var numRows;
    var numPages;
    var $table;
    var filter_checked = [];
    var current_limit = 0;
    var DefaultResultsNumber = 50;
    $search_results_frame = MGCFrame.document


    $("#QSearchResults").animate( {top: "293px"}, 500 );
    $("#AdvancedSearch").slideDown("1500");

    $(".apply_filter").click(function () {
        UpdateSearchResultBody();
    });

    // handle coloring of checkboxes & labels
    // Note the click function is superfulous but we still addClass("checkbox_selected")
    $(".AdvSearch").click(function() {
        $(".AdvSearch").each(function() {
            // $("#ApplyFilterButton").removeClass("disabled");
        });
    }).each(function () {
        if ($(this).is(":checked")) {
            $(this).next().addClass("checkbox_selected");
            filter_checked[$(this).attr("id")] = true;
        } else {
            filter_checked[$(this).attr("id")] = false;
        }
    });
}

function NextSearchResult()
{
    UpdateSearchButtons();
    var currentElement = $(".HighlightedResult").attr("value"); // value is SearchHit#+1
    $("#SearchHit" + currentElement + " a").click(); // use onclick event of link to go to next topic
    UpdateNavButtons();
    // make sure that highlighted element is not hidden off the page
    if ( !SideBarContentInView(".HighlightedResult", "#sidebarTabs, #SearchSidebarHeaderWrap", "#QSearchResults") ) {
        $("#QSearchResults").stop().scrollTo($(".HighlightedResult"), 10, {
            axis: "y",
            offset: ($("#QSearchResults").height() / 2 * -1)
        });
    }
}

function PrevSearchResult()
{
    UpdateSearchButtons();
    var currentElement = $(".HighlightedResult").attr("value") - 2; // value is SearchHit#+1
    $("#SearchHit" + currentElement + " a").click(); // use onclick event of link to go to prev topic
    UpdateNavButtons();
    // make sure that highlighted element is not hidden off the page
    if ( !SideBarContentInView(".HighlightedResult", "#sidebarTabs, #SearchSidebarHeaderWrap", "#QSearchResults") ) {
        $("#QSearchResults").stop().scrollTo($(".HighlightedResult"), 10, {
            axis: "y",
            offset: ($("#QSearchResults").height() / 2 * -1)
        });
    }
}

// Controls the enabling/disabling of the Next/Previous search result buttons.
function UpdateSearchButtons()
{
    var currentItem = parseInt($('li.HighlightedResult').attr('value'));
    var TotalResultNumber = MGCFrame.AllSearchResults.length;

    // Check to see that the next result is not the last element in our set- if it is, then disable the Next button
    if ( (currentItem + 1) > TotalResultNumber ) {
        $('.SearchNextButton').addClass('SearchNextButtonX').removeClass('SearchNextButton').click(function() {
            return false
        });
    } else {
        $('.SearchNextButtonX').addClass('SearchNextButton').removeClass('SearchNextButtonX').unbind('click');
    }

    // If we are on the first element, disable the Previous button
    if ( (currentItem - 1) < 1 ) {
        $('.SearchPrevButton').addClass('SearchPrevButtonX').removeClass('SearchPrevButton').click(function() {
            return false
        });
    } else {
        $('.SearchPrevButtonX').addClass('SearchPrevButton').removeClass('SearchPrevButtonX').unbind("click");
    }
}

function SearchBox_Focus()
{
    // turn off keyboard shortcuts when search field selected
    KeyboardShortcuts = false;
    var q = $("#query");
    if ( q.val() == SearchMessages.QSPrompt ) {
        q.val("");
    }
    q.css("color", "black");
}

function SearchBox_Blur()
{
    // turn keyboard shortcuts back on
    KeyboardShortcuts = true;
    var q = $("#query");
    q.css("color", "black");
    if ( q.val() == "" ) {
        q.css("color", "#778899");
        q.val(SearchMessages.QSPrompt);
    }
}

function ToggleHighlight()
{
    SearchHighlight.enabled = (!SearchHighlight.enabled);
    // Update highlight message & icon in sidebar
    HighlightSearchTerms = SearchHighlight.enabled;
    if ( SearchHighlight.enabled ) {
        // update highlight button
        $("#HighlightButton").addClass("HighlightButton_s").removeClass("HighlightButton").attr("title", Button.Titles["highlight_on"]);
        // Remove transparent style for all highlighted objects
        $(".cSHighlightDisabled", TopicFrame.document).addClass("cSHighlight").removeClass("cSHighlightDisabled");
        $(".cSHighlightSynmDisabled", TopicFrame.document).addClass("csHighlightSynm").removeClass("cSHighlightSynmDisabled");
    } else {
        $("#HighlightButton").addClass("HighlightButton").removeClass("HighlightButton_s").attr("title", Button.Titles["highlight_off"]);
        // Change highlight style to transparent for all highlighted objects
        $(".cSHighlight", TopicFrame.document).addClass("cSHighlightDisabled").removeClass("cSHighlight");
        $(".cSHighlightSynm", TopicFrame.document).addClass("csHighlightSynmDisabled").removeClass("cSHighlightSynm");
    }
}


/////////////////////////
// Search Highlighting //
/////////////////////////

//To correctly highlight everything in a document, we needed to develop a recursive regular expression.
//For the following example, assume we're trying to highlight "foo"

//"The following feature is foo.  It allows the user to foo and bar while fooing!"
//The recursive regular expression splits every string into three parts-  one before the word it matches, one containing the word, then one containing everything after the word
//this allows us to apply a highlighting style to the word and do the necessary DOM modification to rebuild the DOM tree recursively.   When we apply highlighting, we're actually recursivily
//traversing the entire tree and rebuilding it, wrapping things that need to be highlighted in spans that allow us to identify it and apply a highlight to them.
//So, in the above example, we have three parts:

//p1:"The following feature is "
//p2:"foo"
//p3:".  It allows the user to foo and bar while fooing!"

//The original splitting is done by replaceText (a recursive helper function) and then the major work is done by do_replace.
//do_replace determines if p2 contains a string that needs to be highlighted, then modifies the DOM tree as needed to accomplish this.
//It also takes a look at p3, and if there are any more search words in the string, calls itself on it again.  For the above p3, this would look like this:
//p1:". It allows the user to "
//p2: "foo"
//p3: " and bar while fooing!"
//It then repeats the above process, calling itself again on p3
//p1:" and bar while "
//p2:"fooing"
//p3:"!"

//Since there are no more instances of "foo" in p3, the function starts to return and rebuild the DOM tree for this string.
//It does this for every string, although if there are no matches for the search term, there are no recursive calls to do, so the DOM object for the string is not modified at all.
//DOM object modification only happens when a search word is found in the string.

function MGCHighlightSearchTerms( searchText )
{
    //escape regular expression characters
    var rere = new RegExp("([({[^$*+?\\*\\\]})])", "g"); /* you need 2 '\' s to mean 1 '\' and another '\' to treat ']' as special character instead of the characters ending bracket */
    var searchArray = searchText.split(" ");
    for ( var j in searchArray ) {
        searchArray[j] = searchArray[j].replace(rere, "\\$1");
    }
    if ( !TopicFrame.document.body || typeof TopicFrame.document.body.innerHTML == "undefined" ) {
        return false;
    }

    SearchHighlight.preWildcard = false;
    SearchHighlight.postWildcard = false;
    // Get contents of body div, which doesn't include breadcrumbs or footer content
    szDivID = "BodyContent";
    //go through each of the words in the Synonym list and the search query, add highlighting name to them
    for ( var i = 0; i < searchArray.length; i++ ) {
        //determine whether or not user has specified an asterisk in their search query.  If they have, we will disable automatic stemming (assuming they
        //did not put the asterisk in at the end of the string)
        if ( searchArray[i].charAt(1) == "*" ) {
            SearchHighlight.preWildcard = true;
        }
        if ( searchArray[i].charAt(searchArray[i].length - 1) == "*" || (SearchHighlight.preWildcard != true && SearchHighlight.exactMatch == false) ) {
            SearchHighlight.postWildcard = true;
        }
        searchArray[i] = searchArray[i].replace(/^\\\*/, "");
        searchArray[i] = searchArray[i].replace(/\\\*$/, "");
        if ( SearchHighlight.exactMatch || (searchArray[i].length <= 2) ) {
            SearchHighlight.postWildcard = false;
            SearchHighlight.preWildcard = false;
        } //exact mode if work is two or less characters
        MGCHighlight(searchArray[i], false);
    }
    if ( SearchHighlight.synonymList ) {
        for ( var i = 0; i < SearchHighlight.synonymList.length; i++ ) {
            MGCHighlight( SearchHighlight.synonymList[i], true );
        }
    }

    if ( ! SearchHighlight.enabled ) {
        // Change highlight style to transparent for all highlighted objects
        $('.cSHighlight', TopicFrame.document).addClass("cSHighlightDisabled");
        $('.cSHighlightSynm', TopicFrame.document).removeClass("csHighlightSynmDisabled");
    }
    OnlyBodyText = "";
    return true;
}

function MGCHighlight( searchTerm, synonym )
{
    SearchHighlight.searchWord = searchTerm;
    var syn_highlight = "";
    if (synonym == true) {
        syn_highlight = "cSHighlightSynm";
    } else {
        syn_highlight = "cSHighlight";
    }

    //There are 4 different regular expressions here.   "single_word_pattern" is a regular expression that matches words that start at the beginning of a string:
    //for example, if the highlighted word is suppose to be "foo" and our string is " foo is the best function" then we would use the "single_word_pattern" pattern to match this
    //otherwise, if foo is not at the beginning of a string, we will use the "pattern" string.

    //Exact_match makes the matching rules a lot more strict.   When a word is <= 2 characters, no matter what the user settings, we apply the exact filter to the word.
    //This is what the first part of the code is doing here.

    //Let's take a look at the non-exact pattern first, since it's easier to understand:

    //pattern = new RegExp('([\\w\\W]*?[=:;\\.\\,\\(\\)\\|<>\\s\\[\\]]+)('+searchTerm + '[\\w\\-]*)([=:;\\.\\,\\(\\)\\|<>\\s\\[\\]]+[\\w\\W]*)',"i");
    //pattern = new RegExp  -> basic first part of regex:
    //('([\\w\\W]*?  -> Any number of words before the string-  matches the first part of a string that does not have the word we want to highlight in it
    //this substring goes into the first variable, and will be reinserted into the document later.
    //[=:;\\.\\,\\(\\)\\|<>\\s\\[\\]]+)->  requires one or more symbols/spaces before the word we're trying to highlight.  Using the \b character turned out to be too inexact
    //for our purposes, so I defined a list of characters that could be border characters.   For the most part we'll see [,],\s,|,= matching here
    //('+searchTerm + '[\\w\\-]*) ->  matches the acual word (it must be at the beginning of the word) and the following suffix/command name.  if searching for "restart" this will highlight
    //"restarting", "restart-command", and restart.  This is by design for the non-exact match regular expression
    //([=:;\\.\\,\\(\\)\\|<>\\s\\[\\]]+ -> word must have stuff behind it. (might be a bug here and relax this, but not a problem so far.
    //[\\w\\W]*)',"i");  -> any number of words after the word we wish to highlight.  We will process this string later.

    //the single_word_pattern was written to deal with things like "restart" and  " restart" where all the conditions of the first regular expression couldn't be met.  I was unable to
    //generate a regular expression to match both cases with a good deal of accuracy, so I developed two expressions.  This might be able to be condensed to one regular expression
    //now that we are not using the /b character.  This expression is pretty much the same, the only difference (besides not matching words before the searchTerm) is that everything
    //following the searchTerm is optional.  In "pattern" I use the "+" (one or more) matching character on the custom character class I wrote.  Here we use the * (0 or more) for the
    //same class.

    //4 cases:
    if ( SearchHighlight.preWildcard && !SearchHighlight.postWildcard ) {
        pattern = new RegExp('([\\w\\W]*?)([' + SearchHighlight.wildcardCharsAllowed + '\\w]*' + searchTerm + '(?!\\-|\\w))([' + SearchHighlight.charsAllowed + ']+[\\w\\W]*)',"i")
        single_word_pattern = new RegExp('([\\s]*)([' + SearchHighlight.wildcardCharsAllowed + '\\w]*' + searchTerm + '(?!\\-|\\w))([' + SearchHighlight.charsAllowed + ']*?\\s+(?=([\\w\\W]*)))',"i");
    }
    if ( SearchHighlight.preWildcard && SearchHighlight.postWildcard ) {
        pattern = new RegExp('([\\w\\W]*?)([' + SearchHighlight.wildcardCharsAllowed + '\\w]*' + searchTerm + '[\\w\\-]*)([' + SearchHighlight.charsAllowed + '\\w]+[\\w\\W]*)',"i");
        single_word_pattern = new RegExp('([\\s]*)([' + SearchHighlight.wildcardCharsAllowed + '\\w]*' + searchTerm + '[\\w]*)[\\b]*([\\w\\W]*)',"i");
    }
    if ( !SearchHighlight.preWildcard && SearchHighlight.postWildcard ) { // (existing "normal")
        pattern = new RegExp('([\\w\\W]*?[' + SearchHighlight.charsAllowed + ']+)(' + searchTerm + '[\\w\\-]*)([' + SearchHighlight.charsAllowed + ']+[\\w\\W]*)',"i");
        single_word_pattern = new RegExp('([\\s]*)(' + searchTerm + '[\\w]*)[\\b]*([\\w\\W]*)',"i");
    }
    if ( !SearchHighlight.preWildcard && !SearchHighlight.postWildcard ) { // "exact" match case
        //this pattern is pretty much the same as the one I explained above, so I will only point out the differences.  The main difference is that we do not allow any suffixes
        //or allow things like "restart-command" to be highlighted when we're trying to highlight "restart".  This is accomplished by removing the "[\\w\\-]*)" part of the regular expression
        //that we used above.   We also use a "negative-lookahead" to prevent things like "restart-command"
        //(?!\\-|\\w)) <-  This is the negative lookahead.  This does not consume any characters, and will not allow the regular expression to match words that use searchTerm followed by
        //a "-" or any word characters.   This also prevents things like "restarting" from matching when we're trying to highlight "restart".

        //There are some known bugs, but hopefully nothing too major.  Strings like test.restart still match when a user searches for "restart", however for the majority of the use cases
        //that were seen in the code, it works fine.

        pattern = new RegExp('([\\w\\W]*?[' + SearchHighlight.charsAllowed + ']+)(' + searchTerm + '(?!\\-|\\w))([' + SearchHighlight.charsAllowed + ']+[\\w\\W]*)',"i");
        //old pattern pattern = new RegExp('([\\w\\W]*?\\b[\\W]*?)('+ searchTerm + '\\b)([\\w\\W]*)',"i");
        single_word_pattern = new RegExp('([\\s]*)(' + searchTerm + '(?!\\-|\\w))([' + SearchHighlight.charsAllowed + ']*?\\s+(?=([\\w\\W]*)))',"i");
    }

    replaceText( $('#BodyContent',TopicFrame.document)[0], pattern, single_word_pattern, syn_highlight );
}

function replaceText( element, pattern, single_word_pattern, syn_text )
{
    var original_length = element.childNodes.length;
    var chosen_pattern = ""; //variable to switch highlighting patterns based on number of words.
    for ( var childi = 0; childi < element.childNodes.length; childi++ ) {
        var child = element.childNodes[childi];

        if (child.nodeType == 1 && child.className != syn_text) { //make sure we don't call function on newly created node
            replaceText(child, pattern, single_word_pattern, syn_text); //call function on child
        } else if (child.nodeType == 3) { //this is a text node, being processing with our regular expression
            var str = child.data;
            //look for 1 word strings - these can not be parsed by our normal pattern, so we have to use a special "single" word pattern
            //to match these words.  When we've got to make an exact match we must restrict what we match with a negative-lookahead.
            //This is explained further down in the code.
            if ( ! SearchHighlight.exactMatch ) {
                if (SearchHighlight.preWildcard) {
                    singleWordTest = new RegExp( '^[\\s]*[=:;~_<>%/\*\.\,\(\)\,\(\)\\\w]*' + SearchHighlight.searchWord + '$', "gi");
                }
                if (SearchHighlight.postWildcard) {
                    singleWordTest = new RegExp( '^[\\s]*' + SearchHighlight.searchWord, "gi");
                }
                if (!SearchHighlight.preWildcard && !SearchHighlight.postWildcard) {
                    singleWordTest = new RegExp( '^[\\s]*' + SearchHighlight.searchWord + '(?!\\-|\\w)[' + SearchHighlight.charsAllowed + ']+', "gi" );
                }
            } else {  //exact match
                singleWordTest = new RegExp( '^[\\s]*' + SearchHighlight.searchWord + '(?!\\-|\\w)[' + SearchHighlight.charsAllowed + ']+', "gi" );
            }
            if (singleWordTest.test(str)) {
                chosen_pattern = single_word_pattern;
            } else {
                chosen_pattern = pattern;
            }
            str = str.replace( chosen_pattern, function( s, p1, p2, p3, p4 ) {
                // when using the single_word_pattern and not wildcarding ends or have the "exact match" functionality turned on,
                // there can be a p4 variable which should be combined to p3.
                if ( p4 != 0 && p4 != "" ) p3 += p4;
                var parentNode = child.parentNode;
                do_replace(s, p1, p2, p3, child, syn_text);
                // delete old child from parent node, replaced with new nodes at this point
                parentNode.removeChild(child);
            });
        }
    }
}

function do_replace( s, p1, p2, p3, child_node, syn_text )
{
    reg = new RegExp('[h\|H][1-7]');
    if ( p1.length > 0 ) { //this might not be necessary
        //create textnode
        var text_node = TopicFrame.document.createTextNode(p1);
        child_node.parentNode.insertBefore(text_node, child_node);
    }
    if ( p2.length > 0 ) { //create a span + next_node for the highlighting code
        if ((SearchHighlight.titlesOnly && reg.test(child_node.parentNode.localName)) || SearchHighlight.titlesOnly == false) {
            spanTag = TopicFrame.document.createElement("span");
            spanTag.setAttribute("name", "SString");
            spanTag.className = syn_text;
            spanTag.innerHTML = $("<div/>").text(p2).html();
        } else {
            spanTag = TopicFrame.document.createTextNode(p2);
        }
        child_node.parentNode.insertBefore(spanTag, child_node);
    }
    if ( p3.length > 0 ) {
        //test to see if p3 contains another instance of our string.
        var singleWordTest;
        //This is the same test we did earlier in the recursive-helper function "replace-text"  As we process the string (p3) we need to keep
        //verifying which highlighting string should be applied...  This helps fix a corner case where two words that need to be highlighted are
        //written one after the other, eg:  "a foo foo bar" where we're trying to highlight "foo."  However, this might help highlight some legit
        //cases as well that haven't been considered.
        if ( ! SearchHighlight.exactMatch ) {
            if ( SearchHighlight.preWildcard ) {
                singleWordTest = new RegExp('^[\\s]*[=:;~_<>%/\*\.\,\(\)\,\(\)\\\w]*' + SearchHighlight.searchWord + '$', "gi");
            }
            if ( SearchHighlight.postWildcard ) {
                singleWordTest = new RegExp('^[\\s]*' + SearchHighlight.searchWord, "gi");
            }
            if( !SearchHighlight.preWildcard && !SearchHighlight.postWildcard ) {
                singleWordTest = new RegExp('^[\\s]*' + SearchHighlight.searchWord + '(?!\\-|\\w)[' + SearchHighlight.charsAllowed + ']+',"gi");
            }
        } else {  //exact match
            singleWordTest = new RegExp('^[\\s]*' + SearchHighlight.searchWord + '(?!\\-|\\w)[' + SearchHighlight.charsAllowed + ']+',"gi");
        }
        if ( singleWordTest.test(p3) ) {
            chosen_pattern = single_word_pattern;
        } else {
            chosen_pattern = pattern;
        }
        if ( chosen_pattern.test(p3) ) {
            //if there is a instance of our text string in the third part of the string, call function again
            p3.replace( chosen_pattern, function( s, p1, p2, p3, p4 ) {
                if ( p4 != 0 && p4 != "" ) {
                    p3+=p4;
                }
                do_replace( s, p1, p2, p3, child_node, syn_text );
                return;
            });
        } else {
            //otherwise, it's just a plain textnode, so just reinsert it
            var text_nodep3 = TopicFrame.document.createTextNode(p3);
            child_node.parentNode.insertBefore(text_nodep3, child_node);
            return;
        }
    }
    return;
}


/////////////
//  Style  //
/////////////

function MGCStyleSheets()
{
    var AllStylesHTML = "";
    AllStylesHTML += MGCGenerateBodyStyle();
    AllStylesHTML += "\n<link rel='stylesheet' href='" + MGCTreeLoc + "/MGC/styles/document.css' />";
    AllStylesHTML += "\n<link rel='stylesheet' href='" + MGCTreeLoc + "/MGC/styles/catalog.css' />";
    return AllStylesHTML;
}

function MGCGenerateBodyStyle()
{
    var BodyHTML = "";
    BodyHTML += "\n<style type=\"text/css\">\n";
    BodyHTML += " body {\n";
    if ( BookData[mHandle].Draft ) {
        BodyHTML += "background-image: url(" + MGCTreeLoc + "/MGC/images/draft.gif);\n";
    }
    if ( BookData[mHandle].Draft ) {
        BodyHTML += "   background-color: transparent;\n";
    } else {
        BodyHTML += "   background-color: white;\n";
    }
    BodyHTML += "   height: 100%;\n";
    BodyHTML += "   color: black;\n";
    BodyHTML += "   font-family: Verdana, Arial, Tahoma, sans-serif;\n";
    BodyHTML += "   font-size: " + BaseBodyFontSize + "px;\n";
    BodyHTML += "   font-variant: normal;\n";
    BodyHTML += "   font-style: normal;\n";
    BodyHTML += "   font-weight: normal;\n";
    BodyHTML += "   text-decoration: none;\n";
    BodyHTML += "   text-indent: 0px;\n";
    BodyHTML += "   text-transform: none;\n";
    BodyHTML += "   text-align: left;\n";
    BodyHTML += "   margin: 1em 1em 2em 1em;\n";
    BodyHTML += " }\n";
    BodyHTML += "</style>\n";
    return BodyHTML;
}

function MGCFontSize()
{
   //Specify fonts based on browser
   BaseFontColor = "Black";
   BaseBodyFontSize = 10;
   BaseBodyFonts = {};
   BaseBodyFonts["Windows"] = [11,13,15];
   BaseBodyFonts["Unix"] = [12,14,16];
   BaseBodyFonts["Linux"] = [11,13,15];
   BaseBodyFonts["Mac"] = [10,12,14];
   BaseBodyFontSize = BaseBodyFonts[operatingsystem][1];
   BaseNavFonts = {};
   BaseNavFonts["Windows"] = [9,11,13];
   BaseNavFonts["Unix"] = [10,12,14];
   BaseNavFonts["Linux"] = [9,11,13];
   BaseNavFonts["Mac"] = [9,11,13];
   BaseNavFontSize = BaseNavFonts[operatingsystem][1];
   BaseBodyFontSizeID = 1;
   BaseNavFontSizeID = 1;
   //Load users font settings
   if (MGCCookiesEnabled() != null)
   {
      if (MGCGetCookie("MGCBaseNavFontSizeID") != null)
      {
         BaseNavFontSizeID = MGCGetCookie("MGCBaseNavFontSizeID");
         BaseNavFontSize = BaseNavFonts[operatingsystem][BaseNavFontSizeID];
      }
      if (MGCGetCookie("MGCBaseBodyFontSizeID") != null)
      {
         BaseBodyFontSizeID = MGCGetCookie("MGCBaseBodyFontSizeID");
         BaseBodyFontSize = BaseBodyFonts[operatingsystem][BaseBodyFontSizeID];
      }
   }
}

function MGCChangeBaseFontSize(size)
{
    if ((size == 0) || (size == 1) || (size == 2)) {
        BaseBodyFontSize = BaseBodyFonts[operatingsystem][size];
        BaseNavFontSize = BaseNavFonts[operatingsystem][size];
        BaseBodyFontSizeID = size;
        BaseNavFontSizeID = size;
        $("body").css("font-size", BaseNavFontSize);
        if ( typeof TopicFrame != "undefined" ) {
            $("#DocBody", TopicFrame.document).css("font-size", BaseBodyFontSize);
        }
        if (MGCCookiesEnabled() != null) {
            MGCSetCookie("MGCBaseBodyFontSizeID", size);
            MGCSetCookie("MGCBaseNavFontSizeID", size);
        }
    }
}

// Handle all global CSS changes which are required for different browsers
function ChangeBrowserCSS()
{
    if ( $.browser.msie ) {
        // IE7 rendering mode needs adjustment (may actually be IE8 in compatibility mode)
        if( $.browser.version == "7.0" ) {
            $("html").css("overflow", "hidden");
            $("#query").css("padding-top", "3px");
        } else if ( $.browser.version == "8.0" ) {
            $("#query").css("padding-top", "3px");
        }
        // this filter property is not valid CSS, but needed for opacity in IE
        $("#dragdetector").css("filter", "alpha(opacity=0)");
    }
    // Chrome on the local file system doesn't support text size changes in iframe
    if( DetectOnFileSystem() ) {
        $("#resize_button").hide();
    }
}

function MGCInsertRTFooter()
{
    var FooterHTML = "";
    var PropertiesHTML = "";
    var Copyright = BookData[mHandle].Copyright;
    var SWRelease = BookData[mHandle].SWRelease;

    if ( TopicFrame.CurrentFile == BookData[mHandle].FirstPage + ".html" ) {

        // JCB
        // Need to do a version check here to get the right path to the graphic. FM8 books have "wv" instead of "mgchelp" in templatever
        var versionCompare = BookData[mHandle].TemplateVer.indexOf("mgchelp");
        var splashPath = "";

        // License check to remove logo on Siemens books
        if(!(BookData[mHandle]["LicenseType"].toLowerCase().indexOf("siemens") >= 0)) {
             if(versionCompare > -1) {
               splashPath = "../../MGC/images/splash_screen_bottom2.gif";
             }
             else {
               splashPath = "../MGC/images/splash_screen_bottom2.gif";
            }
        }

        FooterHTML += "<br /><table width=\"90\%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" background=";
        FooterHTML  = FooterHTML + "\"" + splashPath + "\"><tr height=\"200\"><td>&#160;</td></tr></table>";
        FooterHTML += "<div id=\"Options\" class=\"Options\"><p class=\"Options\">&#160;</p></div>\n";
        $("#Footer", TopicFrame.document).html(FooterHTML);

        PropertiesHTML = "<p class=\"pLegal\"><a href=\"javascript:MGCFrame.DocProperties()\">Properties</a></p>";
        $("#Properties", TopicFrame.document).html(PropertiesHTML);
        return;
    }

    // JCB - Changed code here to use BookData[mHandle] instead of global variables defined in the footer of each HTML file.
    FooterHTML += "<div class=\"MGCFooter\">";
    if ( BookData[mHandle].Draft ) {
        FooterHTML += "<p class=\"pMGCFooter\"><span class=\"cBold\">DRAFT</span></p>\n";
    }
    if ( typeof BookData[mHandle].ALPHA == "boolean" && BookData[mHandle].ALPHA ) {
        FooterHTML += "<p class=\"pMGCFooter\"><span class=\"cBold\">Alpha Release</span></p>\n";
    }
    if ( typeof BookData[mHandle].BETA == "boolean" && BookData[mHandle].BETA ) {
        FooterHTML += "<p class=\"pMGCFooter\"><span class=\"cBold\">Beta Release</span></p>\n";
    }
    FooterHTML += "<p class=\"pMGCFooter\">" + BookData[mHandle].DocTitle + ",&#160;" + SWRelease + "</p>\n";
    if ( BookData[mHandle].ThirdParty != 'YES' ) {
        FooterHTML += "<p class=\"pMGCFooter\">Unpublished work. &#169;&#160;Siemens " + Copyright + "</p>";
    } else {
        FooterHTML += "<p class=\"pMGCFooter\">Unpublished work. &#169;&#160;Siemens " + Copyright + "&#160;" + BookData[mHandle].ThirdPartyLine + "</p>";
    }
    FooterHTML += "</div>";
    $("#Footer", TopicFrame.document).html(FooterHTML);
}


/////////////
// Cookies //
/////////////

function MGCCookiesEnabled()
{
    CookiesEnabled = false;
    // Try setting a cookie
    MGCSetCookie("MGCCookiesEnabled", "True");
    // Retrieve the cookie
    if ( MGCGetCookie("MGCCookiesEnabled") != null ) {
        // Delete the test cookie
        MGCDeleteCookie("MGCCookiesEnabled");
        // Success
        CookiesEnabled = true;
    }
    return CookiesEnabled;
}

function MGCGetCookie( name )
{
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for ( var i = 0; i < ca.length; i++ ) {
        var c = ca[i];
        while ( c.charAt(0) == ' ' ) c = c.substring(1, c.length);
        if ( c.indexOf(nameEQ) == 0 ) return c.substring( nameEQ.length, c.length );
    }
    return null;
}

function MGCDeleteCookie( ParamName )
{
    // Set cookie to expire yesterday
    MGCSetCookie(ParamName, "", -1);
}

function MGCSetCookie( Name, Value, SixMonthExp )
{
    var expiration = "";
    var eValue = escape(Value);
    var exp = new Date();
    var expirationTime;

    if(SixMonthExp == true) {
        expirationTime = exp.getTime() + (182 * 24 * 60 * 60 * 1000);
    }
    else {
        expirationTime = exp.getTime() + (365 * 24 * 60 * 60 * 1000);
    }

    exp.setTime(expirationTime);
    expiration = ';expires=' + exp.toGMTString();
    document.cookie = Name + "\=" + eValue + "\;path=/" + expiration;
}


///////////////////////
// Browser Detection //
///////////////////////

function DetectOS()
{
    var OS = "Windows";
    var ua = navigator.userAgent.toLowerCase();
    if ( ua.match(/linux/) ) OS = "Linux";
    else if ( ua.match(/x11/) ) OS = "Unix";
    else if ( ua.match(/mac/) ) OS = "Mac";
    MGCFrame.operatingsystem = OS;
}

// As of MGC globals version .005, we only test if on file system. 
// All browsers now reject cross-origin calls to MGCFrame on the file system.
//
function DetectOnFileSystem()
{
    if(isFileSystem == null) {
        isFileSystem = false;
        if ( /file:\/\//.test(location.href) ) {
            isFileSystem = true;
        }
    }
    
    return isFileSystem;  
}

// returns true if using WebKit browser (Chrome/Safari) on the local file system
// This function is deprecated as of version .005..left for historical/documentation
// so we can see what the test was for "web kit on file system".
//
function DetectWebKitOnFileSystem()
{
    if ( mbWebKitFile == null ) {
        mbWebKitFile = false;
        var browserID = /WebKit/.exec(navigator.userAgent);
        if ( browserID != null ) {
            if ( /file:\/\//.test(location.href) ) {
                mbWebKitFile = true;
            }
        }
    }
    return mbWebKitFile;
}

// detect unsupported browsers that need to use basic mode
// NOTE: must match DetectBasicMode function in page.js
function DetectBasicMode()
{
    if ( mbBasicMode == null ) {
        mbBasicMode = false;
        var browserID = /Netscape\/([\d\.]+)/.exec(navigator.userAgent);
        if ( browserID ) {
            mbBasicMode = true;
        }
    }
    return mbBasicMode;
}


///////////////////////
// Utility Functions //
///////////////////////

// GetScript loads the specified JavaScript file and calls the callback function when done.
// This is similar to jQuery's getScript function, except this one works on the local filesystem.
function GetScript( path, id, callback, errcallback )
{
    // If an existing element with the same name exists, delete it.
    var old = document.getElementById(id);
    if ( old != null ) {
        old.parentNode.removeChild(old);
        delete old;
    }
    var head = document.getElementsByTagName("head")[0];
    script = document.createElement('script');
    script.id = id;
    script.type = 'text/javascript';
    script.src = path;

    if(typeof errcallback != 'undefined') {
        script.onerror = errcallback;
    }
        
    // Without the following if statement, IE9 tries to fire both onreadystatechange and onload events.
    if( script.readyState ) {
        script.onreadystatechange = function() {
            if ( this.readyState == 'complete' || this.readyState == 'loaded' ) {
                callback();
            }
        }
    } else {
        script.onload = callback;
    }
    head.appendChild(script);
}

function MGCSidebarScrollTo( DivToScroll, Target )
{
    // Scrolls to a specific ID in a scrollable div in the sidebar
    //first check to see that div is visible and actually exists.
    if( $(DivToScroll).length >=1 && $(DivToScroll).is(':visible') && $(Target).length >=1 ) {
        $(DivToScroll).stop().scrollTo(Target, 1000, {
            axis: 'y',
            offset: -10
        });
    }
}

function MGCDocumentScrollTo( Target )
{
    // If there is some sort of error in the highlighting code, we don't want to cause an error by trying to scroll to some
    // non-existent Target. Verify that our target div exists before scroll to it.
    if($(Target, TopicFrame.document).length >0){
        $(TopicFrame.document).stop().scrollTo(Target, 2000, {
            axis: 'y',
            offset: -70
        });
    }
}


/*** PDF Warning Popup ***/

function loadPopup( divName )
{
    // loads popup only if it is disabled
    if ( popupStatus == 0 ) {
        popupDiv = divName;

        if(MGCCookiesEnabled() == false) {
            $("#pdflink_noprompt").css({"display": "none"});
            $("#pdflink_nopromptlabel").css({"display": "none"});
        }

        $("#backgroundPopup").css({"opacity": ".5"});
        $("#backgroundPopup").fadeIn();
        $(divName).fadeIn();
        popupStatus = 1;
    }
}

function disablePopup()
{
    if ( popupStatus == 1 ) {
        $("#backgroundPopup").fadeOut();
        $(popupDiv).fadeOut();
        $(".notice").remove();
        $("#pdflinkPopup").height(160);
        $(popupDiv + " .open_button").off("click");
        $(popupDiv + " .close_button").off("click");
        popupStatus = 0;
    }
}

function shouldWarnOnPDF()
{
    cookieString = MGCGetCookie("MGC_PDFWarning");

    if ( cookieString == null || cookieString == "" ) {
        return true;
    }


    // Note the inverted logic here, the question is: "Do NOT show this dialog again..."
    // So false == display the warning, and true == do not display the warning.
    if ( cookieString.length >= 1 && cookieString[0] != "" ) {
        if(cookieString == "true") {
            return false;
        }
        else {
            return true;
        }
    }
}


function setupPopupEvents(openFunc)
{
    $(popupDiv + " .open_button").click(function() {

        disableWarning = $("#pdflink_noprompt").is(':checked');
        if(disableWarning == true) {
            MGCSetCookie("MGC_PDFWarning", true, true);
        }
        else {
            MGCSetCookie("MGC_PDFWarning", false, true);
        }

        disablePopup();
        openFunc();
    });


    $(popupDiv + " .cancel_button").click( function() {
        disablePopup();
    });

    // Escape keypress event
    $(document).keypress( function(e) {
        if ( e.keyCode==27 && popupStatus==1 ) {
          disablePopup();
        }
    });
}

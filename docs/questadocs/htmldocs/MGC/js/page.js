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
// page.js - JavaScript loaded in each html topic
//

var MGCFrame = window.parent;
var mbWebKitFile = null;
var isFileSystem = null;
var mbBasicMode = null;
var LocalData = {};
// map DetectChromeForBasic to DetectBasicMode function
var DetectChromeForBasic = DetectBasicMode;

// JCB Added support for converting tabs to spaces in IE
var tabSize = 2;

// JCB Added for version checks
var v4VersionCutoff = "mgc_mgchelp_v4.0.000"

// called when topic is fully loaded
window.onload = function() {

    // JCB for IE, we have to replace tabs with spaces. In all other browsers this is handled with CSS. 
    //Set your tab size here, and in the CSS.
    var codeElements = document.getElementsByClassName('codeblock'),
        e = document.createElement('i');

    if(e.style.tabSize !== '' && e.style.MozTabSize !== '' && e.style.oTabSize !== '' && e.style.WebKitTabSize !== '')
    {
       // console.log(e.style);
       if(codeElements.length > 0)
         replaceTabs(codeElements);
    }

    // ---------------------------

    if ( DetectBasicMode() ) {
        // remove onclick event handlers for all anchor tags (without jquery)
        var anchorTags = this.document.getElementsByTagName("a");
        for ( var i=0; i < anchorTags.length; i++ ) {
            anchorTags[i].onclick = null;
        }
    }

    if ( DetectOnFileSystem() || InEclipse() ) {

        // JCB
        // Open up the regular expression to include either '#' or '?' after the ".html" (this was failing on Eclipse)
        // 10/19/2016 - Some FM8 books don't have "title1" as their title page. 
        // To catch these, test for CurrentFileID == 1.  Actually this simple test could probably replace the 
        // entire "title*" regexp.
        if (/\/title[^/.]*1\.html(?:[#?][^/.]*)?$/.test(location.href) || CurrentFileID == 1) {
  
            // add footer graphic to title pages only
            // JCB
            // Need to do a version check here to get the right path to the graphic.
            // var versionCompare = document.getElementsByTagName('meta')['TEMPLATEBASE'].getAttribute('content').localeCompare("mgc_mgchelp_v4.0.000"); 
            var versionCompare = document.getElementsByTagName('meta')['TEMPLATEBASE'].getAttribute('content').length - v4VersionCutoff.length;
            var splashPath = "";
            if(versionCompare >= 0) {
              splashPath = "../../MGC/images/splash_screen_bottom2.gif";
            }
            else {
              splashPath = "../MGC/images/splash_screen_bottom2.gif";
            }

            // License check for splash bitmap
            var FooterHTML = "";
            var licenseTypeMeta = document.getElementsByTagName('meta')['LicenseType'];
            var licenseType     = licenseTypeMeta ? document.getElementsByTagName('meta')['LicenseType'].getAttribute('content') : "";
            if(licenseType.toLowerCase().indexOf("siemens") >= 0) {
                FooterHTML = "<br /><table width=\"90\%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\"><tr height=\"200\"><td>&#160;</td></tr></table>";
            }
            else {
                FooterHTML = "<br /><table width=\"90\%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" background=\"" + splashPath + "\"><tr height=\"200\"><td>&#160;</td></tr></table>";                
            }

            FooterHTML += "<div id=\"Options\" class=\"Options\"><p class=\"Options\">&#160;</p></div>";
            var footer = document.getElementById("Footer");
            if ( footer ) {
                footer.innerHTML = FooterHTML;
            }
        } else {
            // copy footer from noscript tag (without jquery)
            var nos = this.document.getElementsByTagName("noscript");
            var nosFooter = nos[nos.length-1];
            var e = document.createElement("div");
            e.className = "MGCFooter";
            e.innerHTML = nosFooter.innerHTML.trim();
            
            // extra innerHTML assignment is needed to decode html entities
            // This assignment works on Windows, but not on Linux. On Linux this results
            // in an empty footer because .nodeValue is null for non-#text elements.
            if(e.childNodes[0].nodeValue) {
              e.innerHTML = e.childNodes[0].nodeValue;
            }

            // remove Browser Requirements link
            var a = e.getElementsByTagName("a")[0];
            // Check to see that we actually got something -- on Windows you can't retrieve elements from within noscript.
            if(a) {
              a.parentNode.removeChild(a);
              var footer = document.getElementById("Footer");
              if ( footer ) {
                  footer.innerHTML = "";
                  footer.appendChild(e);
              }
            }
        }
    } else if ( typeof MGCFrame.MGCUpdateNavPane == "function" ) {
         MGCFrame.MGCUpdateNavPane();
         MGCFrame.MGCInsertRTFooter();
    }
}


// JCB 
// Added for converting TABs to spaces
function replaceTabs(ele)
{
  for(var i = 0; i < ele.length; i++)
  {
    ele[i].innerHTML = ele[i].innerHTML.replace(/\t/g, repeat(" ", tabSize));
  }
}


// JCB 
// Added for converting TABs to spaces
function repeat(st, n) {
   var s = "";
   while (--n >= 0) {
     s += st
   }
   return s;
}


// detect unsupported browsers that need to use basic mode
// NOTE: must match DetectBasicMode function in mgchelp.js
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

function writeNoScriptStyles()
{
    document.writeln('<link rel="StyleSheet" href="../MGC/styles/body.css" type="text/css" />');
    document.writeln('<link rel="StyleSheet" href="../MGC/styles/catalog.css" type="text/css" />');
    document.writeln('<link rel="StyleSheet" href="../MGC/styles/document.css" type="text/css" />');
}

function writeBasicHeader()
{
    var html = [
      '<div class="noscriptchromeheader"> ',
      '  <div title="Show Table of Contents" class="noscripttocButton" id="feedback_button"> ',
      '    <a href="index.htm" target="_top"><span>Table of Contents</span></a> ',
      '  </div> ',
      '  <div class="MGCLogo"><a href="http://www.mentor.com"><img src="../MGC/images/mgc_logo.png"/></a></div> ',
      '  <div id="chromebooktitle">title</div> ',
      '</div> ',
      '<div id="noscriptchromewarning" class="noscriptchromeindent"> ',
      '  <strong>Note:</strong> You are viewing the basic version of the Mentor Graphics Documentation System, which provides limited navigation. ',
      '  Due to Chrome and Safari security policies, you are unable to use all features of the documentation system. ',
      '  To access the full system, use a supported browser with specific security settings. ',
      '  Refer to the <a href="../mgc_html_help/index.htm" target="_top">"Browser Settings"</a> topic for details. ',
      '</div> <hr color="grey" style="margin-left:-20px; margin-right:-5px"/> '
    ];
    document.write(html.join("\n"));
}

function javascriptTopicRedirect()
{
    if ( DetectBasicMode() ) return;
    // determine if framework exists around this topic
    if ( MGCFrame == window && !InEclipse() ) {
        var BasePath = "../mgchelp.htm";
        var Parts = [];
        Parts = location.href.split("#");
        var MGCTreeLoc = Parts[0].toString();
        MGCTreeLoc = MGCTreeLoc.replace(/\/MGC\/html\/mgchelp\.htm.*/,"");
        Parts = MGCTreeLoc.split("/");
        var Handle = Parts[Parts.length-2];
        var Topic = Parts[Parts.length-1];
        if ( Handle == "topics" ) {
            Handle = Parts[Parts.length-3];
            BasePath = "../" + BasePath;
            Topic = "topics/" + Topic;
        }
        var newHash = "#context=" + Handle + "&href=" + Topic + "&single=true";
        // failsafe to prevent endless redirect loop
        if ( window.top.location.hash != newHash ) {
            // redirect to mgchelp.htm to load framework around this topic
            setTimeout( function() { window.top.location.href = BasePath + newHash; }, 100 );
            return;
        }
    }

    if ( DetectOnFileSystem() || InEclipse() ) {
        document.write( EclipseStyleSheets() );
    } else if ( typeof MGCFrame.MGCStyleSheets == "function" ) {
        document.write( MGCFrame.MGCStyleSheets() );
    } else {
        // if we didn't redirect above, write basic stylesheets
        document.write( EclipseStyleSheets() );
    }
}

function topicFooter()
{
    if ( DetectOnFileSystem() ) return;
    if ( DetectBasicMode() ) {
        if ( document.getElementById('chromebooktitle') != null ) {
            document.getElementById('chromebooktitle').innerText = DocTitle;
        }
        var copyright_date = ( typeof Copyright == "string" ) ? Copyright : "";
        if ( typeof document.getElementsByClassName != "undefined" && document.getElementsByClassName('Options').length > 0 ){
            document.getElementsByClassName('Options')[0].innerHTML = "";
        } else {
            document.writeln( '<hr color="grey" style="margin-left:-20px; margin-right:-5px"><p class="MGCFooter">' + DocTitle );
        }

        // JCB 
        // The copyright symbol &#169 was after the copyright date. It should appear before the date.
        document.writeln ('<br />' + '&#169;&#160;' + copyright_date + '&#160;Mentor Graphics Corporation. All rights reserved.' );
        if ( !InEclipse() ) {
            document.writeln('<br /><a href="../mgc_html_help/index.htm" target="_blank">Browser Requirements</a></'+'p>');
        }
    }
}

function InEclipse()
{
    if ( DetectOnFileSystem() ) return false;
    // detect eclipse by inspecting topic url, should match one of:
    //   http://127.0.0.1:<port>/help/topic/...   (eclipse help viewer)
    //   http://127.0.0.1:<port>/help/ntopic/...  (eclipse dynamic help)
    if ( /^http:\/\/127.0.0.1:[0-9]+\/help\/n?topic\//.test(location.href) ) {
        return true;
    }
    return false;
}

function EclipseStyleSheets()
{
    // JCB Determine the stylesheet path based on the version used to build.
    // var versionCompare = document.getElementsByTagName('meta')['TEMPLATEBASE'].getAttribute('content').localeCompare("mgc_mgchelp_v4.0.000"); 
    var versionCompare = document.getElementsByTagName('meta')['TEMPLATEBASE'].getAttribute('content').length - v4VersionCutoff.length;
    var doc = "";
    var cat = "";
    if(versionCompare >= 0) {
       if(document.title == "List of Figures" || document.title == "List of Tables") {
          doc = '<link rel="stylesheet" href="../MGC/styles/document.css" type="text/css" />';
          cat = '<link rel="stylesheet" href="../MGC/styles/catalog.css" type="text/css" />';
       }
       else {
          doc = '<link rel="stylesheet" href="../../MGC/styles/document.css" type="text/css" />';
          cat = '<link rel="stylesheet" href="../../MGC/styles/catalog.css" type="text/css" />';        
       }
    }
    else {
       doc = '<link rel="stylesheet" href="../MGC/styles/document.css" type="text/css" />';
       cat = '<link rel="stylesheet" href="../MGC/styles/catalog.css" type="text/css" />';
    }

    var html = [
      '<style type="text/css"> ',
      '  body { ',
      '    background-color: #FFFFFF; ',
      '    color: Black; ',
      '    font-family: Verdana, Arial, Tahoma, sans-serif; ',
      '    font-size: 13px; ',
      '    font-variant: normal; ',
      '    font-style: normal; ',
      '    font-weight: normal; ',
      '    text-decoration: none; ',
      '    text-indent: 0px; ',
      '    text-transform: none; ',
      '    text-align: left; ',
      '    margin-left: 10px; ',
      '    margin-right: 10px; ',
      '  } ',
      '</style>',
      doc,
      cat,
    ];
    return html.join("\n");
}

function doLink()
{
    var behavior = MGCFrame.behavior;
    var context = MGCFrame.context;
    var topic = MGCFrame.topic;

    // JCB added a check for a FM11 style link...need to go up two levels if true
    if ( behavior == "STD" || behavior == "STD_FM11") {
        var file = MGC_MatchTopic(context, topic);
        if(behavior == "STD_FM11") {
           window.location.href = "../../" + context + "/" + file;
        }
        else {
           window.location.href = "../" + context + "/" + file;
        }
    } else if ( behavior == "CRF" ) {
        window.location.href = topic;
    }
}

function EclipseLink()
{
    // JCB Check for a FM11 style link...go up two levels if true
    CreateBookData();
    if ( MGCFrame.behavior == "STD" ) {
        GetScript( "../" + MGCFrame.context + "/MGCdata/MGCAllData.js", "ihubdata", doLink );
    } else if ( MGCFrame.behavior == "STD_FM11") {
        GetScript( "../../" + MGCFrame.context + "/MGCdata/MGCAllData.js", "ihubdata", doLink );
    } else if ( MGCFrame.behavior == "CRF" ) {
        GetScript( "MGCdata/MGCAllData.js", "ihubdata", doLink );
    }
    return;
}

function oT( behavior, topic, context )
{
    // load book data locally for Eclipse browser
    if ( InEclipse() ) {
        MGCFrame = window.self;
        MGCFrame.behavior = behavior;
        MGCFrame.topic = topic;
        MGCFrame.context = context;
        MGCFrame.BookData = [];
        MGCFrame.mLibraryList = [];
        MGCFrame.mLibraryList[0] = [];
        MGCFrame.mLibraryList[0] = ["",context]

        // JCB
        // Check for a FM11 style link...go up two levels if true
        if(behavior == "STD_FM11") {
           GetScript( "../../MGC/js/MGCjavascript.js", "mgcjavascript", EclipseLink );
        }
        else {
           GetScript( "../MGC/js/MGCjavascript.js", "mgcjavascript", EclipseLink );
        }

        return;
    }

    var file = topic;
    var file_hash = "";
    var fileID = null;
    var url;

    if ( typeof topic == "undefined" ) topic = "";
    if ( behavior != "PDF" && behavior != "REL" && behavior != "OLH" ) {
        // remove any special characters from the topic
        // JCB do not remove the directory separator /
        // NB the hyphen character must be either first or last in the character class.
        topic = topic.replace(/[^\-A-Za-z0-9_\.\/]/g,"").replace(/[\)\(]/g,"").replace(/\s/g,"").toLowerCase();
    }

    if ( !DetectOnFileSystem() ) {
        if ( typeof context == "undefined" ) context = MGCFrame.mHandle;
    
        // check if book exists in library, except for PDF, relative, and RoboHelp OLH links
        if ( behavior != "PDF" && behavior != "REL" && behavior != "OLH" ) {
            var found = false;
            if ( typeof MGCFrame.mLibraryList != "undefined" ) {
                for ( var i = 0 ; i < MGCFrame.mLibraryList.length ; i++ ) {
                    if ( context == MGCFrame.mLibraryList[i][1] ) {
                        found = true;
                        break;
                    }
                }
            }
            if ( ! found ) {
                alert( "The requested document is not installed: " + context );
                return;
            }
        }

        // if STD gotolink points to current book, treat as a CRF
        if ( (behavior == "STD_FM11" || behavior == "STD") && context == MGCFrame.mHandle ) {
            
            file = MGCFrame.MGC_MatchTopic( context, topic );

            // A FM11 link is not going to have the "wp" that MGC_MatchTopic mindlessly tacks onto the end of every string it returns.
            if(behavior == "STD_FM11") {
              file = file.replace(/#wp/, "#").replace("topics/", "");
            }

            behavior = "CRF";
        }
    }

    // console.log("BEFORE SWITCH: behavior = " + behavior + " topic = " + topic);

    switch ( behavior ) {
    case "CRF":
        // Open cross-reference within same document
        fileID = MGCFrame.MGC_File_to_ID( context, file );
        // apply highlighting to TOC element

        // JCB - FM11/structured docs do not have "wp" on identifiers. 
        // If file.split() returns undefined, then we have a FM11 id.
        var anchor;
        anchor = file.split("#wp")[1];
        if(typeof anchor == "undefined")
            anchor = file.split("#")[1];
        // JCB
        
        MGCFrame.HighlightTOC( MGCFrame.GetTOCIndex( fileID, anchor, MGCFrame.mHandle ), MGCFrame.mHandle );
        
        // update page hash for history and bookmarks
        file_hash = "#context=" + context + "&id=" + fileID;
        
        // JCB - Initialize tag with the previosly set anchor variable.
        var tag = anchor;
        
        if ( typeof tag == "undefined" ) tag = MGCFrame.MGCID_to_Topic(fileID);
        file_hash += "&tag=" + tag;
        if ( MGCFrame.Popup ) file_hash += "&single=popup";
        MGCFrame.mPreviousHash = file_hash;
        MGCFrame.location.hash = file_hash;
        // use location.replace to not affect history (hash takes care of that)
        location.replace(file);
        break;
    // JCB -- added new behavior for FM11 builds
    case "STD_FM11":
         // URL needs to go up two levels 
         url = "../../mgchelp.htm#context=" + context + "\&topic=" + topic;
         window.open(url);
         break;
    case "STD":
        // Open topic in different document
        url = "../mgchelp.htm#context=" + context + "\&topic=" + topic;
        window.open(url);
        break;
    case "SNG":
        // Open topic in "single mode" w/ sidebar collapsed
        url = "../mgchelp.htm#context=" + context + "&topic=" + topic + "\&single=true";
        window.open(url);
        break;
    case "NEW":
        // Open topic in new window, with full sidebar & navigation
        url = "../mgchelp.htm#context=" + context + "&topic=" + topic;
        window.open(url);
        break;
    case "POP":
        // Open topic in "popup mode" w/ no sidebar or navigation
        url = "../mgchelp.htm#context=" + context + "\&topic=" + topic + "\&single=popup";
        PopupWindow( url, 800, 600 );
        break;
    case "PDF":
        // Open PDF topic in new window
        url = "";
        if ( topic != "" ) {
            topic = topic.replace(/[\-\(\)]/g, "").replace(/[^A-Z,a-z,0-9,_]/g, " ").replace(/ /g, ".");
            url = "../../pdfdocs/" + context + ".pdf#M8.newlink." + topic;
        } else {
            url = "../../pdfdocs/" + context + ".pdf";
        }
        window.open(url);
        break;
    case "REL":
        // Relative link outside htmldocs directory
        url = "../" + topic;
        window.open(url);
        break;
    case "OLH":
        // Open topic for RoboHelp generated OLH
        url = "../" + context + "/" + context + ".htm#" + topic;
        window.open(url);
        break;
    }
}

// Function to open help on search/other mini-helps
function PopupWindow( url, width, height )
{
    var chrome = "location=0,"
        + "width=" + width + ","
        + "height=" + height + ","
        + "menubar=0,"
        + "resizable=1,"
        + "scrollbars=1,"
        + "status=0,"
        + "titlebar=1,"
        + "toolbar=0,"
        + "hotkeys=0,"
        + "left=450,"
        + "top=100";
    var popup = window.open(url,'',chrome);
    popup.focus();
}

function MGCAddBookVar( handle, varname, varvalue )
{
   MGCFrame.BookData[handle][varname] = varvalue;
}

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

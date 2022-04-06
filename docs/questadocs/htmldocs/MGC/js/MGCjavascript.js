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
// MGCjavascript.js - Common JavaScript shared by mgchelp and infohub
//

var mbWebKitFile = null;
var mbBasicMode = null;

// Map the browser language to directory that provides the UI strings
//
function MapLang(lang) {
    langMap = {
        undefined : "en-US",  // Insanity check
        "af"   : "en-US",     // Afrikaans
        "af-ZA": "en-US",     // Afrikaans (South Africa)
        "ar"   : "en-US",     // Arabic
        "ar-AE": "en-US",     // Arabic(U.A.E.)
        "ar-BH": "en-US",     // Arabic(Bahrain)
        "ar-DZ": "en-US",     // Arabic(Algeria)
        "ar-EG": "en-US",     // Arabic(Egypt)
        "ar-IQ": "en-US",     // Arabic(Iraq)
        "ar-JO": "en-US",     // Arabic(Jordan)
        "ar-KW": "en-US",     // Arabic(Kuwait)
        "ar-LB": "en-US",     // Arabic(Lebanon)
        "ar-LY": "en-US",     // Arabic(Libya)
        "ar-MA": "en-US",     // Arabic(Morocco)
        "ar-OM": "en-US",     // Arabic(Oman)
        "ar-QA": "en-US",     // Arabic(Qatar)
        "ar-SA": "en-US",     // Arabic(Saudi Arabia)
        "ar-SY": "en-US",     // Arabic(Syria)
        "ar-TN": "en-US",     // Arabic(Tunisia)
        "ar-YE": "en-US",     // Arabic(Yemen)
        "az"   : "en-US",     // Azeri(Latin)
        "az-AZ": "en-US",     // Azeri(Latin) (Azerbaijan)
                              // "az-AZ	Azeri(Cyrillic)(Azerbaijan) (Duplicate entry)
        "be"   : "en-US",     // Belarusian
        "be-BY": "en-US",     // Belarusian(Belarus)
        "bg"   : "en-US",     // Bulgarian
        "bg-BG": "en-US",     // Bulgarian(Bulgaria)
        "bs-BA": "en-US",     // Bosnian(Bosnia and Herzegovina)
        "ca"   : "en-US",     // Catalan
        "ca-ES": "en-US",     // Catalan(Spain)
        "cs"   : "en-US",     // Czech
        "cs-CZ": "en-US",     // Czech(Czech Republic)
        "cy"   : "en-US",     // Welsh
        "cy-GB": "en-US",     // Welsh(United Kingdom)
        "da"   : "en-US",     // Danish
        "da-DK": "en-US",     // Danish(Denmark)
        "de"   : "de",        // German
        "de-AT": "de",        // German(Austria)
        "de-CH": "de",        // German(Switzerland)
        "de-DE": "de",        // German(Germany)
        "de-LI": "de",        // German(Liechtenstein)
        "de-LU": "de",        // German(Luxembourg)
        "dv"   : "en-US",     // Divehi
        "dv-MV": "en-US",     // Divehi(Maldives)
        "el"   : "en-US",     // Greek
        "el-GR": "en-US",     // Greek(Greece)
        "en"   : "en-US",     // English
        "en-AU": "en-US",     // English(Australia)
        "en-BZ": "en-US",     // English(Belize)
        "en-CA": "en-US",     // English(Canada)
        "en-CB": "en-US",     // English(Caribbean)
        "en-GB": "en-US",     // English(United Kingdom)
        "en-IE": "en-US",     // English(Ireland)
        "en-JM": "en-US",     // English(Jamaica)
        "en-NZ": "en-US",     // English(New Zealand)
        "en-PH": "en-US",     // English(Republic of the Philippines)
        "en-TT": "en-US",     // English(Trinidad and Tobago)
        "en-US": "en-US",     // English(United States)
        "en-ZA": "en-US",     // English(South Africa)
        "en-ZW": "en-US",     // English(Zimbabwe)
        "eo"   : "en-US",     // Esperanto
        "es"   : "en-US",     // Spanish
        "es-AR": "en-US",     // Spanish(Argentina)
        "es-BO": "en-US",     // Spanish(Bolivia)
        "es-CL": "en-US",     // Spanish(Chile)
        "es-CO": "en-US",     // Spanish(Colombia)
        "es-CR": "en-US",     // Spanish(Costa Rica)
        "es-DO": "en-US",     // Spanish(Dominican Republic)
        "es-EC": "en-US",     // Spanish(Ecuador)
        "es-ES": "en-US",     // Spanish(Castilian)
                              // "es-ES": "en-US",  Spanish(Spain) (Duplicate entry)
        "es-GT": "en-US",     // Spanish(Guatemala)
        "es-HN": "en-US",     // Spanish(Honduras)
        "es-MX": "en-US",     // Spanish(Mexico)
        "es-NI": "en-US",     // Spanish(Nicaragua)
        "es-PA": "en-US",     // Spanish(Panama)
        "es-PE": "en-US",     // Spanish(Peru)
        "es-PR": "en-US",     // Spanish(Puerto Rico)
        "es-PY": "en-US",     // Spanish(Paraguay)
        "es-SV": "en-US",     // Spanish(El Salvador)
        "es-UY": "en-US",     // Spanish(Uruguay)
        "es-VE": "en-US",     // Spanish(Venezuela)
        "et"   : "en-US",     // Estonian
        "et-EE": "en-US",     // Estonian(Estonia)
        "eu"   : "en-US",     // Basque
        "eu-ES": "en-US",     // Basque(Spain)
        "fa"   : "en-US",     // Farsi
        "fa-IR": "en-US",     // Farsi(Iran)
        "fi"   : "en-US",     // Finnish
        "fi-FI": "en-US",     // Finnish(Finland)
        "fo"   : "en-US",     // Faroese
        "fo-FO": "en-US",     // Faroese(Faroe Islands)
        "fr"   : "fr",        // French
        "fr-BE": "fr",        // French(Belgium)
        "fr-CA": "fr",        // French(Canada)
        "fr-CH": "fr",        // French(Switzerland)
        "fr-FR": "fr",        // French(France)
        "fr-LU": "fr",        // French(Luxembourg)
        "fr-MC": "fr",        // French(Principality of Monaco)
        "gl"   : "en-US",     // Galician
        "gl-ES": "en-US",     // Galician(Spain)
        "gu"   : "en-US",     // Gujarati
        "gu-IN": "en-US",     // Gujarati(India)
        "he"   : "en-US",     // Hebrew
        "he-IL": "en-US",     // Hebrew(Israel)
        "hi"   : "en-US",     // Hindi
        "hi-IN": "en-US",     // Hindi(India)
        "hr"   : "en-US",     // Croatian
        "hr-BA": "en-US",     // Croatian(Bosnia and Herzegovina)
        "hr-HR": "en-US",     // Croatian(Croatia)
        "hu"   : "en-US",     // Hungarian
        "hu-HU": "en-US",     // Hungarian(Hungary)
        "hy"   : "en-US",     // Armenian
        "hy-AM": "en-US",     // Armenian(Armenia)
        "id"   : "en-US",     // Indonesian
        "id-ID": "en-US",     // Indonesian(Indonesia)
        "is"   : "en-US",     // Icelandic
        "is-IS": "en-US",     // Icelandic(Iceland)
        "it"   : "it",        // Italian
        "it-CH": "it",        // Italian(Switzerland)
        "it-IT": "it",        // Italian(Italy)
        "ja"   : "ja",        // Japanese
        "ja-JP": "ja",        // Japanese(Japan)
        "ka"   : "en-US",     // Georgian
        "ka-GE": "en-US",     // Georgian(Georgia)
        "kk"   : "en-US",     // Kazakh
        "kk-KZ": "en-US",     // Kazakh(Kazakhstan)
        "kn"   : "en-US",     // Kannada
        "kn-IN": "en-US",     // Kannada(India)
        "ko"   : "ko",        // Korean
        "ko-KR": "ko",        // Korean(Korea)
        "kok"  : "en-US",     // Konkani
        "kok-IN": "en-US",    // Konkani(India)
        "ky"   : "en-US",     // Kyrgyz
        "ky-KG": "en-US",     // Kyrgyz(Kyrgyzstan)
        "lt"   : "en-US",     // Lithuanian
        "lt-LT": "en-US",     // Lithuanian(Lithuania)
        "lv"   : "en-US",     // Latvian
        "lv-LV": "en-US",     // Latvian(Latvia)
        "mi"   : "en-US",     // Maori
        "mi-NZ": "en-US",     // Maori(New Zealand)
        "mk"   : "en-US",     // FYRO Macedonian
        "mk-MK": "en-US",     // FYRO Macedonian(Former Yugoslav Republic of Macedonia)
        "mn"   : "en-US",     // Mongolian
        "mn-MN": "en-US",     // Mongolian(Mongolia)
        "mr"   : "en-US",     // Marathi
        "mr-IN": "en-US",     // Marathi(India)
        "ms"   : "en-US",     // Malay
        "ms-BN": "en-US",     // Malay(Brunei Darussalam)
        "ms-MY": "en-US",     // Malay(Malaysia)
        "mt"   : "en-US",     // Maltese
        "mt-MT": "en-US",     // Maltese(Malta)
        "nb"   : "en-US",     // Norwegian(Bokm ? l)
        "nb-NO": "en-US",     // Norwegian(Bokm ? l)(Norway)
        "nl"   : "en-US",     // Dutch
        "nl-BE": "en-US",     // Dutch(Belgium)
        "nl-NL": "en-US",     // Dutch(Netherlands)
        "nn-NO": "en-US",     // Norwegian(Nynorsk)(Norway)
        "ns"   : "en-US",     // Northern Sotho
        "ns-ZA": "en-US",     // Northern Sotho(South Africa)
        "pa"   : "en-US",     // Punjabi
        "pa-IN": "en-US",     // Punjabi(India)
        "pl"   : "en-US",     // Polish
        "pl-PL": "en-US",     // Polish(Poland)
        "ps"   : "en-US",     // Pashto
        "ps-AR": "en-US",     // Pashto(Afghanistan)
        "pt"   : "en-US",     // Portuguese
        "pt-BR": "en-US",     // Portuguese(Brazil)
        "pt-PT": "en-US",     // Portuguese(Portugal)
        "qu"   : "en-US",     // Quechua
        "qu-BO": "en-US",     // Quechua(Bolivia)
        "qu-EC": "en-US",     // Quechua(Ecuador)
        "qu-PE": "en-US",     // Quechua(Peru)
        "ro"   : "en-US",     // Romanian
        "ro-RO": "en-US",     // Romanian(Romania)
        "ru"   : "ru",        // Russian
        "ru-RU": "ru",        // Russian(Russia)
        "sa"   : "en-US",     // Sanskrit
        "sa-IN": "en-US",     // Sanskrit(India)
        "se"   : "en-US",     // Sami(Northern)
        "se-FI": "en-US",     // Sami(Northern)(Finland)
                              // "se-FI": "en-US",  Sami(Skolt)(Finland) (Duplicate entry)
                              // "se-FI": "en-US",  Sami(Inari)(Finland) (Duplicate entry)
        "se-NO": "en-US",     // Sami(Northern)(Norway)
                              // "se-NO": "en-US"   Sami(Lule)(Norway) (Duplicate entry)
                              // "se-NO": "en-US"   Sami(Southern)(Norway) (Duplicate entry)
        "se-SE": "en-US",     // Sami(Northern)(Sweden)
                              // "se-SE": "en-US",  Sami(Lule)(Sweden) (Duplicate entry)
                              // "se-SE": "en-US",  Sami(Southern)(Sweden) (Duplicate entry)
        "sk"   : "en-US",     // Slovak
        "sk-SK": "en-US",     // Slovak(Slovakia)
        "sl"   : "en-US",     // Slovenian
        "sl-SI": "en-US",     // Slovenian(Slovenia)
        "sq"   : "en-US",     // Albanian
        "sq-AL": "en-US",     // Albanian(Albania)
        "sr-BA": "en-US",     // Serbian(Latin)(Bosnia and Herzegovina)
                              // "sr-BA": "en-US",  Serbian(Cyrillic)(Bosnia and Herzegovina) (Duplicate entry)
        "sr-SP": "en-US",     // Serbian(Latin)(Serbia and Montenegro)
                              // "sr-SP": "en-US",  Serbian(Cyrillic)(Serbia and Montenegro) (Duplicate entry)
        "sv"   : "en-US",     // Swedish
        "sv-FI": "en-US",     // Swedish(Finland)
        "sv-SE": "en-US",     // Swedish(Sweden)
        "sw"   : "en-US",     // Swahili
        "sw-KE": "en-US",     // Swahili(Kenya)
        "syr"  : "en-US",     // Syriac
        "syr-SY": "en-US",    // Syriac(Syria)
        "ta"   : "en-US",     // Tamil
        "ta-IN": "en-US",     // Tamil(India)
        "te"   : "en-US",     // Telugu
        "te-IN": "en-US",     // Telugu(India)
        "th"   : "en-US",     // Thai
        "th-TH": "en-US",     // Thai(Thailand)
        "tl"   : "en-US",     // Tagalog
        "tl-PH": "en-US",     // Tagalog(Philippines)
        "tn"   : "en-US",     // Tswana
        "tn-ZA": "en-US",     // Tswana(South Africa)
        "tr"   : "en-US",     // Turkish
        "tr-TR": "en-US",     // Turkish(Turkey)
        "tt"   : "en-US",     // Tatar
        "tt-RU": "en-US",     // Tatar(Russia)
        "ts"   : "en-US",     // Tsonga
        "uk"   : "en-US",     // Ukrainian
        "uk-UA": "en-US",     // Ukrainian(Ukraine)
        "ur"   : "en-US",     // Urdu
        "ur-PK": "en-US",     // Urdu(Islamic Republic of Pakistan)
        "uz"   : "en-US",     // Uzbek(Latin)
        "uz-UZ": "en-US",     // Uzbek(Latin)(Uzbekistan)
                              // "uz-UZ": "en-US",  Uzbek(Cyrillic)(Uzbekistan) (Duplicate entry)
        "vi"   : "en-US",     // Vietnamese
        "vi-VN": "en-US",     // Vietnamese(Viet Nam)
        "xh"   : "en-US",     // Xhosa
        "xh-ZA": "en-US",     // Xhosa(South Africa)
        "zh"   : "zh-CN",     // Chinese
        "zh-CN": "zh-CN",     // Chinese(S)
        "zh-HK": "zh-CN",     // Chinese(Hong Kong)
        "zh-MO": "zh-CN",     // Chinese(Macau)
        "zh-SG": "zh-CN",     // Chinese(Singapore)
        "zh-TW": "zh-CN",     // Chinese(T)
        "zu"   : "en-US",     // Zulu
        "zu-ZA": "en-US",     // Zulu(South Africa)
    };

    var dir = langMap[lang];
    if (dir === undefined) {
        return langMap.undefined;
    }
    else {
        return dir;
    }
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

// Redirect mgchelp.htm file preserving url parameters
function MGCInitDoc()
{
    if ( DetectBasicMode() ) {
        setTimeout( function() { window.location.replace("nsmgchelp.htm"); }, 100 );
        return;
    }
    var Parts = [];
    var tempLoc = location.href.replace("?", "#");
    Parts = tempLoc.split("#");
    var MGCTreeLoc = Parts[0].toString();
    MGCTreeLoc = MGCTreeLoc.replace(/\/MGC\/html\/mgchelp\.htm.*/, "");
    MGCTreeLoc = Parts[0].toString();
    MGCTreeLoc = MGCTreeLoc.replace(/\/a_mgc_help.htm.*/, "").replace(/\/wwhelp.htm.*/, "").replace(/\/index.htm.*/, "").replace(/\/a_open_first.htm.*/, "").replace(/\/$/, "");
    var MGCTreeLocParts = MGCTreeLoc.split('/')
    var Handle = MGCTreeLocParts[MGCTreeLocParts.length - 1].replace(/ /g, "");
    MGCTreeLocParts.pop();
    MGCTreeLoc = MGCTreeLocParts.join("/");
    var url = MGCTreeLoc + "/mgchelp.htm#context=" + Handle;
    if (typeof (Parts[1]) != "undefined") {
        var allParameters = Parts[1].split("&");
        var Parameters = MGCExtractURLParameters(allParameters);
        // Make sure the context, if any matches the handle of the current book.
        if (Parameters.mContext != "context\=" + Handle) {
            Parameters.mContext = "context\=" + Handle;
        }
        // if no parameters, just open the book to the title page
        if ((Parameters.mTopic == "") && (Parameters.mHREF == "")) {
            Parameters.mTopic = "\&topic\=manualtitle";
        }
        url = MGCTreeLoc + "/mgchelp.htm#" + Parameters.mContext + Parameters.mTopic + Parameters.mHREF + Parameters.mSource + Parameters.mQuery + Parameters.mIHub + Parameters.mWindowtype;
    }
    setTimeout( function() { window.location.replace(url); }, 100 );
}

function MGCExtractURLParameters( allParameters )
{
    var URLParameters = new Array();
    URLParameters.mTab = "";
    URLParameters.mIHub = "";
    URLParameters.mSource = "";
    URLParameters.mTopic = "";
    URLParameters.mSingle;
    URLParameters.mHREF = "";
    URLParameters.mQuery = "";
    URLParameters.mWindowtype = "";
    URLParameters.Syn = "";
    URLParameters.Sword = "";
    for (MaxIndex = allParameters.length, Index = 0; Index < MaxIndex; Index++) {
        mParameter = allParameters[Index].split("=");
        if (mParameter[0] == "tab") {
            URLParameters.mTab = "&" + allParameters[Index];
        }
        if (mParameter[0] == "ihub") {
            URLParameters.mIHub = "&" + allParameters[Index];
        }
        if (mParameter[0] == "single") {
            URLParameters.mWindowtype = "&" + allParameters[Index];
        }
        if (mParameter[0] == "topic") {
            URLParameters.mTopic = "&" + allParameters[Index];
        }
        if (mParameter[0] == "href") {
            URLParameters.mHREF = "&" + allParameters[Index];
        }
        if (mParameter[0] == "context") {
            URLParameters.mContext = "&" + allParameters[Index];
        }
        if (mParameter[0] == "src") {
            URLParameters.mSource = "&" + allParameters[Index];
        }
        if (mParameter[0] == "query") {
            URLParameters.mQuery = "&" + allParameters[Index];
        }
        if (mParameter[0] == "Syn") {
            URLParameters.Syn = "&" + allParameters[Index];
        }
        if (mParameter[0] == "Sword") {
            URLParameters.Sword = "&" + allParameters[Index];
        }
    }
    if ((URLParameters.mTopic != "") && (URLParameters.mHREF != "")) {
        URLParameters.mHREF == "";
    }
    return URLParameters;
}


///////////////
// Book Data //
///////////////

// Initialize a BookData array
// Execute before loading any data file
// Arrays are toc, files, paratext
function CreateBookData()
{
    for (MaxIndex = mLibraryList.length, Index = 0; Index < MaxIndex; Index++) {
        handle = mLibraryList[Index][1];
        BookData[handle] = [];
        BookData[handle]["files"] = [];
        BookData[handle]["filelist"] = [];
        BookData[handle]["toc"] = [];
        BookData[handle]["paratext"] = [];
        BookData[handle]["topics"] = [];
        BookData[handle]["AllTopics"] = [];
        BookData[handle]["synonyms"] = [];
        BookData[handle]["search"] = [];
        BookData[handle]["search"]["a"] = [];
        BookData[handle]["search"]["b"] = [];
        BookData[handle]["search"]["c"] = [];
        BookData[handle]["search"]["d"] = [];
        BookData[handle]["search"]["e"] = [];
        BookData[handle]["search"]["f"] = [];
        BookData[handle]["search"]["g"] = [];
        BookData[handle]["search"]["h"] = [];
        BookData[handle]["search"]["i"] = [];
        BookData[handle]["search"]["j"] = [];
        BookData[handle]["search"]["k"] = [];
        BookData[handle]["search"]["l"] = [];
        BookData[handle]["search"]["m"] = [];
        BookData[handle]["search"]["n"] = [];
        BookData[handle]["search"]["o"] = [];
        BookData[handle]["search"]["p"] = [];
        BookData[handle]["search"]["q"] = [];
        BookData[handle]["search"]["r"] = [];
        BookData[handle]["search"]["s"] = [];
        BookData[handle]["search"]["t"] = [];
        BookData[handle]["search"]["u"] = [];
        BookData[handle]["search"]["v"] = [];
        BookData[handle]["search"]["w"] = [];
        BookData[handle]["search"]["x"] = [];
        BookData[handle]["search"]["y"] = [];
        BookData[handle]["search"]["z"] = [];
        BookData[handle]["search"]["num"] = [];
        BookData[handle]["search"]["symbol"] = [];
        BookData[handle]["index"] = [];
        BookData[handle]["index"]["a"] = [];
        BookData[handle]["index"]["b"] = [];
        BookData[handle]["index"]["c"] = [];
        BookData[handle]["index"]["d"] = [];
        BookData[handle]["index"]["e"] = [];
        BookData[handle]["index"]["f"] = [];
        BookData[handle]["index"]["g"] = [];
        BookData[handle]["index"]["h"] = [];
        BookData[handle]["index"]["i"] = [];
        BookData[handle]["index"]["j"] = [];
        BookData[handle]["index"]["k"] = [];
        BookData[handle]["index"]["l"] = [];
        BookData[handle]["index"]["m"] = [];
        BookData[handle]["index"]["n"] = [];
        BookData[handle]["index"]["o"] = [];
        BookData[handle]["index"]["p"] = [];
        BookData[handle]["index"]["q"] = [];
        BookData[handle]["index"]["r"] = [];
        BookData[handle]["index"]["s"] = [];
        BookData[handle]["index"]["t"] = [];
        BookData[handle]["index"]["u"] = [];
        BookData[handle]["index"]["v"] = [];
        BookData[handle]["index"]["w"] = [];
        BookData[handle]["index"]["x"] = [];
        BookData[handle]["index"]["y"] = [];
        BookData[handle]["index"]["z"] = [];
        BookData[handle]["index"]["symbol"] = [];
        BookData[handle]["DataLoaded"] = false;
        
        // JCB Added default values for language and license book vars
        BookData[handle]["LicenseType"] = "eula";
        BookData[handle]["Language"]    = "en";
    }
}

function AddSWrd( letter, word, hits )
{
    MGCFrame.BookData[mLoadHandle]["search"][letter].push([word, hits]);
}

function AddTopic( topic, file, tag )
{
    MGCFrame.BookData[mLoadHandle]["topics"].push([topic, file, tag]);
}

function MGCAddTopic(TopicData)
{
    MGCFrame.BookData[mLoadHandle]["AllTopics"].push(TopicData);
}

function MGCABFile( file )
{
    if (typeof (file) == "undefined") {
        file = "nofile";
    }
    MGCFrame.BookData[mLoadHandle]["filelist"].push(file);
}

function MGCAddFunction( handle, function_name, file )
{
    MGCFrame.BookData[mLoadHandle]["functions"].push([function_name, file]);
}

// Add a variable list entry for a book
function MGCAddBookVar( varname, varvalue )
{
    MGCFrame.BookData[mLoadHandle][varname] = varvalue;
}

// Add a file list entry for a book
function MGCABF( file, title )
{
    if (typeof (file) == "undefined") {
        file = "nofile";
    }
    if (typeof (title) == "undefined") {
        title = "notitle";
    }
    MGCFrame.BookData[mLoadHandle]["files"].push([file, title]);
}

// Save topic text (snippets)
function MGCAddSnippet( file, text )
{
    MGCFrame.BookData[mLoadHandle]["paratext"].push([file, text]);
}

// Add a TOC entry for a book
function MGCAddTOC( HLevel, fileID, title, nd )
{
    MGCFrame.BookData[mLoadHandle]["toc"].push([HLevel, fileID, title, nd]);
}

// Add an Index entry for a book
function MGCAddIX( IXEntry )
{
    var Parts = IXEntry[1].split(":");
    var IXLevel = Parts.length;
    // convert misc to symbol until data format can be updated
    if (IXEntry[0] == "misc") {
        IXEntry[0] = "symbol";
    }
    MGCFrame.BookData[mLoadHandle]["index"][IXEntry[0]].push([IXLevel, IXEntry[3], IXEntry[1], IXEntry[2]]);
    MGCFrame.HasIndex = true;
}

function AddSynonym( synonym, definition )
{
    //MGCRK 10/16/2009 - modified to support both versions of synonym file
    //Makes synonym and definition equivalent for search purposes
    var synList = [];
    if ( typeof definition == "undefined" ) {
        synList = synonym;
    } else {
        synList = definition;
        synList.unshift(synonym);
    }
    // make all words in array lowercase for search
    synList = synList.join("@@@").toLowerCase().split("@@@");
    MGCFrame.BookData[mLoadHandle]["synonyms"].push(synList);
}

function MGC_MatchTopic( handle, topic, fm12 )
{
    // Find matching topic in topic list. Returns "topicfile.htm#tag"
    if ( typeof topic == "undefined" ) topic = "manualtitle";
    topic = topic.toLowerCase().replace(/[^a-z0-9_-]/g, "");
    var file = BookData[handle]["files"][1][0] + ".html";
    for ( var i = 0; i < BookData[handle]["AllTopics"].length; i++ ) {
        var t = BookData[handle]["AllTopics"][i][0];
        t = t.toLowerCase().replace(/[^a-z0-9_-]/g, "");
        if (t == topic) {
            var suffixTag = "";

            if (typeof fm12 === 'undefined')
                suffixTag = ".html#wp";
            else
                if (fm12 > -1)
                    suffixTag = ".html#";
                else
                    suffixTag = ".html#wp";

            var id  = BookData[handle]["AllTopics"][i][2];
            var tag = BookData[handle]["AllTopics"][i][1];
            file    = BookData[handle]["files"][id][0] + suffixTag + tag;
        }
    }
    return file;
}

function MGC_File_to_ID( handle, file )
{
    var FID = 0;
    file = file.replace(/\.html.*/, "");
    var FMaxIndex = BookData[handle].files.length;
    for (var FIndex = 0; FIndex < FMaxIndex; FIndex++) {
        if (MGCFrame.BookData[handle].files[FIndex][0] == file) {
            FID = FIndex;
            break;
        }
    }
    return FID;
}

function MGC_ID_to_File( handle, ID )
{
    return MGCFrame.BookData[handle].files[ID][0];
}

function MGC_ID_to_Topic( handle, ID )
{
    return MGCFrame.BookData[handle].files[ID][1];
}

function MGCID_to_Topic( ID )
{
    var topic = BookData[mHandle].files[ID][1];
    for ( var i = 0; i < BookData[mHandle].toc.length; i++ ) {
        if ( BookData[mHandle].toc[i][2] == topic ) {
            return (BookData[mHandle].toc[i][3]);
        }
    }
    return "";
}

function MGC_Handle_to_Title( handle )
{
    var HMaxIndex = MGCFrame.mLibraryList.length;
    for (var HIndex = 0; HIndex < HMaxIndex; HIndex++) {
        if (MGCFrame.mLibraryList[HIndex][1] == handle) {
            return MGCFrame.mLibraryList[HIndex][0];
        }
    }
    return "ERROR: " + handle + " not found in library";
}

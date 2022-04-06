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
// browserdetect.js - JavaScript loaded by nsmgchelp.htm
//

var mbWebKitFile = null;
var mbBasicMode = null;
// map DetectChromeForBasic to DetectBasicMode function
var DetectChromeForBasic = DetectBasicMode;

// detect unsupported browsers that need to use basic mode
function DetectBasicMode()
{
    if ( mbBasicMode == null ) {
        mbBasicMode = false;
        var browserID = /Netscape\/([\d\.]+)/.exec(navigator.userAgent);
        /*if ( browserID == null ) {
            if ( typeof window.opera != "undefined" ) {
                browserID = window.opera.version();
                if ( parseFloat(browserID) >= 10.0 ) {
                    // allow Opera 10+
                    browserID = null;
                }
            }
        }*/
        if ( browserID ) {
            mbBasicMode = true;
        }
    }
    return mbBasicMode;
}

// returns true if using WebKit browser (Chrome/Safari) on the local file system
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

//
// Copyright 2011-2015 Mentor Graphics Corporation
//
//    All Rights Reserved.
//
// THIS WORK CONTAINS TRADE SECRET
// AND PROPRIETARY INFORMATION WHICH IS THE
// PROPERTY OF MENTOR GRAPHICS
// CORPORATION OR ITS LICENSORS AND IS
// SUBJECT TO LICENSE TERMS.
//

// Define data relevant to all installed InfoHubs
var mReleaseName = "Questa SIM v2020.4";
//var mFlowName = "";
//var mbShowCommunities = true;

// InfoHub data
var mInfoHub = "mgc_ih";

var Entry;
var List;

// Add InfoHubs tab
IHTab_InfoHubs.fVisible( true );

Entry = new TabEntry_Object( "Questa SIM" );
List = new List_Object("infohub", "nosort");
List.fAddItem( "Questa SIM", "./index.html?infohub=questa_sim_ih" );
List.fAddItem( "Release Information", "./index.html?infohub=questa_rls_info_ih" );
Entry.fAddList( List );
IHTab_InfoHubs.fAddEntry( Entry );



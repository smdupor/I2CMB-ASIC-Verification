
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

// InfoHub data
var mInfoHub = "questa_rls_info_ih";
var mProductList = "all Questa SIM products.";

var Entry;
var List;

// Online Help & Manuals
IHTab_Olh.fVisible( true );

Entry = new TabEntry_Object( "Release Notes" );
List = new List_Object( "nosort" );
// ====> Update the following line for every release to use the current version number
List.fAddItem( "Questa SIM Release Notes: 2020.4", "./rlsnotes/RELEASE_NOTES.html" );
// ====> Uncomment the lines below for the applicable previous releases (Do not uncomment the current release)
// ======
//List.fAddItem( "Questa SIM Release Notes: 2020.4", "./rlsnotes/2020.4/RELEASE_NOTES.html" );
List.fAddItem( "Questa SIM Release Notes: 2020.3", "./rlsnotes/2020.3/RELEASE_NOTES.html" );
List.fAddItem( "Questa SIM Release Notes: 2020.2", "./rlsnotes/2020.2/RELEASE_NOTES.html" );
List.fAddItem( "Questa SIM Release Notes: 2020.1", "./rlsnotes/2020.1/RELEASE_NOTES.html" );
// ======
Entry.fAddList( List );
IHTab_Olh.fAddEntry( Entry );

Entry = new TabEntry_Object( "Install &amp; Licensing" );
List = new List_Object("doclist");
List.fAddItem( "Questa SIM Installation and Licensing Guide", "questa_sim_install" );
List.fAddItem( "Mentor Graphics Standard Licensing Manual", "mgc_licen", "pdf" );
List.fAddItem( "Release Notes for Mentor Graphics Standard Licensing Manual", "mgc_lic_rn", "pdf" );
List.fAddItem( "Third-Party Software for Questa and ModelSim Products", "third_party_ver", "pdf" );
List.fAddItem( "FlexNet License Administration Guide", "flexnet_admin", "pdf" );
Entry.fAddList( List );
IHTab_Olh.fAddEntry( Entry );


// Support
IHTab_Support.fVisible( true );

Entry = new TabEntry_Object( "Technical Support & Downloads" );
Entry.fAddLink( "Access Questa SIM Support Center site", "sim_microsite" );
IHTab_Support.fAddEntry( Entry );

Entry = new TabEntry_Object( "Contact Us" );
Entry.fAddLink( "Send feedback on the documentation", "feedback" );
Entry.fAddLink( "Visit www.mentor.com", "mentor" );
IHTab_Support.fAddEntry( Entry );


// Training
IHTab_Training.fVisible( true );

Entry = new TabEntry_Object( "Tutorials" );
List = new List_Object("doclist");
List.fAddItem( "Questa SIM Tutorial", "questa_sim_tut" );
List.fAddItem( "Verification Run Manager Tutorial User Guide", "tutorials_vrm_user" );
Entry.fAddList( List );
IHTab_Training.fAddEntry( Entry );

Entry = new TabEntry_Object( "Movies and Training Courses" );
Entry.fAddLink( "View How-To and Tutorial movies on Support Center", "animations", "A list of movies relating to the products supported by this InfoHub scope." );
Entry.fAddLink( "View available training courses", "training" );
IHTab_Training.fAddEntry( Entry );

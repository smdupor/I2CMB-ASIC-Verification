//
// Copyright 2010-2015 Mentor Graphics Corporation
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
var mInfoHub = "questa_sim_ih";
var mProductList = "Questa SIM, Power Aware, Unified Coverage Data Base, Verification Run Manager";

var Entry;
var List;

// Online Help & Manuals
IHTab_Olh.fVisible( true );

Entry = new TabEntry_Object( "Questa SIM Documentation" );
List = new List_Object("doclist", "nosort");
List.fAddItem( "Questa SIM User's Manual", "questa_sim_user" );
List.fAddItem( "Questa SIM GUI Reference Manual", "questa_sim_gui_ref" );
List.fAddItem( "Questa SIM Command Reference Manual", "questa_sim_ref" );
List.fAddItem( "Questa SIM Tutorial", "questa_sim_tut" );
List.fAddItem( "Power Aware Simulation User's Manual", "pa_user" );
List.fAddItem( "Foreign Language Interface Manual", "fli" );
List.fAddItem( "OVL Checkers Manager User's Guide", "vovl_user" );
List.fAddItem( "Questa Verification Management User's Manual", "questa_sim_vm" );
List.fAddItem( "Questa SIM Multi-core Simulation User's Guide", "questa_sim_multicore" );
List.fAddItem( "Questa SIM Encryption User's Manual", "questa_sim_encrypt_user" );
List.fAddItem( "Questa SIM Qrun User's Manual", "questa_sim_qrun_user" );
List.fAddItem( "Questa Verification Run Manager User Guide", "vrm_user" );
List.fAddItem( "Unified Coverage Data Base (UCDB) API Reference", "ucdbapi_ref" );
List.fAddItem( "Questa Quick Guide", "q_qk_guide", "pdf" );
List.fAddItem( "Questa SIM QIS Quick Reference Manual", "questa_qis_useref" );
Entry.fAddList( List );
IHTab_Olh.fAddEntry( Entry );


Entry = new TabEntry_Object( "OVM Reference" );
List = new List_Object("doclist", "nosort");
List.fAddItem( "OVM Class Reference", "ovm_ref", "pdf" );
Entry.fAddList( List );
IHTab_Olh.fAddEntry( Entry );


// Support
IHTab_Support.fVisible( true );

Entry = new TabEntry_Object( "Technical Support & Downloads" );
Entry.fAddLink( "Access Questa SIM Support Center site", "microsite" );
Entry.fAddLink( "Sign up for CustomerInsight Newsletter", "supportpro" );
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
Entry.fAddList( List );
IHTab_Training.fAddEntry( Entry );

Entry = new TabEntry_Object( "Videos and Training Courses" );
Entry.fAddLink( "View How-To and Tutorial videos on Support Center", "animations", "A list of videos relating to the products supported by this InfoHub scope." );
Entry.fAddLink( "View available training courses", "training" );
IHTab_Training.fAddEntry( Entry );

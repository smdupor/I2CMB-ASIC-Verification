{
  "specialparamshelp":{
    "mergefile": "please switch to Regression Settings Tab, enable Auto Merge, and edit Merge File field",
    "mergeoptions": "please switch to Regression Settings Tab, enable Auto Merge, and edit Additional Merge Options field",
    "coverstore": "please switch to Regression Settings Tab, enable Auto Merge, and select Coverstore in Coverage Type field",
    "tplanfile": "please switch to Regression Settings Tab, enable Auto Merge, select Yes in Import Testplan field, and edit Testplan File field",
    "tplanoptions": "please switch to Regression Settings Tab, enable Auto Merge, select Yes in Import Testplan field, edit Testplan File field, and edit Additional Import Options field",
    "triagefile": "please switch to Regression Settings Tab, enable Auto Triage, and edit Triage File field",
    "triageoptions": "please switch to Regression Settings Tab, enable Auto Triage, and edit Additional Options field",
    "trendfile": "please switch to Regression Settings Tab, enable Auto Trend, and edit Trend File field",
    "trendoptions": "please switch to Regression Settings Tab, enable Auto Trend, and edit Additional Options field",
    "nodelete": "please switch to Regression Settings Tab, check Delete files for passing simulations, and edit Files to Save field"
  },
  "regressionhelp": {
    "filemanagementhelp": {
      "title": "Automated File Management Options",
      "message": "VRM has the ability to automate cleanup and deletion of old files a couple of ways:<br/><br/><b>Delete previous regression results before running</b><br/>Before each new regression run, VRM can free up disk space by cleaning up the results of the previous regression(s).  This will remove all files associated with the previous run(s) which reside under the VRMDATA directory.  While individual test files will be removed, VRM will still maintain a history of those tests (as long as the VRMDATA directory itself is not completely removed i.e. rm -rf VRMDATA).<br/><br/><b>Delete files for passing simulations</b><br/>Often, it is unncessary to keep certain files for passing simulations, such as waveform and log files.  In this situation, VRM can check the pass/fail result of each test as they complete, and if the test is deemed to have passed, VRM can begin clean up of files from that simulation.  If there are specific files which VRM should not delete, use the \"Files to Save\" section to specify those files. This field accepts parameter referencing ex. (%parametername%)"
    },
    "mergehelp": {
      "mergefilehelp": {
        "title": "Location of Merged Coverage Results",
        "message": "In order for VRM to automatically merge test coverage results as they complete, VRM needs to know where you would like to save those results.  Use this field to specify the name and location (optional) of the merge file you would like VRM to create.<br/><br/>If only a filename is given, the merge file will be created directly under the VRMDATA directory. This field accepts parameter referencing ex. (%parametername%)"
      },
      "covtypehelp": {
        "title": "Coverage Storage Type Being Used",
        "message": "Depending on your environment, regression results will either be saved into a shared coverstore directory, or each test will create a seperate UCDB file.  Use this option to tell VRM what type of coverage output it should expect."
      },
      "covstorelochelp": {
        "title": "Specifying a Coverstore Directory",
        "message": "This field is used to indicate to VRM where the coverstore directory will reside.  This is where VRM will pull in test coverge results from for the pursposes of merging, and reporting. This field accepts parameter referencing ex. (%parametername%)"
      },
      "mergetypehelp": {
        "title": "Totals vs. Test-Associated Merge",
        "message": "Coverage can be merged in one of two ways:<br/><br/><b>Totals Merge</b><br/>This is the default merge type which sums all coverage scopes (union).  In a totals merge, information about which test hit which bins, as well as which test specifically contributed what coverage is lost.  However, the test data records of the tests themselves are retained.<br/>If you are not using the ranking tool (vcover ranktest) or using the test analysis features of Questa, then you should use a totals merge.<br/><b>Test-Associated Merge</b><br/>A test-associated merge includes all the data of a totals merge, as well as the test specific information of which test hit which bins.  This information is required for ranking, and the test analysis capabilities of Questa.  If you are using either of those features, you must use a test-assocated merge."
      },
      "mergetestshelp": {
        "title": "Determining Which Test Results to Merge",
        "message": "By default, VRM will only merge results from passing tests.  However, to also include coverage from failing tests as well, select \"All Tests\"."
      },
      "mergeoptshelp": {
        "title": "Adding Additional Merge Options",
        "message": "If you need to apply any additional options to the merge process, do so here.  Any switch which can be supplied to \"vcover merge\" is valid. This field accepts parameter referencing ex. (%parametername%)"
      },
      "testplanhelp": {
        "title": "Merging in a Testplan",
        "message": "Enabling this option will give you the ability to specify a testplan to be merged with your coverage results.  VRM will automatically pickup this testplan and merge it with test results as part of the auto-merge process."
      },
      "testplanfilehelp": {
        "title": "Testplan to Import",
        "message": "This file can be specified in two ways:<br/><br/><b>XML File</b><br/>An XML based testplan file, in which case VRM will convert the file to a UCDB automatically.<br/><br/><b>UCDB File</b><br/>A UCDB file which already contains a converted testplan (i.e. output of xml2ucdb or the Questa Excel Addin). This field accepts parameter referencing ex. (%parametername%)"
      },
      "testplanoptshelp": {
        "title": "Specifying Additional Testplan Import Options",
        "message": "If you need to apply additional options to the import of your testplan, do so here (i.e. specifying a different -datafields ordering than the default).  <br/><br/>If you have specified a UCDB file as the testplan input, this field will be ignored. This field accepts parameter referencing ex. (%parametername%)"
      }
    },
    "trendhelp": {
      "trendfilehelp": {
        "title": "Location of Trend UCDB File",
        "message": "Use this to specify the name and location (optional) of the trend UCDB file you would like VRM to create/append trend results to.  This will be done automatically at the end of each regression.<br/><br/>It is recommended that this file reside outside of the VRMDATA directory to ensure it does not get removed inadvertently when cleaning up existing regression files.<br/><br/>If only a filename is given, the trend file will be created directly under the VRMDATA directory. This field accepts parameter referencing ex. (%parametername%)"
      },
      "trendoptshelp": {
        "title": "Specifying Additional Trending Options",
        "message": "If you need to apply additional options to the automated trending process here, do so here. This field accepts parameter referencing ex. (%parametername%)"
      }
    },
    "triagehelp": {
      "traigefilehelp": {
        "title": "Triage Output File",
        "message": "When auto-triage is enabled, VRM will automatically run Results Analysis on the tests which meet the proper criteria (below) to be triaged.  Use this input to specify the location of the triage database file (tdb).<br/><br/>If only a filename is given, the triage file will be created directly under the VRMDATA directory. This field accepts parameter referencing ex. (%parametername%)"
      },
      "messagesevhelp": {
        "title": "Message Severities to Triage",
        "message": "You can choose which types of messages you want to capture in your triage database by selecting the message severities you are interested in.  You can also choose \"All Severities\" to capture all messages."
      },
      "teststatushelp": {
        "title": "Tests Results to Triage",
        "message": "By default only failing tests (those with a UCDB TESTSTATUS of Error or Fatal), are considered for triage.  You can optionally choose to enable triage of passing tests as well if you are interested in addtionaly information outside that of failing tests."
      },
      "transformfilehelp": {
        "title": "Applying a Transform File",
        "message": "To parse specific additional information out of the messages being triaged with a transform file, you can enter the path to your transform file here.<br/><br/>By default, triage will extract the following information:<br/><br/><ul><li>Message severity</li><br/><li>Message time</li><br/><li>Message string</li><br/><li>All UCDB attributes for the test (seed, simtime, etc.)</li><br/></ul>. This field accepts parameter referencing ex. (%parametername%)"
      },
      "triageoptshelp": {
        "title": "Specifying Additional Triage Options",
        "message": "If you need to specify any additional options to the automated triage process, do so here. This field accepts parameter referencing ex. (%parametername%)"
      }
    }
  },
  "compilehelp": {
    "gridhelp": {
      "title": "Where to Execute Compilation Job",
      "message": "VRM can run jobs either on the local machine or on a grid (if available).  If using a grid, ensure your grid is properly set up in the under Global Settings -> Grid Settings section."
    },
    "timeouthelp": {
      "title": "Specifying Compilation Timeouts",
      "message": "Once a job has begun execution, either locally or on a grid, VRM will monitor the time that job is executing.  By default, if the job does not complete within 5 minutes (300 seconds), an execution timeout will be triggered, and VRM will terminate the job to avoid wasting simulation resources for a job which may never complete.<br/><br/>You can modify this timeout value to be either longer or shorter, by specifying the amount of time (in seconds) VRM should wait before terminating a job.  Specifying 0 will disable compilation timeouts. This field accepts parameter referencing ex. (%parametername%)"
    },
    "sourcehelp": {
      "title": "Compiling with a Script or Specific Commands",
      "message": "You can choose to either have VRM run an existing script containing the necessary commands to compile the required files for the regression, or you can manually enter the compilation commands directly."
    },
    "commandshelp": {
      "title": "Specifying Compilation Commands",
      "message": "Here you must enter the commands, or the path to a script, required to properly compile (and optimize) your design. This field accepts parameter referencing ex. (%parametername%)"
    }
  },
  "simulatehelp": {
    "gridhelp": {
      "title": "Where to Execute Simulation Jobs",
      "message": "VRM can run jobs either on the local machine or on a grid (if available).  If using a grid, ensure your grid is properly set up in the under Global Settings -> Grid Settings section."
    },
    "timeouthelp": {
      "title": "Specifying Simulation Timeouts",
      "message": "Once a job has begun execution, either locally or on a grid, VRM will monitor the time that job is executing.  By default, if the job does not complete within 5 minutes (300 seconds), an execution timeout will be triggered, and VRM will terminate the job to avoid wasting simulation resources for a job which may never complete.<br/><br/>You can modify this timeout value to be either longer or shorter, by specifying the amount of time (in seconds) VRM should wait before terminating a job.  Specifying 0 will disable simulation timeouts. This field accepts parameter referencing ex. (%parametername%)"
    },
    "sourcehelp": {
      "title": "Simulating with a Script or Specific Commands",
      "message": "You can choose to either have VRM run an existing script containing the necessary commands to simulate a test, or you can manually enter the simulation commands directly."
    },
    "commandshelp": {
      "title": "Specifying Simulation Commands",
      "message": "Here you must enter the commands, or path to script required to properly simulate your design. This field accepts parameter referencing ex. (%parametername%)"
    }
  },
  "testlisthelp": {
    "sourcehelp": {
      "title": "Specifying a Testlist to Use",
      "message": "You can choose to either have VRM read in an existing testlist file, or you can manually enter the tests to run below, using the following format:<br/><br/># <testname> <repeat_count> <seed_values> <param_overrides><br/>my_test1 3 123 456 789<br/>my_test2 1 random SAMPLES=4<br/><br/>For more information on testlists, refer to RMDB reference section on testlist files, in the Questa Verification Run Manager User Guide."
    }
  },
  "reporthelp": {
    "htmlreporthelp": {
      "reportlochelp": {
        "title": "HTML Report Location",
        "message": "Specify the location of where you would like the generated HTML report to be placed."
      },
      "covrephelp": {
        "title": "Including Coverage HTML Report",
        "message": "The Regression HTML report will have pass/fail information for all tests, and overall coverage percentages.  VRM can also create a complete Coverage HTML report to allow for deeper coverage analysis."
      },
      "covrepoptshelp": {
        "title": "Coverage HTML Reporting Options",
        "message": "Allows you to choose what information you would like to be included in the Coverage HTML report.  For example, to analyze the annotated source in the HTML report, select the \"Include annotated source files in report\" option."
      },
      "htmlrepoptshelp": {
        "title": "Additional HTML Reporting Options",
        "message": "Common options are listed in the \"Reporting Options\" section above.  If there are additional options required, specify them here.  All options acceptable by \"vcover report -html\" are valid. This field accepts parameter referencing ex. (%parametername%)"
      }
    },
    "trendreporthelp": {
      "reportformathelp": {
        "title": "Trend Report Format",
        "message": "Specify the format you would like to use for the generated Trend report."
      },
      "reportlochelp": {
        "title": "Trend Report Location",
        "message": "Specify the location of where you would like the generated trend report to be placed. This field accepts parameter referencing ex. (%parametername%)"
      },
      "reportdateshelp": {
        "title": "Trending Date Range",
        "message": "By default, the trend report will include all trend information located in the trend UCDB.  If you would rather limit the data to a specific timeframe, do so here."
      },
      "graphtypehelp": {
        "title": "Choose Graph Type to Use",
        "message": "Select whether you would like the HTML report to generate either bar or line graphs for the trend data."
      },
      "trendrepoptshelp": {
        "title": "Additional Trend Reporting Options",
        "message": "If there are additional options required when generating the trend report, specify them here. This field accepts parameter referencing ex. (%parametername%)"
      }
    },
    "emailhelp": {
      "recepienthelp": {
        "title": "Email Recipients",
        "message": "Enter a TCL list of email addresses (comma or space seperated) to notify via email of the regression results.  Upon completion of the regression, each address specified will recieve a regression report email."
      },
      "subjecthelp": {
        "title": "Email Subject",
        "message": "This is the subject of the email that will be sent to the recipeients listed. This field accepts parameter referencing ex. (%parametername%)"
      },
      "messagehelp": {
        "title": "Adding a Custom Message",
        "message": "If you would like to add any additional information to the email message, type that message here. This field accepts parameter referencing ex. (%parametername%)"
      },
      "sectionshelp": {
        "title": "Selecting What Information to Place in the Email",
        "message": "You have the option to choose how much information VRM automatically inserts into the auto-generated email.  Each section correlates to the same named section in the VRM status report summary which is output at the end of a regression run."
      },
      "serverhelp": {
        "title": "Selecting Server to Use While Sending the Email",
        "message": "You need to set the Email server in the Global Settings page. You can either use your machine server or specify another SMTP server."
      }
    },
    "reportoptshelp": {
      "reportsourcehelp": {
        "title": "Additional Reporting",
        "message": "You can choose to have VRM run an existing script, or to type in additional reporting commands which will be ran once the regression is completed."
      },
      "reportcommandshelp": {
        "title": "Reporting Commands",
        "message": "You can type any additional TCL comamnds, or existing script, here.  Any commands entered, should be valid commands which can be executed from a vsim prompt. This field accepts parameter referencing ex. (%parametername%)"
      }
    }
  }
}

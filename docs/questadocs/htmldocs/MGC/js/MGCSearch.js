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
// MGCSearch.js - Search functionality shared by mgchelp and infohub
//

//internal weighting array for creating weighted results for topic searches.
weighting_array = {
1: 20,
2: 25,
3: 30,
4: 30,
5: 30,
"H1Apndx":   20,
"H2NoSplit": 25,
"H3NoSplit": 30,
"H4Split":   30,
"HExercise": 30,
"zCmdFunc":  125,
"zCmdFunc2": 125
};

skip_array = {
"a": 1,
"about": 1,
"after": 1,
"all": 1,
"also": 1,
"am": 1,
"an": 1,
"and": 1,
"another": 1,
"any": 1,
"are": 1,
"as": 1,
"at": 1,
"be": 1,
"because": 1,
"been": 1,
"before": 1,
"being": 1,
"between": 1,
"both": 1,
"but": 1,
"by": 1,
"came": 1,
"can": 1,
"come": 1,
"copyright": 1,
"corp": 1,
"corporation": 1,
"could": 1,
"did": 1,
"do": 1,
"does": 1,
"each": 1,
"etc": 1,
"for": 1,
"from": 1,
"get": 1,
"goes": 1,
"got": 1,
"had": 1,
"has": 1,
"have": 1,
"he": 1,
"her": 1,
"here": 1,
"him": 1,
"himself": 1,
"his": 1,
"how": 1,
"if": 1,
"in": 1,
"inc": 1,
"into": 1,
"is": 1,
"it": 1,
"its": 1,
"let": 1,
"like": 1,
"make": 1,
"many": 1,
"me": 1,
"mentor": 1,
"might": 1,
"more": 1,
"most": 1,
"much": 1,
"must": 1,
"my": 1,
"never": 1,
"nor": 1,
"not": 1,
"now": 1,
"of": 1,
"off": 1,
"on": 1,
"one": 1,
"only": 1,
"or": 1,
"other": 1,
"our": 1,
"out": 1,
"over": 1,
"own": 1,
"rights": 1,
"said": 1,
"same": 1,
"see": 1,
"set": 1,
"shall": 1,
"she": 1,
"should": 1,
"since": 1,
"so": 1,
"some": 1,
"still": 1,
"such": 1,
"take": 1,
"than": 1,
"that": 1,
"the": 1,
"their": 1,
"them": 1,
"then": 1,
"there": 1,
"these": 1,
"they": 1,
"this": 1,
"those": 1,
"though": 1,
"through": 1,
"to": 1,
"too": 1,
"under": 1,
"us": 1,
"use": 1,
"very": 1,
"was": 1,
"way": 1,
"we": 1,
"well": 1,
"were": 1,
"what": 1,
"when": 1,
"where": 1,
"which": 1,
"while": 1,
"who": 1,
"why": 1,
"will": 1,
"with": 1,
"would": 1,
"yes": 1,
"yet": 1,
"you": 1,
"your": 1
};

function MGCExecuteSearch( handle, searchWords, filter )
{
    // Since MGCExecuteSearch executes per book, we'll need to have an array of topic search results and every time we find a result update the
    // appropiate index in the array. To accomplish this we'll create an associative array with the topic number as an index.
    var results = [];
    var synonyms = [];

    // searchWords contains the query that a user types, so it is more than likely more than one word.
    searchWords = applySearchFilter(searchWords);
    for ( var i in searchWords ) {
        var search_word_array = [searchWords[i]];
        var synonym_word = searchWords[i];
        var match_letter = [];
        // look up synonyms for each word in the query
        var synLookup = [];
        if ( filter.include_synonyms ) {
            synLookup = MGCGetSynonyms( handle, synonym_word, searchWords );
        }
        for ( var word in synLookup ) {
            search_word_array.push(synLookup[word]);
            synonyms.push(synLookup[word][0]);
        }

        // once we include synonyms, we can split off and search topics, if a user only wants to search them
        if ( filter.show_topic_titles ) {
            MGCTopicSearch( handle, searchWords, filter );
            return;
        }
    
        var rere = new RegExp("([({[^$*+?\\\]})])","g"); /* you need 2 '\' s to mean 1 '\' and another '\' to treat ']' as special character instead of the characters ending bracket */
        for ( var j in search_word_array ) {
            var word = search_word_array[j][0].toLowerCase();
            word = word.replace(rere,"\\$1"); /* replace the special characters with a \ before them */
            AllLetters = ["symbol","num","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"];
            SearchVal = word.toString();
            Pre_Asterisk = false;
            Post_Asterisk = false;
            if ( SearchVal.charAt(1) == "*" ) Pre_Asterisk = true;
            if ( SearchVal.charAt(SearchVal.length-1) == "*" ) Post_Asterisk = true;
            word = SearchVal = SearchVal.replace(/^\\\*/,"");
            word = SearchVal = SearchVal.replace(/\\\*$/,"");
            Letter = SearchVal.charAt(0).toLowerCase();
            var CharTest = new RegExp("^[\\W]*\(\\w\)", "i");  // ignore symbol characters at beginning of word
            var test = word.match(CharTest);
            if ( test == null ) {
                Letter = "symbol";
            } else {
                Letter = test[1];
            }
            CurrentLetter = "symbol";
            if ( Letter >= "0" && Letter <= "9" ) {
                Letter = "num";
                CurrentLetter = "number";
            }
            if ( Letter >= "a" && Letter <= "z" ) CurrentLetter = "letter";
            if ( CurrentLetter == "symbol" ) Letter = "symbol";
            if ( ! Pre_Asterisk ) {
                AllLetters = [Letter];
            }
    
            // Generate the regular expression that we want to use to do the searching.
            // Force exact match if word is 2 or less characters, or if search word is in the "exclude" array.
            // Excluded words will only come through if they are a zcmdfunc or zcmdfunc2
            if ( filter.exact_match || word.length <= 2 || search_word_array[j][1] ) {
                if ( Pre_Asterisk ) {
                    SearchString = new RegExp("^[\\W]*\\*"+word+"$","i");
                } else {
                    SearchString = new RegExp("^[\\W]*"+word+"$","i");
                }
            } else {
                if ( Pre_Asterisk && !Post_Asterisk ) {
                    SearchString = new RegExp("^[\\W\\w]*"+word+"$", "i");
                } else if ( Pre_Asterisk && Post_Asterisk ) {
                    SearchString = new RegExp("^[\\W\\w]*"+word, "i");
                } else {
                    SearchString = new RegExp("^[\\W]*"+word, "i");
                }
            }
          
            for ( var LIndex = 0; LIndex < AllLetters.length; LIndex++ ) {
                Letter = AllLetters[LIndex];
                for ( var SIndex = 0; SIndex < BookData[handle]["search"][Letter].length; SIndex++ ) {
                    if ( SearchString.test(BookData[handle]["search"][Letter][SIndex][0]) ) {
                        var result = BookData[handle]["search"][Letter][SIndex][1];
                        for ( var TIndex = 0; TIndex < result.length; TIndex += 2 ) {
                            var topic_id = result[TIndex];
                            // if we've already added this index to the array of book search results, update the word count and weight
                            if ( results[topic_id] != undefined ) {
                                if ( match_letter[topic_id] == undefined || match_letter[topic_id] == false ) {
                                    results[topic_id].word_count++;
                                    match_letter[topic_id] = true;
                                }
                                results[topic_id].weight += result[TIndex+1];
                                results[topic_id].matching_word = results[topic_id].matching_word + BookData[handle]["search"][Letter][SIndex][0] + " ";
                            } else {
                                results[topic_id] = {
                                    book: handle,
                                    file_name: "",
                                    handle: topic_id + 1,
                                    snippet: "",
                                    doc_type: "",
                                    doc_title: "",
                                    file_link: "",
                                    synonym: "",
                                    search_term: "",
                                    matching_word: BookData[handle]["search"][Letter][SIndex][0] + " ",
                                    weight: result[TIndex+1],
                                    word_count: 1
                                };
                                match_letter[topic_id] = true;
                            }
                        }
                    }
                }
            }
        }
    }
    synonyms = unique(synonyms);

    //after we've made an array of search results, populate the object fields with real values
    for ( var j in results ) {
        var ID = results[j].handle;
        var file_name = MGC_ID_to_File(results[j].book,ID);
        var file_link = "";
        //the file link needs to be different for infohubs than htmldocs, so split based on which one we're creating the link for
        if ( filter.infohubs ) {
            file_link = MGCTreeLoc + "/mgchelp.htm#context=" + results[j].book + "&id=" + ID + "&ihub=" + mInfoHub;
            if ( filter.exact_match ) file_link += "&exact=true";
            if ( filter.show_topic_titles ) file_link += "&topiconly=true";
        } else {
            file_link = ID + ', "#SString1", "' + results[j].book + '", 1, "")';
        }
        var topic = MGC_ID_to_Topic(results[j].book, ID);
        var snippet = BookData[results[j].book].paratext[ID-1][1] + "...";
        results[j].file_name = file_name;
        results[j].file_link = file_link;
        results[j].doc_title = topic;
        results[j].snippet = snippet;
        // doc_type is always "document" for now, could include additional types in future
        results[j].doc_type = "document";
        AllSearchResults.push(results[j]);
    }
}

function MGCGetSynonyms( handle, keyword, searchWords )
{
    var Synonyms = [];
    for ( var sIndex = 0; sIndex < BookData[handle]["synonyms"].length; sIndex++ ) {
        if ( keyword[0] == BookData[handle]["synonyms"][sIndex][0] ) {
            var CurrentDef = BookData[handle]["synonyms"][sIndex];
            for ( var sIx = 1 ; sIx < CurrentDef.length ; sIx++ ) {
                if ( CurrentDef[sIx] != keyword[0] ) {
                    var append_synonym = true;
                    // make sure that the synonym we're pushing onto the array doesn't already exist
                    // example: search query of "delete remove" where remove is a synonym of delete
                    for ( var test in searchWords ) {
                        if ( searchWords[test][0] == CurrentDef[sIx] ) {
                            append_synonym = false;
                        }
                    }
                    if ( append_synonym ) {
                        AllSynonyms.push( CurrentDef[sIx] );
                        // assign synonym the same "exact search" properties as it's parent
                        Synonyms.push( [CurrentDef[sIx], keyword[1]] );
                    }
                }
            }
        }
    }
    return Synonyms;
}

function MGCTopicSearch( handle, searchWords, filter )
{
    //if synonyms were included, there could be multiple words we're searching for
    var SearchString;
    var results = [];
    var rere = new RegExp("([({[^$*+?\\\]})])","g");
    for ( var i=0; i < BookData[handle]["toc"].length; i++ ) {
        var toc_level = BookData[handle]["toc"][i][0];
        var toc_id    = BookData[handle]["toc"][i][1];
        var toc_title = BookData[handle]["toc"][i][2];
        var toc_tag   = BookData[handle]["toc"][i][3];
        for ( var j in searchWords ) {
            // escape special characters in word with backslash
            var word = searchWords[j][0].toLowerCase().replace(rere,"\\$1");
            if ( filter.exact_match ) {
                SearchString = new RegExp("\\b"+word+"\\b","ig");
            } else {
                SearchString = new RegExp("\\b"+word+"[\\w]*\\b", "gi");
            }
            var topic = toc_title.toLowerCase();
            // test to see if the search word exists in the topic
            // it must also be a heading type defined in weighting_array
            if ( SearchString.test(topic) && ( typeof weighting_array[toc_level] != "undefined" ) ) {
                var matches = topic.match(SearchString);
                var word_matches = matches.join(" ");
                var weight = weighting_array[toc_level];
                // if we've already added this index to the array of book search results, update the word count and weight
                if ( results[toc_id] != undefined ) {
                    results[toc_id].word_count.push(word);
                    results[toc_id].weight += (matches.length * weight);
                    results[toc_id].matching_word = results[toc_id].matching_word + word_matches + " ";
                } else {
                    results[toc_id] = {
                        book: handle,
                        file_name: "",
                        handle: toc_id,
                        snippet: "",
                        doc_type: [],
                        doc_title: "",
                        file_link: "",
                        synonym: "",
                        search_term: "",
                        matching_word: word_matches + " ",
                        weight: matches.length * weight,
                        word_count: [word]
                    };
                }
                //Topic results have a different format than normal results. We must store the direct links to the topic(s) that match our keywords somewhere.
                //for the meantime, we will store them in the "doc_type" member of our data structure, and then take them out when we're processing the data later on
                //reset doc_link variable to null string every time, otherwise we can run into some odd behavior
                var doc_link = "";
                // don't add a subtopic with the same title as the page heading
                if ( toc_title.replace(/^\s+|\s+$/g, "") != MGC_ID_to_Topic(handle, toc_id).replace(/^\s+|\s+$/g, "") ) {
                    if ( filter.infohubs ) {
                        var syn = unique(AllSynonyms);
                        doc_link = "<li><a href='";
                        doc_link += ResultLink( results[toc_id].book, results[toc_id].handle, toc_tag, results[toc_id].matching_word, filter.infohubs, filter.show_topic_titles, filter.exact_match );
                        doc_link += "&Sword=" + encodeURIComponent(mSearchWords);
                        if ( syn.length > 0 ) doc_link += "&Syn=" + encodeURIComponent(syn.join(" "));
                        doc_link += "' target='_blank'>" + toc_title + "</a></li>";
                    } else {
                        doc_link = "<li><a href='javascript:SearchTopicDisplay(0, "
                        doc_link += ResultLink( results[toc_id].book, results[toc_id].handle, toc_tag, results[toc_id].matching_word, filter.infohubs, filter.show_topic_titles, filter.exact_match );
                        doc_link += "' title='" + toc_title + "'>" + toc_title + "</a></li>";
                    }
                }
                if ( doc_link ) {
                    results[toc_id].doc_type[i] = doc_link;
                }
            }
        }
    }

    for ( var idx in results ) {
        var ID = results[idx].handle;
        var file_name = MGC_ID_to_File(results[idx].book,ID);
        var file_link = ResultLink( results[idx].book, ID, "SString1", results[idx].matching_word, filter.infohubs, filter.show_topic_titles, filter.exact_match );
        var topic = MGC_ID_to_Topic( results[idx].book, ID );
        var snippet = BookData[results[idx].book].paratext[ID-1][1] + '...';
        //If the topic/doc_title is the same as the subtopic, we don't want to display the subtopic twice, so we won't add it to
        //the doc_type array. If there are not any other results in the doc_type array, don't display the "subtopics:" heading, because
        //there are no subtopics to display
        if ( results[idx].doc_type.length > 0 ) {
            snippet += '<br /><span class="subtopics">Additional subtopics:</span><ul class="topic_result_ul">' + results[idx].doc_type.join(" ") + '</ul>';
        }
        results[idx].doc_title = topic;
        results[idx].snippet = snippet;
        results[idx].word_count = unique(results[idx].word_count).length;
        results[idx].doc_type = "Document";
        results[idx].file_link = file_link;
        results[idx].file_name = file_name;
        // make sure the matching_word tooltip doesn't have duplicates, a string, and has "'" characters filtered out.
        results[idx].matching_word = unique(results[idx].matching_word.split(" ")).join(" ").replace("'", "#&39;");
        AllSearchResults.push(results[idx]);
    }
}

function ResultLink( book, id, tag, matching_word, infohub, topiconly, exact )
{
    var file_link = "";
    if ( typeof tag == "undefined" ) tag = "SString1";
    if ( infohub ) {
        file_link = MGCTreeLoc + "/mgchelp.htm#context=" + book + "&id=" + id + "&ihub=" + mInfoHub;
        file_link += "&scrollid=" + tag;
        if ( topiconly ) file_link += "&topiconly=" + topiconly;
        if ( exact ) file_link += "&exact=" + exact;
     } else {
        file_link = id;
        file_link += ", \"" + tag + "\", \"" + book + "\", 1, \"" + unique(matching_word.split(" ")).join(" ");
        file_link += topiconly ? "\", true);" : "\")";
     }
     return file_link;
}

function compareTotals( a, b )
{
    if ( b.word_count < a.word_count ) {
        return -1;
    }
    if ( b.word_count > a.word_count ) {
        return 1;
    } else {
        return b.weight - a.weight;
    }
}

function applyWordFilter( searchWords )
{
    if ( typeof searchWords != "string" || searchWords == "" ) return "";
    // remove apostrophes, replace white space characters with space, strip leading/trailing space,
    // and finally replace consecutive spaces with single space
    var sw = searchWords.toLowerCase()
                        .replace(/[']|%27/g,"")
                        .replace(/[<>+=,?!;|@~"\^\{\}\[\]\(\)\/\\]+/g," ")
                        .replace(/^\s+|\s+$/g,"")
                        .replace(/\s+/g," ");
    return sw;
}

function applySearchFilter( searchWordArray )
{
    var sw = [];
    for ( var i = 0; i < searchWordArray.length; i++ ) {
        if ( searchWordArray[i] != "*" ) {
            if ( skip_array[searchWordArray[i]] == undefined ) {
                sw.push([searchWordArray[i],false]);
            } else {
                sw.push([searchWordArray[i],true]);
            }
        }
    }
    return sw;
}

function unique(a)
{
    a.sort();
    for(var i = 1;i < a.length;){
        if(a[i-1] == a[i]){a.splice(i, 1);}
        else{i++;}
    }
    if(a[0]==""){
        a.splice(0,1)
    }
    if(a[a.length-1] == ""){
        a.splice(a.length-1,1)
    }
    return a;
}

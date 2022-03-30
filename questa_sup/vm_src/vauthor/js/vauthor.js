//
// jQuery extension to insert text at the cursor in
//   an input or textarea element
//
jQuery.fn.extend({

    getCaretPos: function(){
	var el = $(this).get(0);
        var pos = 0;
        if('selectionStart' in el) {
            pos = el.selectionStart;
        } else if('selection' in document) {
            el.focus();
            var Sel = document.selection.createRange();
            var SelLength = document.selection.createRange().text.length;
            Sel.moveStart('character', -el.value.length);
            pos = Sel.text.length - SelLength;
        }
        return pos;
    },
    insertAtCaret: function(str){
        return this.each(function(i) {

            if (document.selection) { // IE
                this.focus();

                sel      = document.selection.createRange();
                sel.text = str;

                this.focus();
            }

            else if (this.selectionStart || this.selectionStart == '0') { // WebKit
                var startPos  = this.selectionStart;
                var endPos    = this.selectionEnd;
                var scrollTop = this.scrollTop;

                this.value = this.value.substring(0, startPos)
                           + str
                           + this.value.substring(endPos, this.value.length);

                this.focus();

                this.selectionStart = startPos + str.length;
                this.selectionEnd   = startPos + str.length;
                this.scrollTop      = scrollTop;

            } else { // Append by default
                this.value += str;

                this.focus();
            }
        });
    },

    insertRmdbParameter: function(options) {
        var settings = $.extend(true, {}, options); // no defaults for now

        var keys = settings.categories.map(function(category) {return category.key;});

        $('#paramSelectDialog tbody').empty();

        $.ajax({
            type: 'GET',
            url: settings.suite + '/keys.json',
            data: {'keys': keys},
            dataType: 'json',
            context: this,
            success: function(results) {
                for (var i in settings.categories) {
                    var category = settings.categories[i];

                    for (var j in results) {
                        var result = results[j];

                        if (result.key == category.key) {

                            for (var k in result.value) {
                                var param = result.value[k];

				                var newRow = $('<tr/>').appendTo('#paramSelectDialog tbody');

				                $('<td/>').appendTo(newRow).append(
                                    '<input type="checkbox" value="' + param.name + '" />'
                                );
				                $('<td/>').appendTo(newRow).text(category.name);
				                $('<td/>').appendTo(newRow).text(param.name);
				                $('<td/>').appendTo(newRow).text(param.value);
                            }
                        }
                    }
                }

                $('#paramSelectDialog button[type="submit"]').one('click', {target: this}, function(e) {

                    $('#paramSelectDialog input[type="checkbox"]:checked').each(function() {
                        $(e.data.target).insertAtCaret('(%' + this.value + '%)');
                    });

                    if (settings.success && typeof(settings.success) === "function") {
                        settings.success(results);
                    }
                });

                $('#paramSelectDialog').modal();
            },
            failure: function(msg) {
                if (settings.failure && typeof(settings.failure) === "function") {
                    settings.failure(msg);
                }
            }
        });
    }
});

function extractTerm(input) {
    var end = $(input).getCaretPos()
    var tillCursor = input.value.substring(0, end);
    var begin = tillCursor.lastIndexOf('(%');
    if (begin != -1) {
        return tillCursor.substring(begin + 2);
    }
    return undefined;
}
function paramRefAutoComplete(visibleparams) {
	$('.paramRef').autocomplete({
	    source: function (request, response) {
	        var term = extractTerm(this.bindings[0])
	        var re = $.ui.autocomplete.escapeRegex(term);
	        var matcher = new RegExp(re, "i");
	        a = $.grep(visibleparams, function (item, index) {
	            return matcher.test(item);
	        });
	        response(a);
	    },
	    search: function () {
		if (visibleparams == undefined){
			return false;
		}
	        var term = extractTerm(this);
	        if (term == undefined) {
	            return false;
	        }
	    },
	    focus: function () {
	        // prevent value inserted on focus
	        return false;
	    },
	    select: function (event, ui) {
	        var caret = $(this).getCaretPos();
	        var term = extractTerm(this);
	        this.value = this.value.substring(0, caret - term.length - 2) + "(%" + ui.item.value + "%)" + this.value.substring(caret);
	        return false;
	    }
	});
}

function paramNameAutoComplete(overridableparams) {
	$('.paramName').autocomplete({
	    source: overridableparams,
	    search: function () {
		if (overridableparams == undefined){
			return false;
		}
	        // custom minLength
	        if (this.value.length<2) {
	            return false;
	        }
	    },
	    focus: function () {
	        // prevent value inserted on focus
	        return false;
	    }
	});
}

import tempita

def get_params_table(formname, space, parameters, regparameters, speparameters, specialMessages):

    template = tempita.HTMLTemplate('''\
<div  class="row">
        <div class="col-lg-12">
            <div class="panel panel-primary">
                <div class="panel-heading">
                    <h3 class="panel-title">Parameters</h3>
                    <i id="{{formname}}param-helpBtn" class="fa fa-lg fa-question pull-right" style="margin-top:-17px;;cursor:pointer;"></i>
                </div>
	      <div id="{{formname}}param-helpDlg" class="modal fade" role="dialog">
		<div class="modal-dialog">
		  <div class="modal-content">
		    <div class="modal-header">
		      <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
		      <h4 class="modal-title">Parameters Help</h4>
		    </div>
		    <div class="modal-body"></div><!-- dynamic -->
		  </div>
		</div>
	      </div>
                <div class="panel-body">
                    <form method="post" role="form" id="{{formname}}-form">
                        <div class="table-responsive">
                            <table class="table table-condensed">
                                <thead>
                                    <tr>
                                        <th class="col-sm-2">Name</th>
                                        <th class="col-sm-6">Value</th>
                                        <th class="col-sm-2">Type</th>
                                        <th class="col-sm-1">Export</th>
                                        <th class="col-sm-1"></th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr class="newRow hidden"><!-- empty row for cloning -->
                                        <td>
                                             <div class="ui-widget">
                                            <input type="text" class="form-control" placeholder="Name" value="" />
                                             </div>
                                        </td>
                                        <td>
                                            <div class="ui-widget">
                                                <input type="text" class="form-control paramRef" placeholder="Value" value="" />
                                            </div>
                                        </td> 
                                        <td>
                                         <div class="ui-widget">
                                            <select name="paramtype" class="form-control paramRef" placeholder="Type" value="Text">
                                                <option value="text">Text</option>
                                                <option value="tcl">Tcl</option>
                                                <option value="file">File</option>
                                            </select>
                                               </div>
                                        </td>
                                        <td>
                                            <div class="ui-widget">
                                                <input type="checkbox"  class="paramRef" name="paramexport" placeholder="Export"/> 
                                            </div>
                                        </td>
                                        <td class="deleteBtn">
                                            <i class="fa fa-lg fa-trash-o" style="vertical-align:middle;padding-top:7px;cursor:pointer;"></i>
                                        </td>
                                    </tr>
                                    {{for parameter in parameters}}
                                    <tr >
                                        <td>
                                            <div class="ui-widget">
                                                <input type="text" class="form-control" placeholder="Name" value="{{parameter['name']}}" />
                                            </div>
                                        </td>
                                        <td>
                                            <div class="ui-widget">
                                                <input type="text" class="form-control paramRef" placeholder="Value" value="{{parameter['value']}}" />
                                            <div>
                                        </td>
                                        <td>
                                             <div class="ui-widget">
                                            <select name="paramtype" class="form-control paramRef" placeholder="Type">
                                                {{if parameter['type'] == 'tcl'}}
                                                   <option value="text">Text</option>
                                                   <option value="tcl" selected >Tcl</option>
                                                   <option value="file">File</option>
                                                {{elif parameter['type'] == 'file'}}
                                                    <option value="text">Text</option>
                                                    <option value="tcl">Tcl</option>
                                                    <option value="file" selected>File</option>
                                                {{else}}
                                                    <option value="text">Text</option>
                                                    <option value="tcl">Tcl</option>
                                                    <option value="file">File</option>
                                                {{endif}}
                                            </select>
                                               </div>
                                        </td>
                                        <td>
                                            <div class="ui-widget">
                                                <input type="checkbox" class="paramRef" name="paramexport" placeholder="Export" {{if parameter['export'] == '1'}} checked="checked" {{endif}} /> 
                                            </div>
                                        </td>
                                        <td class="deleteBtn">
                                            <i class="fa fa-lg fa-trash-o" style="vertical-align:middle;cursor:pointer;"></i>
                                        </td>
                                    </tr>
                                    {{endfor}}
                                </tbody>
                            </table>
                        </div>
                        <div style="margin-left: 20px;">
                            <button class="btn btn-primary addBtn btn-sm"><i class="fa fa-fw fa-plus" type="button"></i> Add Parameter</button>
                            <!--button style="margin-left: 20px;" class="btn btn-primary insertBtn btn-sm"><i class="fa fa-fw fa-pencil-square-o"></i> Insert Parameter Reference</button-->
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div> 
    <script>
    $("#{{formname}}param-helpBtn").on('click', function(){
        $("#{{formname}}param-helpDlg .modal-body").load('/pages/paramHelp.htm', function() {
            $("#{{formname}}param-helpDlg").modal();
        });
    });

var addedParameters = [];
var specialParameters = [];
var special = [];
{{if formname != "regparam"}}
{{for parameter in parameters}}
	addedParameters.push("{{parameter['name']}}");
{{endfor}}
{{endif}}
{{for parameter in regparameters}}
	addedParameters.push("{{parameter['name']}}");
{{endfor}}
{{for parameter in speparameters}}
	specialParameters.push("{{parameter}}");
{{endfor}}
var visibleparams = [
        "DATADIR",
        "RMDBDIR",
        "RMDBFILE",
        "MODEL_TECH",
        "CONTEXT",
        "INSTANCE",
        "ITERATION",
        "RUNNABLE",
        "TASKDIR",
        "VSIMDIR",
        "VRUNDIR",
	"testname",
	"seed"
    ];
    visibleparams = visibleparams.concat(addedParameters);
    visibleparams = visibleparams.concat(specialParameters);
    visibleparams.sort();
    paramRefAutoComplete(visibleparams)
{{for key, value in specialMessages.items()}}
        special["{{key}}"] = "{{value}}";
{{endfor}}
            function getParams{{formname}}() {
                var param = [];
                // collext all rows EXCEPT the dummy empty row
                $('#{{formname}}-form table tbody tr:not(.newRow)').each(function (index) {
                    var name = $('td:nth-child(1) input', this).val();
                    var value = $('td:nth-child(2) input', this).val();
                    var type = $('td:nth-child(3) select', this).val();
                    var e = $('td:nth-child(4) input:checked', this).val();
                    if (e == "on") {
                        e = "1";
                    } else {
                        e = "0";
                    }
		    if (name && $.inArray(name, specialParameters) == -1 && /^[a-zA-Z0-9_]+$/.test(name))
                        param.push({'name': name, 'value': value, 'type': type, 'export': e});
		    else
			$(this).fadeOut(1000, function () {
	            	    $(this).remove();
			})
                });
                return param;
            }
            $('#{{formname}}-form').on('click', 'td.deleteBtn', function (e) {
                var row = $(this).parent('tr');
		var name = row.children().first().children().first().children().first().val();
		var index = visibleparams.indexOf(name);
		if (index > -1) {
 		   visibleparams.splice(index, 1);
		}
		$(row).addClass("danger");
                $(row).fadeOut(1000, function () {
                    $(this).remove();
                });
		
                EnableButtons(true); // enable save/reset if any row is deleted
                return false;
            });
            $('#{{formname}}-form button.addBtn').on("click", function (e) {
                var newRow = $('#{{formname}}-form tr.newRow').clone();

                newRow.removeClass('newRow hidden');
		newRow.focusout(function(){
			var name = newRow.children().first().children().first().children().first().val();
			if (visibleparams.indexOf(name) < 0)
				visibleparams.push(name);
		})
		newRow.children().first().children().first().children().first().focusout(function(){
                        var name = $(this).val();
                        if ($.inArray(name, specialParameters) > -1) {
                                willNotSave(name);
				newRow.addClass('danger');
			} else {
			if (! /^[a-zA-Z0-9_]+$/.test(name)) {
				editParam(name);
				newRow.addClass('danger');
			} else {
				newRow.removeClass('danger');	
			}	
			}	
                })

                $('#{{formname}}-form tbody').append(newRow);
                paramRefAutoComplete(visibleparams);

                EnableButtons(true); // enable save/reset if a row is added

                return false;
            });
            $('#{{formname}}-form').on('focusin', 'input', function (e) {
                $('#{{formname}}-form input').removeClass('lastFocus');
                $(this).addClass('lastFocus');
            });
	    function editParam(name) {
                if ($('#modalEditName').length) {
			$('#modalEditName').remove();
		}
	       $('body').append(
		'<div id="modalEditName" class="modal fade" role="dialog" aria-hidden="true">' +
		'  <div class="modal-dialog">' +
		'    <div class="modal-content">' +
		'      <div class="modal-header">' +
		'        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>' +
		'        <h4 class="modal-title">"' + name + '" parameter will not be saved!</h4>' +
		'      </div>' +
		'      <div class="modal-body">Parameters cannot contain spaces or special characters. Please edit the name</div>' +
		'    </div>' +
		'  </div>' +
                '</div>');
                

                $('#modalEditName').modal();
                return false;
            }

	    function willNotSave(name) {
		var message = special[name];
                if ($('#modalNotSave').length) {
			$('#modalNotSave').remove();
		}
	       $('body').append(
		'<div id="modalNotSave" class="modal fade" role="dialog" aria-hidden="true">' +
		'  <div class="modal-dialog">' +
		'    <div class="modal-content">' +
		'      <div class="modal-header">' +
		'        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>' +
		'        <h4 class="modal-title">"' + name + '" parameter will not be saved. Please delete it from the parameters list!</h4>' +
		'      </div>' +
		'      <div class="modal-body">To set '+name +', ' + message + '</div>' +
		'    </div>' +
		'  </div>' +
                '</div>');
                

                $('#modalNotSave').modal();
                return false;
            }


    </script>''')
    return template.substitute(locals())

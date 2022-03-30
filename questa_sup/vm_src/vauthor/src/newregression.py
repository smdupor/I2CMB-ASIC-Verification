import tempita

def get_newregression_button(formname, buttontext):

   template = tempita.HTMLTemplate('''\
    <div id="{{formname}}-newDlg" class="modal fade" role="dialog">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
            <h4 class="modal-title">Create New Regression Suite</h4>
          </div>
          <div class="modal-body">
            <form role="form">
              <div class="form-group">
                <label for="{{formname}}-newName">Suite Name</label>
                <input class="form-control" id="{{formname}}-newName" placeholder="Enter suite name" type="text" required>
              </div>
              <div class="form-group">
                <label for="{{formname}}-newTemplate">Template</label>
                <select class="form-control" id="{{formname}}-newTemplate" style="transition: none !important">
                  <option>Loading...</option>
                </select>
              </div>
            </form>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
            <button type="submit" class="btn btn-primary">Create Suite</button>
          </div>
        </div>
      </div>
    </div>
    <a class="btn btn-primary" onclick='addRegression()'>{{buttontext}}</a>
    <script>
    // Add a new regression suite
  //
  function addRegression() {

      // (1) Fetch the current template list and populate the drop-down selector
      $.ajax({
          type: "GET",
          url: "/templates.json",
          dataType: "json",
          success: function(templates) {
              $('#{{formname}}-newTemplate').empty();
              $.each(templates, function(index, name) {   
                   $('#{{formname}}-newTemplate').append($('<option>').text(name)); 
              });

              // (2) Open the modal dialog

              $("#{{formname}}-newDlg").modal('show');
          },
          failure: function(msg) {
              alert('Error: ' + msg);
          }
      });
  }

  $('#{{formname}}-newDlg button[type="submit"]').on('click', function(e) {
      // (3) Grab the suite name and template name from the dialog

      var jsonData = {
          name:     $('#{{formname}}-newName').val(),
          template: $('#{{formname}}-newTemplate option:selected').text()
      };
	jsonData.name = jsonData.name.replace("#", "%");
$.ajax({
          type: "GET",
          url: "/validate/suite?suitename="+jsonData.name,
          contentType: "application/json; charset=utf-8",
          dataType: "text",
          success: function(data) {
      // (4) Tell the server to create the suite's data file

      $.ajax({
          type: "POST",
          url: "/create",
          data: JSON.stringify(jsonData),
          contentType: "application/json; charset=utf-8",
          dataType: "text",
          success: function(data) {
              var href = '/generate/' + jsonData['name'] + '.tar';
          
              // (5) Add the new suite to the visible list
              {{if formname == 'home'}}
              $('#{{formname}}-suiteTable tbody').append(
                  '<tr><td class="suite-select">' +
                  '  <a class="suite-name" data-target="#home-panel" href="/pages/suite.htm?suitename=' + jsonData['name'] + '" onclick="navigatePanel(this)">' + jsonData['name'] + '</a>' +
                  '</td><td>' + jsonData['template'] + '</td><td>' +
                  '  <a class="btn btn-success generateBtn" href="' + href + '"><i class="fa fa-fw fa-refresh"></i> Generate</a>' +
                  '</td><td class="suite-delete">' +
      '  <i class="fa fa-lg fa-trash-o" style="vertical-align:middle;cursor:pointer;"> </i>' +
                  '</td></tr>');
  $('#reglist').append(
              '<li class="indent active"><a class="mainmenu" data-target="#home-panel" suite="'+jsonData['name'] +'" href="/pages/suite.htm?suitename='+ jsonData['name']+'" onclick="if (suiteEditted || globalEditted) {var name = $(this).attr(\\'href\\'); return ConfirmMove(name);} else {return navigatePanel(this)}">'+jsonData['name']+'</a>'+
              '</li>');
              {{endif}}
                  $('#{{formname}}-newDlg').find('.modal-header').find('#{{formname}}-error').remove();
		          $('#{{formname}}-newDlg').modal('hide');
		          },
		          error: function(msg) {
		              alert('Error: ' + msg);
		          }
		      });
          },
          error: function(msg) {
                $('#{{formname}}-newDlg').find('.modal-header').find('#{{formname}}-error').remove();
	            $('#{{formname}}-newDlg').find('.modal-header').append('<div id="{{formname}}-error" class="alert alert-danger"><strong>'+msg.statusText+'</strong></div>');
          }
      });
  });
  $('#{{formname}}-newDlg').on('keydown', function(e) {
      var key = e.keyCode || e.which;

      if (key == 13) {
          $('#{{formname}}-newDlg button[type="submit"]').trigger('click'); // submit form

          return false;
      }
  });
  </script>''')
   return template.substitute(locals())

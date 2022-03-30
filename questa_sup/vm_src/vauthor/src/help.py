import tempita

def get_help_message(formname, messagehead, messagebody):
    tempiltastring = '''\
      <div id="{{formname}}-helpDlg" class="modal fade" role="dialog">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header" align="left">
              <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
              <h4 class="modal-title">{{str(messagehead)}}</h4>
            </div>
            <div id={{formname}}-helpbody class="modal-body" align="left"><h5>''' + messagebody + '''\
            </h5></div>
          </div>
        </div>
      </div>
      <span class="help-link"><a href="javascript:void(0);" onclick='{{formname}}show_help()'>Learn more</a></span>
      <script>
        function {{formname}}show_help() {
              $("#{{formname}}-helpDlg").modal('show');
        }

      </script>
    '''
    template = tempita.HTMLTemplate(tempiltastring)
    return template.substitute(locals())

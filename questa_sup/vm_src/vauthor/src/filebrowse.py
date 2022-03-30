import tempita

def get_file_browse(formname, fieldname, default, accept):

    template = tempita.HTMLTemplate('''\
    <div class="input-group" style="margin-top: 10px; ">
         <input class="form-control paramRef" name="{{formname}}_{{fieldname}}" id="{{formname}}_{{fieldname}}"value="{{default}}" type="text">
         <input type="file" name="file" id="{{formname}}_{{fieldname}}upload" style="width:200px; display:none;" onchange="fillTextFile{{fieldname}}();"  accept="{{accept}}" />
         <span class="input-group-btn">
<input type="button" class="btn btn-browse btn-primary btn-file" value="Browse" onclick="$('#{{formname}}_{{fieldname}}upload').click();"/>
            </span>
    </div>
    <script>
             function fillTextFile{{fieldname}}() {
                var uploadFiles = document.getElementById("{{formname}}_{{fieldname}}upload").files;
                var txt = "";
                for (var i = 0; i < uploadFiles.length; i++) {
                    var file = uploadFiles[i];
                    if (txt != "") {
                        txt += " ";
                    }
                    txt += file.name;
                    
                }
                document.getElementById("{{formname}}_{{fieldname}}").value = txt;
            }
            function get{{formname}}{{fieldname}}Files() {
                return document.getElementById("{{formname}}_{{fieldname}}upload").files;
            }
    </script>''')
    return template.substitute(locals())
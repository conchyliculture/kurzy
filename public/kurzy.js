function show_liste(liste) {
    var logged_in = $('#logoutdiv').is(':visible');
    var tab = $('#list');
    var html = '<table>';
    html += '<tr>';
    if (logged_in) {
        html += '<th>Delete</th>';
    }
    html += '<th>Date</th>';
    html += '<th>Short URL</th>';
    html += '<th>Destination</th>';
    html += '<th>Count</th>';
    html += '</tr>';
    for (var i = 0; i < liste.length; i++) {
        var elem = liste[i];
        html += '<tr>';
        if (logged_in) {
            html += '<td>';
            html += '<a href="#" onclick="delete_short(\''+elem['short']+'\')">x</a>';
            html += '</td>';
        }
        html += '<td>';
        html += elem['timestamp'];
        html += '</td>';
        html += '<td>';
        html += '<a href="'+elem['url']+'">'+elem['short']+'</a>';
        html += '</td>';
        html += '<td>';
        html += '<a href="'+elem['url']+'">'+elem['url']+'</a>';
        html += '</td>';
        html += '<td>';
        html += elem['counter'];
        html += '</td>';
        html += '</tr>';
    }
    html += '</table>';
    tab.html(html);
}
function delete_short(s) {
    $.ajax({
        type: 'GET',
        url: '/d/'+s,
        dataType: "json",
        success: function (data, s) {
            Materialize.toast('Successfull deleted link', 4000);
            load_liste();
        },
        error: function(data, s) {
            Materialize.toast('Error deleting link', 4000);
            console.log(s);
            console.log(data.responseJSON);
        }
    });
}
function load_liste() {
    $.ajax({
        type: "GET",
        url: "/list",
        dataType: "json",
        success: function (data, s) {
            show_liste(data['list']);
        },
        error: function(data, s) {
            console.log('error');
            console.log(s);
            console.log(data.responseText);
        }
    });
}

function kurzy_add(e){
    e.preventDefault();
    var url = $('#urlfield').val();
    var surl = $('#shorturlfield').val();
    var privateurl = $('#privatefield').is(":checked");
    $.ajax({
        url: "/a",
        type: "POST",
        dataType: "json",
        data: {'url': url, 'shorturl': surl, 'privateurl': privateurl},
        success: function(res, textStatus) {
            Materialize.toast('Successfull added link', 4000);
            console.log(res);
            var link = document.location.origin+'/'+res['short'];
            $('#add_result').html('<div class="col s12">Successfully added short link <a href="'+link+'">'+link+'</a></div>');
        },
        error: function(res) {
            Materialize.toast('Error adding link', 4000);
            $('#add_result').html('<div class="col s12 aria-invalid invalid">Error adding short link :'+res.responseJSON.msg+'</div>');
            $("#shorturlfield").addClass("invalid");
            $("#shorturlfield").prop("aria-invalid", "true");
        }
    });
};

function kurzy_logout(e) {
    $.ajax({
        url: "/logout",
        type: "GET",
        success: function(data, textStatus) {
            load_liste();
            $('#logindiv').show();
            $('#logoutdiv').hide();
        },
        error: function(data) {
            console.log(data.responseJSON);
        }
    });
}

function kurzy_login(e) {
    e.preventDefault();
    var pwd = $('#password').val();
    $.ajax({
        url: "/login",
        type: "POST",
        dataType: "json",
        data: {'password': pwd},
        success: function(data, textStatus) {
            load_liste();
            $('#logindiv').hide();
            $('#logoutdiv').show();
            Materialize.toast('Login Successful!', 4000);
        },
        error: function(data) {
            Materialize.toast('Login Failed', 4000);
            console.log(data.responseText);
        }
    });
};

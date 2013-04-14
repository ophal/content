(function($) {

$(document).ready(function() {
  $('#content_edit_form #save_submit').click(function() {
    var content = {
      id: $('#content_edit_form #content_id').val(),
      title: $('#content_edit_form #content_title').val(),
      teaser: $('#content_edit_form #content_teaser').val(),
      body: $('#content_edit_form #content_body').val(),
    }

    /* Fetch auth token */
    $.ajax({
      type: 'POST',
      url: '/content/save',
      contentType: 'application/json; charset=utf-8',
      data: JSON.stringify(content),
      dataType: 'json',
      processData: false,
      success: function (data) {
        if (data.edited) {
          window.location = '/content/' + data.content_id;
        }
        else {
          if (data.error) {
            alert('Operation failed! Reason: ' + data.error);
          }
          else {
            alert('Operation failed!');
          }
        }
      },
      error: function() {
        alert('Operation error. Please try again later.');
      },
    });
  });
});

})(jQuery);
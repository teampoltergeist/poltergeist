$(function() {
  $("#datepicker").datepicker();

  $('#remove').click(function() {
    $('#remove_me').remove()
  })

  var increment = function(index, oldText) {
    return parseInt(oldText || 0) + 1;
  }

  $('#change_me')
    .change(function(event) {
      $('#changes').text($(this).val())
    })
    .bind('input', function(event) {
      $('#changes_on_input').text($(this).val())
    })
    .keydown(function(event) {
      $('#changes_on_keydown').text(increment)
      $('#value_on_keydown').text($(this).val())
    })
    .keyup(function(event) {
      $('#changes_on_keyup').text(increment)
      $('#value_on_keyup').text($(this).val())
    })
    .keypress(function() {
      $('#changes_on_keypress').text(increment)
    })
    .focus(function(event) {
      $('#changes_on_focus').text('Focus')
    })
    .blur(function() {
      $('#changes_on_blur').text('Blur')
    })

  $('#browser')
    .change(function(event) {
      $('#changes').text($(this).val())
      $('#target_on_select').text(event.target.nodeName)
    })
    .focus(function() {
      $('#changes_on_focus').text($(this).val())
    })
    .blur(function() {
      $('#changes_on_blur').text($(this).val())
    })

  $('#open-match')
    .click(function() {
      if (confirm('{T}ext \\w|th [reg.exp] (chara©+er$)?')) {
        $(this).attr('confirmed', 'true');
      }
    })

  $('#open-twice')
    .click(function() {
      if (confirm('Are you sure?')) {
        if (!confirm('Are you really sure?')) {
          $(this).attr('confirmed', 'false');
        }
      }
    })
})

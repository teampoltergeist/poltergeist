$(function() {
  $('#remove').click(function() {
    $('#remove_me').remove()
  })

  $('#change_me').change(function(event) {
    $('#changes').text($('#change_me').val())
  })
})

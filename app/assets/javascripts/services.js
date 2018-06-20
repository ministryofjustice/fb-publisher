
function attachEvents() {
  $( document ).on('ajax:success','.button_to', handleAjaxResponse)
}

function handleAjaxResponse(event, data) {
  var html = event.detail[event.detail.length-1].responseText
  var tr = $(event.target).closest('tr')

  tr.replaceWith(html)
}

$(document).ready( function() {
  attachEvents()
})

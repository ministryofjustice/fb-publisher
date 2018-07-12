
function attachEvents() {
  // general-purpose for all remote: true buttons - should probably
  // be more specific
  $( document ).on('ajax:success','.button_to', handleAjaxResponse)

  if( $('tr[data-refreshable]').size() > 0 ) {
    set_refresh_timer(5000);
  }
}

function set_refresh_timer(interval) {
  setTimeout( function() {
    refresh_all(interval)
  }, interval)
}

function refresh_all(refresh_again_interval) {
  $('tr[data-refreshable]').each( function(i, elem){
    console.log("elem = ");
    console.log(elem)
    $.ajax({
          url: $(elem).data('refreshable'),
          cache: false,
          success: function(html) {
              $(elem).replaceWith(html);
              set_refresh_timer(refresh_again_interval);
          }
      });
  } );
}

function handleAjaxResponse(event, data) {
  var html = event.detail[event.detail.length-1].responseText
  var tr = $(event.target).closest('tr')

  tr.replaceWith(html)
}

$(document).ready( function() {
  attachEvents()
})

window.LoadingIndicator = (function($) {
  // private
  function onSubmit(e) {
    var $form = $(e.target).parents('.cf-form');
    $form.addClass("cf-is-loading");
  }

  // public
  return {
    bind: function() {
      $(".cf-form .cf-submit").on('click', onSubmit);

      // remove loading flag for browsers with bfcaching
      window.onpageshow = function() { $(".cf-form").removeClass("cf-is-loading"); };
    }
  };
})($);
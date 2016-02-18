window.Dropdown = (function($) {
  // private
  function onOpen(e) {
    e.preventDefault(); // Prevent page jump
    var dropdownMenuId = $(this).attr('href');
    $(dropdownMenuId).addClass('active');
  }

  function onClose(e) {
    if (!$(e.target).parents('.cf-dropdown').length) {
      $('.cf-dropdown-menu').removeClass('active');
    }
  }

  // public
  return {
    bind: function() {
      $(".cf-dropdown-trigger").on('click', onOpen);
      $(":not(.cf-dropdown)").on('click', onClose);
    }
  };
})($);
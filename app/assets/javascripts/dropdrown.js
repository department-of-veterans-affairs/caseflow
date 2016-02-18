var CFDropdown = (function ($) {
    // private
    var onOpen = function (e) {
        e.preventDefault(); // Prevent page jump
        var dropdownMenu = $(this).attr('href');
        $(dropdownMenu).toggleItem();
    };

    var onClose = function (e) {
        if (!$(e.target).parents('.cf-dropdown').length) {
            $('.cf-dropdown-menu').closeItem();
        }
    };

    // public
    return {
        bind: function () {
            $(".cf-dropdown-trigger").on('click', onOpen);
            $(":not(.cf-dropdown)").on('click', onClose);
        }
    };
})($);
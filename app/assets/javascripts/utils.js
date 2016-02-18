var CFUtils = (function ($) {

    // public
    return {
        extendJQuery: function () {
            $.fn.extend({

                openItem: function () {
                    $(this).show(50, function () {
                        $(this).removeAttr('hidden')
                    });
                },
                toggleItem: function () {
                    $(this).toggle(50);
                },
                closeItem: function () {
                    $(this).hide(50, function () {
                        $(this).attr('hidden', 'true')
                    });
                }
            });
        }
    }
})($);
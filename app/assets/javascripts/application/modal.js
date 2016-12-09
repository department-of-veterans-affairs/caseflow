//= require jquery

window.Modal = (function($) {

  // function openModal(e) {
  //   e.preventDefault();
  //   var target = $(e.target).attr("href");
  //   $(target).addClass("active");
  // }

  // function closeModal(e) {
  //   e.stopPropagation();
  //   e.stopImmediatePropagation();

  //   if ($(e.target).hasClass("cf-modal") || $(e.target).hasClass("cf-action-closemodal")) {
  //     e.preventDefault();
  //     $(e.currentTarget).removeClass("active");
  //   }
  // }

  // function onKeyDown(e) {
  //   var escKey = (e.which === 27);

  //   if (escKey) {
  //     $('.cf-modal').trigger('click');
  //   }
  // }

  // // public
  // return {
  //   bind: function() {
  //     $('.cf-action-openmodal').on('click', openModal);
  //     $('.cf-modal').on('click', closeModal);
  //     $(window).on('keydown', onKeyDown);
  //   }
  // };
})($);
//= require webpack-loader

/* globals Clipboard */

// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require clipboard
//= require jquery
//= require jquery_ujs
//= require_tree ./application

$(function() {
  window.Dropdown.bind();
  window.Modal.bind();
  window.LoadingIndicator.bind();
});

/* Copies appeals ID to clipboard */
$(function () {
  "use strict";
  new Clipboard('[data-clipboard-text]');
});

/* Reusable 'refresh' pattern */
$(function() {
  $('.cf-action-refresh').on('click', function() {
    location.reload(); return false;
  });
});

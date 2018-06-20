/* globals */

//= require webpack-loader
//= require jquery
//= require ./dropdown.js

window.onload = function () {
  // Leave the Dropdown jQuery on React pages since the header
  // is rendered from erb files.
  $(function() {
    window.Dropdown.bind();
  });

  /* Reusable 'refresh' pattern */
  $(function() {
    $('.cf-action-refresh').on('click', function() {
      location.reload(); return false;
    });
  });
};

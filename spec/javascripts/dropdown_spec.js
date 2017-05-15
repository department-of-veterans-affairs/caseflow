//= require jquery
//= require application/dropdown

describe("Dropdown", function() {
  var $testContainer;

  beforeEach(function() {
    $testContainer = $("#konacha");
  });

  context(".bind", function() {
    it("adds active class to dropdown when clicked", function() {
      var $dropdown = $('<a class="cf-dropdown-trigger" href="#menu">Trigger</a><ul id="menu"><li>Menu Item</li>/ul>');
      $dropdown.appendTo($testContainer);

      Dropdown.bind();
      expect($('#menu').hasClass('active')).to.eq(false)
      $dropdown.click();
      expect($('#menu').hasClass('active')).to.eq(true)
    });
  });
});
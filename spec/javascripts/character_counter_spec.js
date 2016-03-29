//= require jquery
//= require character_counter

describe("CharacterCounter", function() {
  var $testContainer, $field;

  beforeEach(function() {
    $testContainer = $("#konacha");
  });

  it("shows character counter when value", function() {
    $field = $("<div id='test-question'><input type='text' maxlength='15'></input></div>");
    $field.appendTo($testContainer);

    new CharacterCounter($field);

    $field.find("input").val("1234").trigger("input");
    expect($field.find('.cf-characters-left').html()).to.contain('11 characters remaining');
  });

  it("shows empty character counter when no value", function() {
    $field = $("<div id='test-question'><input type='text' maxlength='15'></input></div>");
    $field.appendTo($testContainer);

    new CharacterCounter($field);

    $field.find("input").val("1234").trigger("input");
    expect($field.find('.cf-characters-left').html()).to.contain('');
  });
});
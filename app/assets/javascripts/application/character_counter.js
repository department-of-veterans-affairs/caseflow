window.CharacterCounter = (function($) {
  return function($field) {
    var $charactersLeft, $inputField;

    function onInput() {
      var maxLength = $inputField.attr('maxlength');
      var length = $inputField.val().length;

      var message = maxLength - length + " characters remaining";
      if (length <= 0) { message = ""; }

      $charactersLeft.html(message);
    }

    $inputField = $field.find("input, textarea");
    $charactersLeft = $("<div class='cf-characters-left'></div>");
    $field.append($charactersLeft);

    $inputField.on('input change keyup paste mouseup', onInput);
  };
})($);
//= require jquery

window.Modal = (function($) {
  var state = {};
  var questionNames = ["cancellationReason", "otherReason", "email"];
  var errorMessages = {
    "cancellationReason": "Make sure you've selected an option below.",
    "otherReason": "Make sure you’ve filled out the comment box below.",
    "email":  "Make sure you’ve entered a valid email address below."
  };
  var interactiveQuestions = ["otherReason"];
  var emailPattern = /^[A-Z0-9._%+-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i;

  function init() {
    initState();

    new window.CharacterCounter($question("otherReason"));

    $("#cancellation-form input, #cancellation-form textarea").on("change keyup paste mouseup", function() {
      return reevalulate();
    });

    $("#cancellation-form").on("submit", function() {
      return onSubmit();
    });
  }

  function reevalulate() {
    fetchState();
    processState();
    render();
  }

  function $question(questionName) {
    return $("#question" + questionName);
  }

  function questionValue(questionName) {
    var value = $question(questionName).find("input[type='text'], textarea, input[type='radio']:checked").val();
    if (value !== undefined) { return value.trim(); }
  }

  function fetchState() {
    questionNames.forEach(function(questionName) {
      state[questionName].value = questionValue(questionName);
    });
  }

  function processState() {
    questionNames.forEach(function(questionName) {
      validateQuestion(questionName, false);
    });
    state["otherReason"].show = false;
    if (state["cancellationReason"].value === "Other"){
      state["otherReason"].show = true;
    }

  }

  function render() {
    questionNames.forEach(function(questionName) {
      var error = state[questionName].error;
      var $q = $question(questionName);
      $q.find(".usa-input-error-message").html(error);
      $q.toggleClass("usa-input-error", !!error);
    });
    interactiveQuestions.forEach(function(questionName) {
        toggleQuestion(questionName);
    });
  }

  function toggleQuestion(questionName) {
      var $q = $question(questionName);
      var hideQuestion = !state[questionName].show;

      $q.toggleClass('hidden-field', hideQuestion);
  }

  function onSubmit() {
    var invalidQuestionNames;

    fetchState();
    invalidQuestionNames = getInvalidQuestionNames();
    render();

    if (invalidQuestionNames.length > 0) {
      // remove loading style
      $(".cf-form").removeClass("cf-is-loading");
    }
    return invalidQuestionNames.length === 0;
  }

  function getInvalidQuestionNames() {
    return questionNames.filter(function(questionName){
      return !validateQuestion(questionName, true);
    });
  }

  function validateQuestion(questionName, showError) {
    var questionState = state[questionName];
    var isValid = !!questionState.value || !questionState.show;

    if (isValid && questionName === "email") {
      isValid = emailPattern.test(questionState.value);
    }

    if(isValid) {
      questionState.error = null;
    }
    else if(showError) {
      questionState.error = errorMessages[questionName];
    }

    return isValid;
  }

  function initState() {
    questionNames.forEach(function(questionName) {
      state[questionName] = { show: true };
    });
    interactiveQuestions.forEach(function(questionName) {
        state[questionName] = { show: false };
        toggleQuestion(questionName);
    });
    $question("cancellationReason").find("input[type=radio]").prop("checked", false);
    questionNames.forEach(function(questionName) {
      $question(questionName).find(".question-label").append(
        $("<span class='cf-required'> Required</span>")
      );
    });
  }

  function openModal(e) {
    e.preventDefault();
    var target = $(e.target).attr("href");
    $(target).addClass("active");
  }

  function closeModal(e) {
    e.stopPropagation();
    e.stopImmediatePropagation();

    if ($(e.target).hasClass("cf-modal") || $(e.target).hasClass("cf-action-closemodal")) {
      e.preventDefault();
      $(e.currentTarget).removeClass("active");
    }
  }

  function onKeyDown(e) {
    var escKey = (e.which === 27);

    if (escKey) {
      $('.cf-modal').trigger('click');
    }
  }

  // public
  return {
    bind: function() {
      $('.cf-action-openmodal').on('click', openModal);
      $('.cf-modal').on('click', closeModal);
      $(window).on('keydown', onKeyDown);

      init();
    }
  };
})($);

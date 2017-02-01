//= require jquery

(function(){
  function $question(questionNumber) {
    return $("#question" + questionNumber);
  }

  function questionValue(questionNumber) {
    var value = $question(questionNumber).find("input[type='text'], textarea, input[type='radio']:checked").val();
    // value is returned as undefined for hidden fields
    // trim() blows up when it is called on undefined
    if (value === undefined) { return; }
    return value.trim();
  }

  var DEFAULT_RADIO_ERROR_MESSAGE = "Oops! Looks like you missed one! Please select one of these options.";


  window.Form8 =  {
    interactiveQuestions: [
      "5A", "5B",
      "6A", "6B",
      "7A", "7B",
      "8A2", "8A3", "8B1", "8B2", "8C",
      "9A", "9B",
      "10A", "10B1", "10B2", "10C",
      "11A", "11B",
      "132",
      "17B2"
    ],

    requiredQuestions: {
      "2":   { message: "" },
      "3":   { message: "Please enter the veteran's full name." },
      "5B":  { message: "Please enter the date of notification." },
      "6B":  { message: "Please enter the date of notification." },
      "7B":  { message: "Please enter the date of notification." },
      "8A1": { message: "Please enter the representative name." },
      "8A2": { message: DEFAULT_RADIO_ERROR_MESSAGE },
      "8A3": { message: "" },
      "8B2": { message: "Please provide the location." },
      "8C":  { message: "" },
      "9A":  { message: DEFAULT_RADIO_ERROR_MESSAGE },
      "9B":  { message: DEFAULT_RADIO_ERROR_MESSAGE },
      "10A": { message: DEFAULT_RADIO_ERROR_MESSAGE },
      "10B2": { message: DEFAULT_RADIO_ERROR_MESSAGE },
      "11A": { message: DEFAULT_RADIO_ERROR_MESSAGE },
      "11B": { message: DEFAULT_RADIO_ERROR_MESSAGE },
      "12A": { message: "Please enter the date of the statement of the case." },
      "12B": { message: DEFAULT_RADIO_ERROR_MESSAGE },
      "15":  { message: "" },
      "16":  { message: "" },
      "17A": { message: "Please enter the name of the Certifying Official (usually your name)." },
      "17B1": { message: "Please enter the title of the Certifying Official (e.g. Decision Review Officer)." },
      "17B2": { message: "Please enter the title of the Certifying Official (e.g. Decision Review Officer)." },
      "17C": { message: "" }
    },

    getRequiredQuestions: function() {
      return Object.keys(this.requiredQuestions);
    },

    getWatchedQuestions: function() {
      if(this.watchedQuestions) { return this.watchedQuestions; }

      this.watchedQuestions = $.unique(this.interactiveQuestions.concat(this.getRequiredQuestions()));
      return this.watchedQuestions;
    },

    init: function(){
      var self = this;
      window.DateField.init();
      window.autoresize.init();

      this.initState();
      this.reevalulate();


      ["5A", "6A", "7A", "14"].forEach(function(questionNumber) {
        new window.CharacterCounter($question(questionNumber));
      });

      $("#form8 input, #form8 textarea").on("change keyup paste mouseup", function() {
        return self.reevalulate();
      });

      $("#form8").on("submit", function() {
        return self.onSubmit();
      });

      this.getRequiredQuestions().forEach(function(questionNumber) {
        $question(questionNumber).find(".question-label").append(
          $("<span class='cf-required'> (Required)</span>")
        );
      });
    },

    initState: function() {
      this.state = {};
      var state = this.state;

      this.getWatchedQuestions().forEach(function(questionNumber) {
        state["question" + questionNumber] = { show: true };
      });
    },

    fetchState: function() {
      var state = this.state;

      this.getWatchedQuestions().forEach(function(questionNumber) {
        state["question" + questionNumber].value = questionValue(questionNumber);
      });

      state.question13other = ($("#question13 #form8_record_other:checked").length === 1);
    },

    processState: function() {
      var state = this.state;
      var self = this;

      state.question5B.show = !!state.question5A.value;
      state.question6B.show = !!state.question6A.value;
      state.question7B.show = !!state.question7A.value;

      ["8A3", "8C", "9A", "9B"].forEach(function(questionNumber) {
        state["question" + questionNumber].show = false;
      });

      state.question8B1.show = true;

      switch (state.question8A2.value) {
      case "Agent":
        state.question8C.show = true;
        break;
      case "Organization":
        state.question9A.show = true;
        state.question9B.show = (state.question9A.value === "No");
        break;
      case "Other":
        state.question8A3.show = true;
        break;
      case "None":
        state.question8B1.show = false;
        state.question8B2.show = false;
        break;
      }

      var poaInAnotherFile = state.question8B1.value === "Certification that valid POA is in another VA file";
      var hasRepresentative;
      if (state.question8A2.value && state.question8A2.value !== "None") {
        hasRepresentative = true;
      } else {
        hasRepresentative = false;
      }

      state.question8B2.show = poaInAnotherFile && hasRepresentative;
      state.question10B1.show = state.question10C.show = (state.question10A.value === "Yes");
      state.question10B2.show = (state.question10B1.value === "Yes");
      state.question11B.show = (state.question11A.value === "Yes");
      state.question132.show = state.question13other;
      state.question17B2.show = (state.question17B1.value === "Other");


      this.getRequiredQuestions().forEach(function(questionNumber) {
        self.validateRequiredQuestion(questionNumber, false);
      });

      return state;
    },

    validateRequiredQuestion: function(questionNumber, showError) {
      var questionState = this.state["question" + questionNumber];
      var isValid = !!questionState.value || !questionState.show;

      if(isValid) {
        questionState.error = null;
      }
      else if(showError) {
        questionState.error = this.requiredQuestions[questionNumber];
      }

      return isValid;
    },

    getInvalidQuestionNumbers: function() {
      var self = this;

      var invalidQuestionNumbers = this.getRequiredQuestions().filter(function(questionNumber){
        return !self.validateRequiredQuestion(questionNumber, true);
      });

      return invalidQuestionNumbers;
    },

    render: function() {
      var self = this;

      this.getRequiredQuestions().forEach(function(questionNumber) {
        var error = self.state["question" + questionNumber].error;
        var errorMessage = error ? error.message : "";
        var $q = $question(questionNumber);

        $q.find(".usa-input-error-message").html(errorMessage);
        $q.toggleClass("usa-input-error", !!error);
      });

      this.interactiveQuestions.forEach(function(questionNumber) {
        self.toggleQuestion(questionNumber);
      });
    },

    reevalulate: function() {
      this.fetchState();
      this.processState();
      this.render();
    },

    onSubmit: function() {
      this.fetchState();
      var invalidQuestionNumbers = this.getInvalidQuestionNumbers();
      this.render();

      if (invalidQuestionNumbers.length > 0) {
        // invalid, focus first invalid field
        $question(invalidQuestionNumbers[0]).find("input, textarea, select").first().focus();

        // remove loading style
        $(".cf-form").removeClass("cf-is-loading");
      }

      return invalidQuestionNumbers.length === 0;
    },

    toggleQuestion: function(questionNumber) {
      var $q = $question(questionNumber);
      var hideQuestion = !this.state["question" + questionNumber].show;

      $q.toggleClass('hidden-field', hideQuestion);
      $q.find('input, textarea').prop('disabled', hideQuestion);
    }
  };
})();



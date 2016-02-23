//= require jquery

(function(){
  function $question(questionNumber) {
    return $("#question" + questionNumber);
  }

  function questionValue(questionNumber) {
    return $question(questionNumber).find("input[type='text'], textarea, input[type='radio']:checked").val();
  }

  var DEFAULT_RADIO_ERROR_MESSAGE = "Oops! Looks like you missed one! Please select one of these options.";


  window.Form8 =  {
    interactiveQuestions: [
      "5A", "5B",
      "6A", "6B",
      "7A", "7B",
      "8A2", "8A3", "8B1", "8B2", "8C",
      "9A", "9B",
      "10A", "10B", "10C",
      "11A", "11B",
      "132"
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
      "11A": { message: DEFAULT_RADIO_ERROR_MESSAGE },
      "11B": { message: DEFAULT_RADIO_ERROR_MESSAGE },
      "12A": { message: "Please enter the date of the statement of the case." },
      "12B": { message: DEFAULT_RADIO_ERROR_MESSAGE },
      "15":  { message: "" },
      "16":  { message: "" },
      "17A": { message: "Please enter the name of the Certifying Official (usually your name)." },
      "17B": { message: "Please enter the title of the Certifying Official (e.g. Decision Review Officer)." },
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

      this.initState();
      this.reevalulate();

      $("#form8 input, #form8 textarea").on("change keyup paste mouseup", function() {
        return self.reevalulate();
      });

      $("#form8").on("submit", function() {
        return self.onSubmit();
      });

      this.getRequiredQuestions().forEach(function(questionNumber) {
        $question(questionNumber).find(".question-label").addClass("required");
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
      }

      state.question8B2.show = (state.question8B1.value === "Certification that valid POA is in another VA file");
      state.question10B.show = state.question10C.show = (state.question10A.value === "Yes");
      state.question11B.show = (state.question11A.value === "Yes");
      state.question132.show = state.question13other;


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

    validateSubmit: function() {
      var self = this;

      return this.getRequiredQuestions().reduce(function(result, questionNumber) {
        return self.validateRequiredQuestion(questionNumber, true) && result;
      }, true);
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
      var result = this.validateSubmit();
      this.render();

      return result;
    },

    toggleQuestion: function(questionNumber) {
      var $q = $question(questionNumber);

      if(this.state["question" + questionNumber].show) {
        $q.removeClass('hidden-field');
      } else {
        $q.addClass('hidden-field');
      }
    }
  };
})();



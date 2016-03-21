//= require jquery
//= require rxjs

(function(){
  function $question(questionNumber) {
    return $("#question" + questionNumber);
  }

  function questionValue(questionNumber) {
    return $question(questionNumber).find("input[type='text'], textarea, input[type='radio']:checked").val();
  }

  function valueFromEvent(event) {
    return event.target.value;
  }

  function initQuestionStream(questionNumber) {
    return Rx.Observable.fromEvent($question(questionNumber), 'input click')
      .map(valueFromEvent)
      .startWith(questionValue(questionNumber));
  }

  var DEFAULT_RADIO_ERROR_MESSAGE = "Oops! Looks like you missed one! Please select one of these options.";

  window.Form8 = {
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

    init: function(){
      window.DateField.init();

      this.getRequiredQuestions().forEach(function(questionNumber) {
        $question(questionNumber).find(".question-label").addClass("required");
      });

      this.initStreams();
    },

    initStreams: function() {
      var formStream = this.initFormStream()
        .map(this.processShowing)
        .map(this.processValidation.bind(this));

      var submitStream = Rx.Observable.fromEvent($("#form8"), "submit");

      var formShowErrorsStream = formStream
        .sample(submitStream)
        .combineLatest(submitStream, this.processFormSubmit.bind(this))
        .flatMap(function() { return Rx.Observable.from([true, false]); })
        .startWith(false);

      formStream = formStream
        .scan(function (old, current) { return { previous: old.current, current: current }; }, {})
        .combineLatest(formShowErrorsStream, this.processErrorMessages.bind(this));

      formStream.subscribe(this.renderForm.bind(this));
    },

    getRequiredQuestions: function() {
      return Object.keys(this.requiredQuestions);
    },

    getWatchedQuestions: function() {
      if(this.watchedQuestions) { return this.watchedQuestions; }

      this.watchedQuestions = $.unique(this.interactiveQuestions.concat(this.getRequiredQuestions()));
      return this.watchedQuestions;
    },

    isRequiredQuestionValid: function(value) {
      return !!value;
    },

    initFormStream: function() {
      var formStream = Rx.Observable.return(null);

      // create a stream of objects representing the state of each question in the form
      this.getWatchedQuestions().forEach(function(questionNumber) {
        formStream = formStream.combineLatest(
          initQuestionStream(questionNumber),
          function(form, questionValue) {
            form = $.extend({}, form) || {};

            form[questionNumber] = {
              value: questionValue,
              show: true,
              valid: true
            };
            return form;
          }
        );
      });

      // exception to find the checked state of the other checkbox in question 13
      var otherCheckboxStream = Rx.Observable.fromEvent($question("13"), 'input click')
        .map(function() { return ($("#question13 #form8_record_other:checked").length === 1); })
        .startWith($("#question13 #form8_record_other:checked").length === 1);

      formStream = formStream.combineLatest(otherCheckboxStream, function(form, otherValue) {
        form["13other"] = otherValue;
        return form;
      });

      return formStream;
    },

    processValidation: function(form) {
      var self = this;

      this.getRequiredQuestions().forEach(function(questionNumber) {
        form[questionNumber].valid = form[questionNumber].show ? self.isRequiredQuestionValid(form[questionNumber].value) : true;
      });

      return form;
    },

    processShowing: function(form) {
      form["5B"].show = !!form["5A"].value;
      form["6B"].show = !!form["6A"].value;
      form["7B"].show = !!form["7A"].value;

      ["8A3", "8C", "9A", "9B"].forEach(function(questionNumber) {
        form[questionNumber].show = false;
      });

      switch (form["8A2"].value) {
      case "Agent":
        form["8C"].show = true;
        break;
      case "Organization":
        form["9A"].show = true;
        form["9B"].show = (form["9A"].value === "No");
        break;
      case "Other":
        form["8A3"].show = true;
      }

      form["8B2"].show = (form["8B1"].value === "Certification that valid POA is in another VA file");
      form["10B"].show = form["10C"].show = (form["10A"].value === "Yes");
      form["11B"].show = (form["11A"].value === "Yes");
      form["132"].show = form["13other"];

      return form;
    },

    processErrorMessages: function(forms, showErrorMessages) {
      var self = this;
      var previousForm = forms.previous,
          form = forms.current;

      this.getRequiredQuestions().forEach(function(questionNumber) {
        if(form[questionNumber].valid) {
          form[questionNumber].error = null;
        }
        else if(showErrorMessages) {
          form[questionNumber].error = self.requiredQuestions[questionNumber];
        }
        else if(previousForm && previousForm[questionNumber].error) {
          form[questionNumber].error = previousForm[questionNumber].error;
        }
      });

      return form;
    },

    processFormSubmit: function(form, submitEvent) {
      var invalidQuestions = this.getRequiredQuestions().filter(function(questionNumber) {
        return !form[questionNumber].valid;
      });

      if(invalidQuestions.length > 0) {
        // focus first invalid field
        $question(invalidQuestions[0]).find("input, textarea, select").first().focus();

        $(".cf-form").removeClass("cf-is-loading");

        // cancel submission if there are any invalid questions
        submitEvent.preventDefault();
      }
    },

    renderForm: function(form) {
      this.getWatchedQuestions().forEach(function(questionNumber) {
        var $q = $question(questionNumber);

        var hideQuestion = !form[questionNumber].show;
        $q.toggleClass('hidden-field', hideQuestion);
        $q.find('input, textarea').prop('disabled', hideQuestion);

        var error = form[questionNumber].error;
        var errorMessage = error ? error.message : "";
        $q.find(".usa-input-error-message").html(errorMessage);
        $q.toggleClass("usa-input-error", !!error);
      });
    }
  };
})();



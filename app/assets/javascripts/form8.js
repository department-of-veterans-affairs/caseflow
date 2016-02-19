(function(){
  function questionValue(questionNumber) {
    return $("#question" + questionNumber + " input[type='text'], " +
             "#question" + questionNumber + " textarea, " +
             "#question" + questionNumber + " input[type='radio']:checked").val();
  }

  function $question(questionNumber) {
    return $("#question" + questionNumber);
  }

  window.Form8 =  {
    watchedQuestions: [
      "5A", "5B",
      "6A", "6B",
      "7A", "7B",
      "8A2", "8A3", "8B1", "8B2", "8C",
      "9A", "9B",
      "10A", "10B", "10C"
    ],

    init: function(){
      var self = this;
      window.DateField.init();

      this.initState();
      this.refresh();

      $("#form8 input, #form8 textarea").on("change keyup paste mouseup", function() {
        self.refresh();
      });
    },

    initState: function() {
      this.state = {};
      var state = this.state;

      this.watchedQuestions.forEach(function(questionNumber) {
        state["question" + questionNumber] = { show: true };
      });
    },

    fetchState: function() {
      var state = this.state;

      this.watchedQuestions.forEach(function(questionNumber) {
        state["question" + questionNumber].value = questionValue(questionNumber);
      });
    },

    processState: function() {
      var state = this.state;

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

      return state;
    },

    render: function() {
      var self = this;

      this.watchedQuestions.forEach(function(questionNumber) {
        self.toggleQuestion(questionNumber);
      });
    },

    refresh: function() {
      this.fetchState();
      this.processState();
      this.render();
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



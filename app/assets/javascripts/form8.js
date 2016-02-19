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
    state: {
      question5A: {},
      question5B: { show: false },
      question6A: {},
      question6B: { show: false },
      question7A: {},
      question7B: { show: false },
      question8A2: {},
      question8A3: { show: false },
      question8B1: {},
      question8B2: { show: false },
      question8C: { show: false },
      question9A: { show: false },
      question9B: { show: false }
    },

    init: function(){
      var self = this;
      window.DateField.init();

      this.refresh();
      $("#form8 input, #form8 textarea").on("change keyup paste mouseup", function() {
        self.refresh();
      });
    },

    fetchState: function() {
      this.state.question5A.value = questionValue("5A");
      this.state.question6A.value = questionValue("6A");
      this.state.question7A.value = questionValue("7A");
      this.state.question8A2.value = questionValue("8A2");
      this.state.question8B1.value = questionValue("8B1");
      this.state.question9A.value = questionValue("9A");
    },

    processState: function() {
      this.state.question5B.show = !!this.state.question5A.value;
      this.state.question6B.show = !!this.state.question6A.value;
      this.state.question7B.show = !!this.state.question7A.value;

      this.state.question8A3.show =
      this.state.question8C.show =
      this.state.question9A.show =
      this.state.question9B.show = false;

      switch (this.state.question8A2.value) {
      case "Agent":
        this.state.question8C.show = true;
        break;
      case "Organization":
        this.state.question9A.show = true;
        this.state.question9B.show = (this.state.question9A.value === "No");
        break;
      case "Other":
        this.state.question8A3.show = true;
      }

      this.state.question8B2.show = (this.state.question8B1.value === "Certification that valid POA is in another VA file");
    },

    render: function() {
      this.toggleQuestion("5B");
      this.toggleQuestion("6B");
      this.toggleQuestion("7B");
      this.toggleQuestion("8A3");
      this.toggleQuestion("8C");
      this.toggleQuestion("9A");
      this.toggleQuestion("9B");
      this.toggleQuestion("8B2");
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



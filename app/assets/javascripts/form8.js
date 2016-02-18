(function(){
  function $questionValue(questionNumber) {
    return $("#question" + questionNumber + " input, " +
             "#question" + questionNumber + " textarea").val();
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
      question7B: { show: false }
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
      this.state.question5A.value = $questionValue("5A");
      this.state.question6A.value = $questionValue("6A");
      this.state.question7A.value = $questionValue("7A");
    },


    processState: function() {
      this.state.question5B.show = !!this.state.question5A.value;
      this.state.question6B.show = !!this.state.question6A.value;
      this.state.question7B.show = !!this.state.question7A.value;
    },

    render: function() {
      this.toggleQuestion("5B");
      this.toggleQuestion("6B");
      this.toggleQuestion("7B");
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



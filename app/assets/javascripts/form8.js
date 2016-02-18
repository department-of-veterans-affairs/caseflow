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
      question5B: { show: false }
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
    },

    processState: function() {
      this.state.question5B.show = !!this.state.question5A.value;
    },

    render: function() {
      if(this.state.question5B.show) {
        $question("5B").removeClass('hidden-field');
      } else {
        $question("5B").addClass('hidden-field');
      }
    },

    refresh: function() {
      this.fetchState();
      this.processState();
      this.render();
    },
  };
})();



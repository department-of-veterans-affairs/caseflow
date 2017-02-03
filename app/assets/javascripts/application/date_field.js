//= require jquery
//= require jquery.maskedinput

(function(){
  function zeroPadLeft(number) {
    var length = 2,
        paddedNumber = number.toString();

    for(var i=0; i<length; i++) {
      paddedNumber = '0' + paddedNumber;
    }

    return paddedNumber.substr(paddedNumber.length - length);
  }

  window.DateField =  {
    init: function(){
      var self = this;

      $('input[type=date]').attr('type','text').each(function(index, input){
        // reformat value from ISO to masked pattern
        var $input = $(input);
        $input.val(self.formatDate($input.val()));
      }).mask("99/99/9999",{ placeholder: "mm/dd/yyyy" });
    },

    formatDate: function(dashDateStr) {
      var date = new Date(Date.parse(dashDateStr));
      var dateParts = [];

      if(date.toString() === "Invalid Date") { return ""; }

      dateParts[0] = zeroPadLeft(date.getUTCMonth()+1);
      dateParts[1] = zeroPadLeft(date.getUTCDate());
      dateParts[2] = date.getFullYear();

      return dateParts.join('/');
    },

    isValidDate: function(questionNumber){
      var enteredDate = Date.parse($('#question'+questionNumber).children('input').val());
      var startDate = Date.parse('1850-01-01');
      var endDate = new Date();
      return ((startDate <= enteredDate) && (enteredDate <= endDate));
    }
  };
})();

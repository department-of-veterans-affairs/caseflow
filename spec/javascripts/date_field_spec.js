//= require jquery
//= require application/date_field

function typeKeys($el, str) {
  for (var i = 0; i < str.length; i++) {
    var e = $.Event("keypress");
    e.which = str[i].charCodeAt(0);
    $el.trigger(e);
  }
}

describe("DateField", function() {
  var $testContainer;

  beforeEach(function() {
    $testContainer = $("#konacha");
  });

  context(".init", function() {
    it("converts date fields to text fields with formatted value", function() {
      var $dateField = $("<input type='date' value='2015-09-06'></input>")
      $dateField.appendTo($testContainer);

      DateField.init();

      expect($dateField.attr('type')).to.eq('text');
      expect($dateField.val()).to.eq('09/06/2015');
    });

    it("applies mask to date fields", function() {
      var $dateField = $("<input type='date'></input>")
      $dateField.appendTo($testContainer);
      DateField.init();

      typeKeys($dateField, "9");
      expect($dateField.val()).to.eq("9m/dd/yyyy");

      $dateField.blur();
      expect($dateField.val()).to.be.empty;

      typeKeys($dateField, "09061987");
      $dateField.blur();
      expect($dateField.val()).to.eq("09/06/1987");
    });
  });

  context(".formatDate", function() {
    it("formats date in yyyy-mm-dd to mm/dd/yyyy", function() {
      expect(DateField.formatDate("2016-03-01")).to.eq("03/01/2016");
    });

    it("returns empty string if malformated", function() {
      expect(DateField.formatDate("2016-03-abcd")).to.eq("");
    });
  });
  context(".isValidDate", function() {
    it("returns false for date before 1850-01-01", function() {
      expect(DateField.isValidDate("1849-12-31")).to.be.false;
    });

    it("returns true for date after 1850-01-01 and before today", function() {
      expect(DateField.isValidDate("1850-01-01")).to.be.true;
      expect(DateField.isValidDate(Date.today)).to.be.true;
    });
    it("returns false for future date", function() {
      expect(DateField.isValidDate(Date.today+1)).to.be.false;
    });

  });
});

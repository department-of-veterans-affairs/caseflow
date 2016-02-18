//= require form8

describe("Form8", function() {
  context(".processState", function() {
    context("when question 5A is empty", function() {
      it("hides question 5B", function() {
        Form8.state.question5A.value =  ""; 
        Form8.processState();

        expect(Form8.state.question5B.show).to.be.false;
      });
    });

    context("when question 5A has a value", function() {
      it("shows question 5B", function() {
        Form8.state.question5A.value =  "so much value"; 
        Form8.processState();

        expect(Form8.state.question5B.show).to.be.true;
      });
    });
  });
});
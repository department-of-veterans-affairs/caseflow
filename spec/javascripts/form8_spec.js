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


    context("when question 6A is empty", function() {
      it("hides question 6B", function() {
        Form8.state.question6A.value =  "";
        Form8.processState();

        expect(Form8.state.question6B.show).to.be.false;
      });
    });

    context("when question 6A has a value", function() {
      it("shows question 6B", function() {
        Form8.state.question6A.value =  "so much value";
        Form8.processState();

        expect(Form8.state.question6B.show).to.be.true;
      });
    });


    context("when question 7A is empty", function() {
      it("hides question 7B", function() {
        Form8.state.question7A.value =  "";
        Form8.processState();

        expect(Form8.state.question7B.show).to.be.false;
      });
    });

    context("when question 7A has a value", function() {
      it("shows question 7B", function() {
        Form8.state.question7A.value =  "so much value";
        Form8.processState();

        expect(Form8.state.question7B.show).to.be.true;
      });
    });

    context("when question 8A2 is Other", function() {
      it("shows 'Specify Other' (question 8A3)", function() {
        Form8.state.question8A2.value =  "Other";
        Form8.processState();
        expect(Form8.state.question8A3.show).to.be.true;
      })
    })
  });
});
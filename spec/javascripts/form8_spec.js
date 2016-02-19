//= require form8

describe("Form8", function() {
  beforeEach(function() {
    Form8.initState();
  });

  context(".processState", function() {
    context("when question 5A", function() {
      context("is empty", function() {
        it("hides question 5B", function() {
          Form8.state.question5A.value =  "";
          Form8.processState();

          expect(Form8.state.question5B.show).to.be.false;
        });
      });

      context("has a value", function() {
        it("shows question 5B", function() {
          Form8.state.question5A.value =  "so much value";
          Form8.processState();

          expect(Form8.state.question5B.show).to.be.true;
        });
      });
    });

    context("when question 6A", function() {
      context("is empty", function() {
        it("hides question 6B", function() {
          Form8.state.question6A.value =  "";
          Form8.processState();

          expect(Form8.state.question6B.show).to.be.false;
        });
      });

      context("has a value", function() {
        it("shows question 6B", function() {
          Form8.state.question6A.value =  "so much value";
          Form8.processState();

          expect(Form8.state.question6B.show).to.be.true;
        });
      });
    });

    context("when question 7A", function() {
      context("is empty", function() {
        it("hides question 7B", function() {
          Form8.state.question7A.value =  "";
          Form8.processState();

          expect(Form8.state.question7B.show).to.be.false;
        });
      });


      context("has a value", function() {
        it("shows question 7B", function() {
          Form8.state.question7A.value =  "so much value";
          Form8.processState();

          expect(Form8.state.question7B.show).to.be.true;
        });
      });
    });

    it("hides 'Specify Other', 8C, 9A, and 9B", function() {
      Form8.state.question8A3.show =
      Form8.state.question9A.show =
      Form8.state.question9B.show =
      Form8.state.question8C.show = true;

      Form8.state.question8A2.value =  "Attorney";
      Form8.processState();

      expect(Form8.state.question8A3.show).to.be.false;
      expect(Form8.state.question8C.show).to.be.false;
      expect(Form8.state.question9A.show).to.be.false;
      expect(Form8.state.question9B.show).to.be.false;
    });

    context("when question 8A2", function() {
      context("is Agent", function() {
        it("shows 8C", function() {
          Form8.state.question8A2.value =  "Agent";
          Form8.processState();
          expect(Form8.state.question8C.show).to.be.true;
        });
      });

      context("is Organization", function() {
        beforeEach(function() {
          Form8.state.question8A2.value =  "Organization";
          Form8.processState();
        });

        it("shows 9A", function() {
          Form8.state.question9B.show = true;
          Form8.state.question9A.value =  "Yes";
          Form8.processState();
          expect(Form8.state.question9B.show).to.be.false;
        });

        context("when 9A is No", function() {
          it("shows 9B", function() {
            Form8.state.question9B.show = false;
            Form8.state.question9A.value =  "No";
            Form8.processState();
            expect(Form8.state.question9B.show).to.be.true;
          });
        });
      });

      context("is Other", function() {
        it("shows 8A3", function() {
          Form8.state.question8A2.value =  "Other";
          Form8.processState();
          expect(Form8.state.question8A3.show).to.be.true;
        });
      });
    });

    context("when question 8B1", function(){
      context("is 'Certification that valid POA is in another VA file'", function() {
        it("shows 8B2", function() {
          Form8.state.question8B1.value =  "Certification that valid POA is in another VA file";
          Form8.processState();
          expect(Form8.state.question8B2.show).to.be.true;
        });
      });

      context("is 'POA'", function() {
        it("shows 8B2", function() {
          Form8.state.question8B1.value =  "POA";
          Form8.processState();
          expect(Form8.state.question8B2.show).to.be.false;
        });
      });
    });

    context("when question 10A", function(){
      context("is Yes", function() {
        it("shows 10B and 10C", function() {
          Form8.state.question10B.show =
          Form8.state.question10C.show = false;
          Form8.state.question10A.value =  "Yes";
          Form8.processState();

          expect(Form8.state.question10B.show).to.be.true;
          expect(Form8.state.question10C.show).to.be.true;
        });
      });

      context("is No", function() {
        it("hides 10B and 10C", function() {
          Form8.state.question10B.show =
          Form8.state.question10C.show = false;
          Form8.state.question10A.value =  "No";
          Form8.processState();

          expect(Form8.state.question10B.show).to.be.false;
          expect(Form8.state.question10C.show).to.be.false;
        });
      });
    });
  });
});
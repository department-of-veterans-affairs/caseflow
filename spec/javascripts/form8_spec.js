//= require application/form8

describe("Form8", function() {
  context(".validateRequiredQuestion", function() {
    beforeEach(function() {
      Form8.initState();
    });

    context("when question is showing", function() {
      beforeEach(function() {
        Form8.state.question5B.show = true;
      });

      context("when question's value is empty", function() {
        beforeEach(function() {
          Form8.state.question5B.value = "";
        });

        it("returns false", function() {
          expect(Form8.validateRequiredQuestion("5B")).to.be.false;
        });
      });

      context("when question has a value", function() {
        beforeEach(function() {
          Form8.state.question5B.value = "so much value";
        });

        it("returns true", function() {
          expect(Form8.validateRequiredQuestion("5B")).to.be.true;
        });
      });
    });

    context("when question is hidden", function() {
      beforeEach(function() {
        Form8.state.question5B.show = false;
      });

      context("when question's value is empty", function() {
        beforeEach(function() {
          Form8.state.question5B.value = "";
        });

        it("returns true", function() {
          expect(Form8.validateRequiredQuestion("5B")).to.be.true;
        });
      });
    });

    context("when question is a date question", function() {
      beforeEach(function() {
        Form8.dateQuestions  = {"12A": {message: "Please enter a valid date."}};
      });

      context("when question's value is a date before 1850-01-01", function() {
        beforeEach(function() {
          Form8.state.question12A.value = "12/31/1849";
        });

        it("returns false", function() {
          expect(Form8.validateRequiredQuestion("12A")).to.be.false;
        });
      });

      context("when question's value is a date after 1850-01-01 and before today", function() {
        beforeEach(function() {
          Form8.state.question12A.value = "01/01/1850";
        });

        it("returns true", function() {
          expect(Form8.validateRequiredQuestion("12A")).to.be.true;
        });
      });

      context("when question's value is a future date", function() {
        beforeEach(function() {
          Form8.state.question12A.value = (Date.today+1).to_s;
        });

        it("returns false", function() {
          expect(Form8.validateRequiredQuestion("12A")).to.be.false;
        });
      });
    });

  });

  context(".getInvalidQuestionNumbers", function() {
    beforeEach(function() {
      Form8.requiredQuestions  = {"5B": {message: "5B error"}, "6B": {message: "6B error"}};
      Form8.initState();
    });

    context("when a required question is invalid", function() {
      beforeEach(function(){
        Form8.state.question5B.show = true;
        Form8.state.question5B.value = "";
      });

      it("returns false", function() {
        expect(Form8.getInvalidQuestionNumbers()).to.not.be.empty;
      });

      it("sets error message on question", function() {
        Form8.getInvalidQuestionNumbers();
        expect(Form8.state.question5B.error.message).to.eq("5B error");
      });
    });

    context("when all required questions are valid", function() {
      beforeEach(function(){
        Form8.state.question5B.value = "value";
        Form8.state.question6B.value = "so much value";
      });

      it("returns true", function() {
        expect(Form8.getInvalidQuestionNumbers()).to.be.empty;
      });
    });
  });

  context(".processState", function() {
    beforeEach(function() {
      Form8.initState();
    });

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

      context("is None", function() {
        it("hides 8B", function() {
          Form8.state.question8A2.value =  "None";
          Form8.processState();
          expect(Form8.state.question8B1.show).to.be.false;
          expect(Form8.state.question8B2.show).to.be.false;
        });
      });
    });

    context("when question 8B1", function(){
      context("is 'Certification that valid POA is in another VA file'", function() {
        it("shows 8B2 if 'Representative type'(8A1) is not 'None'", function() {
          Form8.state.question8A2.value = "Attorney";
          Form8.state.question8B1.value = "Certification that valid POA is in another VA file";
          Form8.processState();
          expect(Form8.state.question8B2.show).to.be.true;
        });
      });

      context("is 'POA'", function() {
        it("hides 8B2", function() {
          Form8.state.question8B1.value =  "POA";
          Form8.processState();
          expect(Form8.state.question8B2.show).to.be.false;
        });
      });
    });

    context("when question 10A", function(){
      context("is Yes", function() {
        beforeEach(function() {
          Form8.state.question10B1.show =
          Form8.state.question10C.show = false;
          Form8.state.question10A.value =  "Yes";
        });

        it("shows 10B and 10C", function() {
          Form8.processState();

          expect(Form8.state.question10B1.show).to.be.true;
          expect(Form8.state.question10C.show).to.be.true;
        });

        context("when question 10B1 is Yes", function() {
          it("shows 10B2", function() {
            Form8.state.question10B1.value =  "Yes";
            Form8.processState();

            expect(Form8.state.question10B2.show).to.be.true;
          });
        });

        context("when question 10B1 is No", function() {
          it("hides 10B2", function() {
            Form8.state.question10B1.value =  "No";
            Form8.processState();

            expect(Form8.state.question10B2.show).to.be.false;
          });
        });
      });

      context("is No", function() {
        it("hides 10B and 10C", function() {
          Form8.state.question10B1.show =
          Form8.state.question10C.show = false;
          Form8.state.question10A.value =  "No";
          Form8.processState();

          expect(Form8.state.question10B1.show).to.be.false;
          expect(Form8.state.question10C.show).to.be.false;
        });
      });
    });

    context("when question 11A", function(){
      context("is Yes", function() {
        it("shows 11B", function() {
          Form8.state.question11B.show = false;
          Form8.state.question11A.value =  "Yes";
          Form8.processState();
          expect(Form8.state.question11B.show).to.be.true;
        });
      });

      context("is No", function() {
        it("hides 11B", function() {
          Form8.state.question11B.show = true;
          Form8.state.question11A.value =  "No";
          Form8.processState();
          expect(Form8.state.question11B.show).to.be.false;
        });
      });
    });

    context("when question 13 other", function(){
      context("is true", function() {
        it("shows 13B", function() {
          Form8.state.question13other = true;
          Form8.state.question132.show = false;
          Form8.processState();
          expect(Form8.state.question132.show).to.be.true;
        });
      });

      context("is No", function() {
        it("hides 13B", function() {
          Form8.state.question13other = false;
          Form8.state.question132.show = true;
          Form8.processState();
          expect(Form8.state.question132.show).to.be.false;
        });
      });
    });
  });
});

//= require form8

describe("Form8", function() {
  function emptyForm() {
    return Form8.getWatchedQuestions().reduce(function(form, questionNumber) {
      form[questionNumber] = {}
      return form;
    }, {});
  }

  context(".processShowing", function() {
    var form;

    beforeEach(function() {
      form = emptyForm();
    });

    context("when question 5A", function() {
      context("is empty", function() {
        it("hides question 5B", function() {
          form["5A"].value = "";

          var results = Form8.processShowing(form);

          expect(results["5B"].show).to.be.false;
        });
      });

      context("has a value", function() {
        it("shows question 5B", function() {
          form["5A"].value = "HI";

          var results = Form8.processShowing(form);

          expect(results["5B"].show).to.be.true;
        });
      });
    });

    context("when question 6A", function() {
      context("is empty", function() {
        it("hides question 6B", function() {
          form["6A"].value = "";

          var results = Form8.processShowing(form);

          expect(results["6B"].show).to.be.false;
        });
      });

      context("has a value", function() {
        it("shows question 6B", function() {
          form["6A"].value = "HI";

          var results = Form8.processShowing(form);

          expect(results["6B"].show).to.be.true;
        });
      });
    });

    context("when question 7A", function() {
      context("is empty", function() {
        it("hides question 7B", function() {
          form["7A"].value = "";

          var results = Form8.processShowing(form);

          expect(results["7B"].show).to.be.false;
        });
      });

      context("has a value", function() {
        it("shows question 7B", function() {
          form["7A"].value = "HI";

          var results = Form8.processShowing(form);

          expect(results["7B"].show).to.be.true;
        });
      });
    });

    it("hides 'Specify Other', 8C, 9A, and 9B", function() {
      var results = Form8.processShowing(form);

      expect(results["8A3"].show).to.be.false;
      expect(results["8C"].show).to.be.false;
      expect(results["9A"].show).to.be.false;
      expect(results["9B"].show).to.be.false;
    });

    context("when question 8A2", function() {
      context("is Agent", function() {
        it("shows 8C", function() {
          form["8A2"].value = "Agent";

          var results = Form8.processShowing(form);

          expect(results["8C"].show).to.be.true;
        });
      });

      context("is Organization", function() {
        beforeEach(function() {
          form["8A2"].value = "Organization";
        });

        it("shows 9A", function() {
          var results = Form8.processShowing(form);

          expect(results["9A"].show).to.be.true;
        });

        context("when 9A is No", function() {
          it("shows 9B", function() {
            form["9A"].value =  "No";

            var results = Form8.processShowing(form);

            expect(results["9B"].show).to.be.true;
          });
        });
      });

      context("is Other", function() {
        it("shows 8A3", function() {
          form["8A2"].value =  "Other";

          var results = Form8.processShowing(form);

          expect(form["8A3"].show).to.be.true;
        });
      });
    });

    context("when question 8B1", function(){
      context("is 'Certification that valid POA is in another VA file'", function() {
        it("shows 8B2", function() {
          form["8B1"].value =  "Certification that valid POA is in another VA file";

          var results = Form8.processShowing(form);

          expect(form["8B2"].show).to.be.true;
        });
      });

      context("is 'POA'", function() {
        it("hides 8B2", function() {
          form["8B1"].value =  "POA";

          var results = Form8.processShowing(form);

          expect(form["8B2"].show).to.be.false;
        });
      });
    });

    context("when question 10A", function(){
      context("is Yes", function() {
        it("shows 10B and 10C", function() {
          form["10A"].value =  "Yes";

          var results = Form8.processShowing(form);

          expect(form["10B"].show).to.be.true;
          expect(form["10C"].show).to.be.true;
        });
      });

      context("is No", function() {
        it("hides 10B and 10C", function() {
          form["10A"].value =  "No";

          var results = Form8.processShowing(form);

          expect(form["10B"].show).to.be.false;
          expect(form["10C"].show).to.be.false;
        });
      });
    });

    context("when question 11A", function(){
      context("is Yes", function() {
        it("shows 11B", function() {
          form["11A"].value =  "Yes";

          var results = Form8.processShowing(form);

          expect(form["11B"].show).to.be.true;
        });
      });

      context("is No", function() {
        it("hides 11B", function() {
          form["11A"].value =  "No";

          var results = Form8.processShowing(form);

          expect(form["11B"].show).to.be.false;
        });
      });
    });

    context("when question 13 other", function(){
      context("is true", function() {
        it("shows 132", function() {
          form["13other"] = true;

          var results = Form8.processShowing(form);

          expect(form["132"].show).to.be.true;
        });
      });

      context("is false", function() {
        it("hides 13B", function() {
          form["13other"] = false;

          var results = Form8.processShowing(form);

          expect(form["132"].show).to.be.false;
        });
      });
    });
  });

  context(".processValidation", function() {
    var form;

    beforeEach(function() {
      form = emptyForm();
    });

    context("when question is showing", function() {
      beforeEach(function() {
        form["5B"].show = true;
      });

      context("when question's value is empty", function() {
        it("is invalid", function() {
          form["5B"].value = "";

          var results = Form8.processValidation(form);

          expect(results["5B"].valid).to.be.false;
        });
      });

      context("when question has a value", function() {
        it("is valid", function() {
          form["5B"].value = "so much value";

          var results = Form8.processValidation(form);

          expect(results["5B"].valid).to.be.true;
        });
      });
    });

    context("when question is hidden", function() {
      beforeEach(function() {
        form["5B"].show = false;
      });

      context("when question's value is empty", function() {
        it("is valid", function() {
          form["5B"].value = "";

          var results = Form8.processValidation(form);

          expect(results["5B"].valid).to.be.true;
        });
      });
    });
  });

  context(".processErrorMessages", function() {
    var forms, showErrorMessages;

    beforeEach(function() {
      forms = {
        current: emptyForm(),
        previous: emptyForm()
      }
    });

    context("when question is valid", function() {
      beforeEach(function() {
        forms.current["5B"].valid = true;
      });

      context("when showErrorMessages is set", function() {
        beforeEach(function() { showErrorMessages = true; });

        it("sets error to null", function() {
          var results = Form8.processErrorMessages(forms, showErrorMessages);

          expect(results["5B"].error).to.not.exist;
        });
      });
    });

    context("when question isn't valid", function() {
      beforeEach(function() {
        forms.current["5B"].valid = false;
      });

      context("when showErrorMessages is set", function() {
        beforeEach(function() { showErrorMessages = true; });

        it("sets error", function() {
          var results = Form8.processErrorMessages(forms, showErrorMessages);

          expect(results["5B"].error.message).to.exist;
        });
      });

      context("when showErrorMessages isn't set", function() {
        beforeEach(function() { showErrorMessages = false; });

        context("when question didn't have error", function() {
          it("sets error to null", function() {
            var results = Form8.processErrorMessages(forms, showErrorMessages);

            expect(results["5B"].error).to.not.exist;
          });
        });

        context("when question had error", function() {
          beforeEach(function() {
            forms.previous["5B"].error = "david duchovny"
          });

          it("keeps the error", function() {
            var results = Form8.processErrorMessages(forms, showErrorMessages);

            expect(results["5B"].error).to.eq("david duchovny");
          });
        });
      });
    });
  });
});
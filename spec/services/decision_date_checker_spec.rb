# frozen_string_literal: true

describe DecisionDateChecker, :postgres do

    let!(:request_issues) do
        [
          create(:request_issue, :nonrating, id: 12, decision_date: 1.month.ago),
          create(:request_issue, :nonrating, id: 34, decision_date: nil),
          create(:request_issue, :nonrating, id: 56, decision_date: nil),
          create(:request_issue, :rating, id: 78),
          create(:request_issue, :unidentified),
        ]
    end

    context "nonrating request issues with nil decision dates" do
        it "should find request issues without decision dates" do 
            subject.call
            expect(subject.report).to include("#{request_issues[1].id}")
            expect(subject.report).to include("#{request_issues[2].id}")
        end
    end


    context "rating and nonrating issues with nil decision dates" do 
        it "should not check rating issues" do 
            subject.call
            expect(subject.report).not_to include("#{request_issues[3].id}")
         end
    end

    context "unidentifed issues with nil decision dates" do 
        it "should not find unidentified" do 
            subject.call
            expect(subject.report).not_to include("unidentified")
         end
    end
  end
  
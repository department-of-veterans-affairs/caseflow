describe TemporaryAppeal do
  before do
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:receipt_date) { SupplementalClaim::AMA_BEGIN_DATE + 1 }
  let(:docket_type) { nil }
  let(:established_at) { nil }

  let(:appeal) do
    TemporaryAppeal.new(
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      docket_type: docket_type,
      established_at: established_at
    )
  end

  context "#valid?" do
    subject { appeal.valid? }

    context "receipt_date" do
      context "when it is nil" do
        let(:receipt_date) { nil }
        it { is_expected.to be true }
      end

      context "when it is after today" do
        let(:receipt_date) { 1.day.from_now }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(appeal.errors[:receipt_date]).to include("in_future")
        end
      end

      context "when it is before AMA begin date" do
        let(:receipt_date) { SupplementalClaim::AMA_BEGIN_DATE - 1 }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(appeal.errors[:receipt_date]).to include("before_ama")
        end
      end

      context "when saving receipt" do
        before { appeal.save(context: :intake_review) }

        context "when it is nil" do
          let(:receipt_date) { nil }

          it "adds error to receipt_date" do
            is_expected.to be false
            expect(appeal.errors[:receipt_date]).to include("blank")
          end
        end
      end
    end

    context "docket_type" do
      context "during review" do
        before { appeal.save(context: :intake_review) }

        context "when it is set" do
          let(:docket_type) { "hearing" }

          it "is valid" do
            is_expected.to be true
          end
        end

        context "when it is nil" do
          let(:docket_type) { nil }
          it "adds errors to docket_type" do
            is_expected.to be false
            expect(appeal.errors[:docket_type]).to include("blank")
          end
        end
      end
    end
  end

  context "#create_issues!" do
    before { appeal.save! }
    subject { appeal.create_issues!(request_issues_data: request_issues_data) }

    let!(:request_issues_data) do
      [
        { reference_id: "abc", profile_date: "2018-04-04", decision_text: "hello" },
        { reference_id: "def", profile_date: "2018-04-08", decision_text: "goodbye" }
      ]
    end

    let!(:outdated_issue) do
      appeal.request_issues.create!(
        rating_issue_reference_id: "000",
        rating_issue_profile_date: Date.new,
        description: "i will be destroyed"
      )
    end

    it "creates issues from request_issues_data" do
      subject
      expect(appeal.request_issues.count).to eq(2)
      expect(appeal.request_issues.find_by(rating_issue_reference_id: "abc")).to have_attributes(
        rating_issue_profile_date: Date.new(2018, 4, 4),
        description: "hello"
      )
    end
  end
end

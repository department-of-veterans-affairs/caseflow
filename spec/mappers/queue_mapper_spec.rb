# frozen_string_literal: true

describe QueueMapper do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  describe "#rename_and_validate_decass_attrs" do
    subject { QueueMapper.new(info).rename_and_validate_decass_attrs }

    context "when all fields are present" do
      let(:info) do
        { work_product: "OMO - IME",
          overtime: false,
          document_id: "123456789.1234",
          note: "Require action4",
          modifying_user: "TESTSLOGID",
          reassigned_to_judge_date: VacolsHelper.local_date_with_utc_timezone,
          assigned_to_attorney_date: VacolsHelper.local_date_with_utc_timezone,
          attorney_id: "123",
          group_name: "DCS",
          complexity: :medium,
          quality: :exceeds_expectations,
          comment: "do something",
          deficiencies: [:caselaw, :lay_evidence, :remands_are_not_completed],
          one_touch_initiative: true,
          case_id: "123",
          adding_user: "TESTSLOGID",
          added_at_date: VacolsHelper.local_date_with_utc_timezone,
          deadline_date: VacolsHelper.local_date_with_utc_timezone,
          board_member_id: "123",
          complexity_rating: "4",
          completion_date: VacolsHelper.local_date_with_utc_timezone,
          timeliness: "Y" }
      end

      let(:expected_result) do
        { deprod: "IME",
          dedocid: "123456789.1234",
          deatcom: "Require action4",
          dereceive: VacolsHelper.local_date_with_utc_timezone,
          demdtim: VacolsHelper.local_date_with_utc_timezone,
          demdusr: "TESTSLOGID",
          deassign: VacolsHelper.local_date_with_utc_timezone,
          deatty: "123",
          deteam: "DCS",
          defdiff: "2",
          deoq: "4",
          debmcom: "do something",
          deqr3: "Y",
          deqr7: "Y",
          deqr10: "Y",
          de1touch: "Y",
          defolder: "123",
          deadusr: "TESTSLOGID",
          deadtim: VacolsHelper.local_date_with_utc_timezone,
          dedeadline: VacolsHelper.local_date_with_utc_timezone,
          dememid: "123",
          deicr: "4",
          decomp: VacolsHelper.local_date_with_utc_timezone,
          detrem: "Y" }
      end
      it { is_expected.to eq expected_result }
    end

    context "when optional note is nil" do
      let(:info) do
        { work_product: "OMO - IME",
          overtime: true,
          note: nil,
          reassigned_to_judge_date: VacolsHelper.local_date_with_utc_timezone,
          document_id: "123456789.1234",
          modifying_user: "TESTSLOGID" }
      end

      it "renames the key to deatcom and sets it to nil" do
        expect(subject[:deatcom]).to be_nil
      end
    end

    context "when optional note is missing" do
      let(:info) do
        { work_product: "OMO - IME",
          overtime: false,
          reassigned_to_judge_date: VacolsHelper.local_date_with_utc_timezone,
          document_id: "123456789.1234",
          modifying_user: "TESTSLOGID" }
      end

      it "does not contain the deatcom key" do
        expect(subject.keys).to_not include :deatcom
      end
    end

    context "when work product key is present and overtime is true" do
      let(:info) do
        { work_product: "OMO - IME",
          overtime: true,
          note: nil,
          reassigned_to_judge_date: VacolsHelper.local_date_with_utc_timezone,
          document_id: "123456789.1234",
          modifying_user: "TESTSLOGID" }
      end

      it "converts to the VACOLS overtime work product codes" do
        expect(subject[:deprod]).to eq "OTI"
      end
    end

    context "when work product key is present and overtime is false" do
      let(:info) do
        { work_product: "OMO - IME",
          overtime: false }
      end

      it "converts to the VACOLS regular work product codes" do
        expect(subject[:deprod]).to eq "IME"
      end
    end

    context "when work product key is present but the value is unrecognized" do
      let(:info) do
        { work_product: "foo",
          overtime: false }
      end

      it "sets to deprod to nil" do
        expect(subject[:deprod]).to be_nil
      end
    end

    context "when complexity key is present but the value is invalid" do
      let(:info) do
        { complexity: "not_valid" }
      end

      it "raises Caseflow::Error::QueueRepositoryError" do
        expect { subject }.to raise_error(Caseflow::Error::QueueRepositoryError)
      end
    end

    context "when complexity is valid" do
      let(:info) do
        { complexity: "hard" }
      end

      it "converts the string complexity into a number" do
        expect(subject[:defdiff]).to eq "3"
      end
    end

    context "when quality is not valid" do
      let(:info) do
        { quality: "not_valid" }
      end

      it "raises Caseflow::Error::QueueRepositoryError" do
        expect { subject }.to raise_error(Caseflow::Error::QueueRepositoryError)
      end
    end

    context "when quality is valid" do
      let(:info) do
        { quality: "does_not_meet_expectations" }
      end

      it "converts the string quality into a number" do
        expect(subject[:deoq]).to eq "1"
      end
    end

    context "when deficiencies are present" do
      let(:info) do
        {
          deficiencies: [
            :issues_are_not_addressed,
            :theory_contention,
            :caselaw,
            :statute_regulation,
            :admin_procedure,
            :relevant_records,
            :lay_evidence,
            :findings_are_not_supported,
            :process_violations,
            :remands_are_not_completed,
            :grammar_errors
          ]
        }
      end

      it "renames the keys and sets them all to Y" do
        (1..11).each do |index|
          expect(subject[:"deqr#{index}"]).to eq "Y"
        end
      end
    end

    context "demdtim timestamp" do
      let(:info) do
        {}
      end

      it "always adds a key called demdtime set to the local date with UTC timezone" do
        expect(subject[:demdtim]).to eq VacolsHelper.local_date_with_utc_timezone
      end
    end

    context "one_touch_initiative is true" do
      let(:info) do
        { one_touch_initiative: true }
      end

      it "renames the key to de1touch and maps true to Y" do
        expect(subject[:de1touch]).to eq "Y"
      end
    end

    context "one_touch_initiative is false" do
      let(:info) do
        { one_touch_initiative: false }
      end

      it "renames the key to de1touch and maps false to N" do
        expect(subject[:de1touch]).to eq "N"
      end
    end
  end
end

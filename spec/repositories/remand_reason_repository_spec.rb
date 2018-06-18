describe RemandReasonRepository do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context ".update_remand_reasons" do
    subject { RemandReasonRepository.update_remand_reasons(record, issue_attrs) }
    let(:record) do
      OpenStruct.new(issdc: initial_disposition)
    end

    let(:issue_attrs) do
      {
        disposition: disposition,
        vacols_user_id: "TEST1",
        readjudication: nil,
        vacols_sequence_id: "3",
        vacols_id: "123456",
        remand_reasons: [{ code: "AB", after_certification: true }]
      }
    end

    context "when disposition is not changed from remanded" do
      let(:initial_disposition) { "3" }
      let(:disposition) { "3" }
      let(:remand_reasons) { create(:remand_reason) }

      it "does not create new remand reasons" do
        remand_reasons.save!
        expect(RemandReasonRepository).to_not receive(:create_remand_reasons!)
        subject
      end

      it "updates existing remand reasons" do
        expect(RemandReasonRepository).to receive(:update_remand_reasons!)
        subject
      end
    end

    context "when disposition is changed to remanded" do
      let(:initial_disposition) { nil }
      let(:disposition) { "3" }
      let(:remand_reasons) do
        [{
          rmdval: "AB",
          rmddev: "R2",
          rmdmdusr: "TEST1",
          rmdmdtim: VacolsHelper.local_time_with_utc_timezone
        }]
      end

      it "creates remand reasons" do
        expect(RemandReasonRepository).to receive(:create_remand_reasons!)
          .with("123456", "3", remand_reasons).once
        expect(BusinessMetrics).to_not receive(:record)
        subject
      end
    end

    context "when disposition is changed from remanded" do
      let(:initial_disposition) { "3" }
      let(:disposition) { "Allowed" }

      it "deletes existing remand reasons" do
        expect(RemandReasonRepository).to receive(:delete_remand_reasons!)
        subject
      end
    end
  end

  context ".create_remand_reasons!" do
    subject { RemandReasonRepository.create_remand_reasons!(vacols_id, vacols_sequence_id, remand_reasons) }
    let(:vacols_id) { "123456" }
    let(:vacols_sequence_id) { "3" }
    let(:remand_reasons) do
      [{
        rmdval: "AB",
        rmddev: "R2",
        rmdmdusr: "TEST1",
        rmdmdtim: VacolsHelper.local_time_with_utc_timezone
      }]
    end

    it "creates remand reasons" do
      subject
      expect(VACOLS::RemandReason.all.length).to eq(1)

      remand_reason = VACOLS::RemandReason.all.first
      expect(remand_reason.rmdval).to eq "AB"
      expect(remand_reason.rmddev).to eq "R2"
      expect(remand_reason.rmdissseq).to eq 3
      expect(remand_reason.rmdkey).to eq "123456"
    end
  end

  context ".delete_remand_reasons!" do
    subject { RemandReasonRepository.delete_remand_reasons!(vacols_id, vacols_sequence_id, **kwargs) }
    let(:vacols_id) { "123456" }
    let(:vacols_sequence_id) { "3" }
    let!(:remand_reasons) do
      [
        create(:remand_reason),
        create(:remand_reason, rmdval: "DI"),
        create(:remand_reason, rmdval: "AA")
      ]
    end

    context "deletes a specific remand reason" do
      let(:kwargs) { { rmdval: "DI" } }

      it "deletes a specific remand reason" do
        subject
        expect(VACOLS::RemandReason.all.length).to eq(2)
        expect(VACOLS::RemandReason.all.map(&:rmdval).include?("DI")).to be_falsey
      end
    end

    context "deletes all remand reasons for an issue" do
      let(:kwargs) { {} }

      it "deletes all remand reasons for an issue" do
        subject
        expect(VACOLS::RemandReason.all.length).to eq(0)
      end
    end
  end
end

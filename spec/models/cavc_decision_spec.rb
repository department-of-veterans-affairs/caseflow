describe CAVCDecision do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))
    Time.zone = "America/Chicago"
  end

  context ".load_from_vacols" do
    subject { CAVCDecision.load_from_vacols(cavc_vacols_model) }

    let(:decision_date) { AppealRepository.normalize_vacols_date(7.days.from_now) }
    let(:cavc_vacols_model) do
      OpenStruct.new(
        cvddec: decision_date,
        cvfolder: "1234"
      )
    end

    it "assigns values properly" do
      expect(subject).to have_attributes(
        appeal_vacols_id: "1234",
        decision_date: decision_date
      )
    end
  end
end

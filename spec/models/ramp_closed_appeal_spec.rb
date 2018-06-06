describe RampClosedAppeal do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  context ".reclose_all!" do
    subject { RampClosedAppeal.reclose_all! }

    let!(:ramp_closed_appeals) do
      [
        RampClosedAppeal.create!(vacols_id: "SHANE1"),
        RampClosedAppeal.create!(vacols_id: "SHANE2"),
        RampClosedAppeal.create!(vacols_id: "SHANE3")
      ]
    end

    before do
      expect(AppealRepository).to receive(:find_ramp_reopened_appeals)
        .with(%w[SHANE1 SHANE2 SHANE3])
        .and_return(["STUFF"])
    end

    it "finds reopened appeals based off of ramp closed appeals and returns them" do
      expect(subject).to eq(["STUFF"])
    end
  end
end

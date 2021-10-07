feature "Intake Edit POA on Appeals with Unrecognized Appellants", :all_dbs do
  include IntakeHelpers

  before do
    Timecop.freeze(Time.zone.today)
  end

  let!(:colocated_user) do
    create(:user).tap { |user| Colocated.singleton.add_user(user) }
  end
  let!(:colocated_staff) { create(:staff, :colocated_role, sdomainid: colocated_user.css_id) }
  let(:appeal) { create(:appeal, veteran: create(:veteran) )}
  let(:ua_with_no_poa) do 
    create(
      :unrecognized_appellant,
      unrecognized_power_of_attorney_id: nil
    )
  end
  let!(:claimant) do 
    create(
      :claimant,
      unrecognized_appellant: ua_with_no_poa,
      decision_review: appeal,
      type: "OtherClaimant"
    )
  end

  context "when appeal with unrecognized appellant has no POA record" do
    it "allows VLJ support user to update the POA record" do
      User.authenticate!(user: colocated_user)
      visit "queue/appeals/#{appeal.uuid}"
      binding.pry
    end
  end

  context "when appeal with unrecognized appellant has a POA record" do
    it "does not allow user to update the POA record" 
  end

end
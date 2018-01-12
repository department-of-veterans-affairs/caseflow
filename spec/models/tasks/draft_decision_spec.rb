describe DraftDecision do
  let(:case_assignment) do
    OpenStruct.new(appeal_id: "1111", due_on: nil, assigned_on: nil, docket_date: nil)
  end

  context "#from_vacols" do
    subject { DraftDecision.from_vacols(case_assignment, "USER_ID") }

    it "is hydrated from appeal model" do
      expect(subject.user_id).to eq("USER_ID")
    end
  end

  context "#to_hash" do
    subject { DraftDecision.from_vacols(case_assignment, "USER_ID").to_hash }

    it "returns a hash" do
      expect(subject.class).to eq(Hash)
    end
  end
end

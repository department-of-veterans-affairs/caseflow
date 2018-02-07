describe VacolsAssignment do
  let(:case_assignment) do
    OpenStruct.new(vacols_id: "1111", due_on: nil, assigned_on: nil, docket_date: nil)
  end

  context "#from_vacols" do
    subject { VacolsAssignment.from_vacols(case_assignment, "USER_ID") }

    it "is hydrated from appeal model" do
      expect(subject.user_id).to eq("USER_ID")
      expect(subject.id).to eq("1111")
    end
  end
end

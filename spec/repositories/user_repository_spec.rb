describe UserRepository do
  context ".vacols_role" do
    subject { UserRepository.vacols_role("TEST1") }

    context "when a user is an attorney" do
      it "should return an attorney role" do
        allow(UserRepository).to receive(:staff_record_by_css_id).and_return(OpenStruct.new(svlj: nil, sattyid: "1234"))
        expect(subject).to eq "Attorney"
      end
    end

    context "when a user is a judge" do
      it "should return a judge role" do
        allow(UserRepository).to receive(:staff_record_by_css_id).and_return(OpenStruct.new(svlj: "J"))
        expect(subject).to eq "Judge"
      end
    end

    context "when a user is an acting judge" do
      it "should return a judge role" do
        allow(UserRepository).to receive(:staff_record_by_css_id).and_return(OpenStruct.new(svlj: "A"))
        expect(subject).to eq "Judge"
      end
    end

    context "when a user is an acting judge and has an attorney number" do
      it "should return an attorney role" do
        allow(UserRepository).to receive(:staff_record_by_css_id).and_return(OpenStruct.new(svlj: "A", sattyid: "1234"))
        expect(subject).to eq "Attorney"
      end
    end

    context "when a user is neither" do
      it "should not return a role" do
        allow(UserRepository).to receive(:staff_record_by_css_id).and_return(OpenStruct.new(svlj: "L"))
        expect(subject).to eq nil
      end
    end
  end

  context "can_access_task?" do
    subject { UserRepository.can_access_task?("TEST1", "4321") }

    context "when a task is assigned to a user" do
      it "should return true" do
        allow(QueueRepository).to receive(:tasks_for_user).and_return(
          [OpenStruct.new(vacols_id: "1234"), OpenStruct.new(vacols_id: "4321")]
        )
        expect(subject).to eq true
      end
    end

    context "when a task is not assigned to a user" do
      it "should raise Caseflow::Error::UserRepositoryError" do
        allow(QueueRepository).to receive(:tasks_for_user).and_return(
          [OpenStruct.new(vacols_id: "1234"), OpenStruct.new(vacols_id: "5678")]
        )
        expect { subject }.to raise_error(Caseflow::Error::UserRepositoryError)
      end
    end
  end

  context "vacols_uniq_id" do
    subject { UserRepository.vacols_uniq_id("TEST1") }

    context "when user exists in VACOLS" do
      it "should return an ID" do
        allow(UserRepository).to receive(:staff_record_by_css_id).and_return(OpenStruct.new(slogid: "LKG564"))
        expect(subject).to eq "LKG564"
      end
    end

    context "when user does not exist in VACOLS" do
      it "should raise Caseflow::Error::UserRepositoryError" do
        allow(UserRepository).to receive(:staff_record_by_css_id).and_raise(Caseflow::Error::UserRepositoryError)
        expect { subject }.to raise_error(Caseflow::Error::UserRepositoryError)
      end
    end
  end
end

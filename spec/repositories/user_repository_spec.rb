# frozen_string_literal: true

describe UserRepository, :all_dbs do
  let(:css_id) { "TEST1" }

  context ".vacols_role" do
    subject { UserRepository.user_info_from_vacols(css_id)[:roles] }

    context "when a user is an attorney" do
      let!(:staff) { create(:staff, sattyid: "1234", sdomainid: css_id, sactive: "A") }

      it "should return an attorney role" do
        expect(subject).to eq ["attorney"]
      end
    end

    context "when a user is a judge" do
      let!(:staff) { create(:staff, svlj: "J", sdomainid: css_id, sactive: "A") }

      it "should return a judge role" do
        expect(subject).to eq ["judge"]
      end
    end

    context "when a user has the acting judge flag set but no attorney ID" do
      let!(:staff) { create(:staff, svlj: "A", sdomainid: css_id, sattyid: nil, sactive: "A") }

      it "should return an empty role" do
        expect(subject).to eq []
      end
    end

    context "when a user is a co-located admin" do
      let!(:staff) { create(:staff, :colocated_role, sdomainid: css_id) }

      it "should return a co-located role" do
        expect(subject).to eq ["colocated"]
      end
    end

    context "when a user is both a co-located admin and a dispatcher" do
      let!(:staff) { create(:staff, sdept: "DSP", stitle: "A2", sattyid: nil, sdomainid: css_id) }

      it "should return a co-located role" do
        expect(subject).to eq %w[colocated dispatch]
      end
    end

    context "when a user is an acting judge and has an attorney number" do
      let!(:staff) { create(:staff, svlj: "A", sattyid: "1234", sdomainid: css_id, sactive: "A") }

      it "should return both roles" do
        expect(subject).to eq %w[attorney judge]
      end
    end

    context "when a user is a dispatch user" do
      let!(:staff) { create(:staff, :dispatch_role, sdomainid: css_id) }

      it "should return both roles" do
        expect(subject).to eq %w[dispatch]
      end
    end

    context "when a user is neither" do
      let!(:staff) { create(:staff, svlj: "L", sdomainid: css_id, sactive: "A") }

      it "should not return a role" do
        expect(subject).to eq []
      end
    end

    context "when user does not exist in VACOLS" do
      it "should return nil" do
        expect(subject).to eq []
      end
    end
  end

  context ".css_ids_by_vlj_ids" do
    let(:sattyid) { "9876" }
    let(:first_name) { "Leocadia" }
    let(:last_name) { "Jarecki" }
    let!(:staff) do
      create(
        :staff,
        svlj: "J",
        sdomainid: css_id,
        sactive: "A",
        sattyid: sattyid,
        snamef: first_name,
        snamel: last_name
      )
    end

    it "returns the expected results" do
      result = described_class.css_ids_by_vlj_ids(sattyid)
      expect(result.keys.length).to eq 1
      expect(result.keys.first).to eq sattyid

      record = result[sattyid]
      expect(record[:css_id]).to eq css_id
      expect(record[:first_name]).to eq first_name
      expect(record[:last_name]).to eq last_name
    end

    context "more than one record" do
      let(:css_id2) { "TESTX" }
      let(:sattyid2) { "8765" }
      let!(:staff2) do
        create(
          :staff,
          svlj: "J",
          sdomainid: css_id2,
          sactive: "A",
          sattyid: sattyid2
        )
      end

      it "returns the expected results" do
        result = described_class.css_ids_by_vlj_ids([sattyid, sattyid2])
        expect(result.keys.length).to eq 2
        expect(result.keys).to match_array [sattyid, sattyid2]
      end
    end
  end

  context "fail_if_no_access_to_task!" do
    subject { UserRepository.fail_if_no_access_to_task!(css_id, "4321") }

    context "when a task is assigned to a user" do
      let(:user) { User.create(css_id: css_id, station_id: "101") }
      let!(:vacols_case) { create(:case, :assigned, bfkey: "4321", user: user) }

      it "should return true" do
        expect(subject).to eq true
      end
    end

    context "when a task is not assigned to a user" do
      let(:user) { User.create(css_id: css_id, station_id: "101") }
      let!(:vacols_case) { create(:case, :assigned, bfkey: "5678", user: user) }

      it "should raise Caseflow::Error::UserRepositoryError" do
        expect { subject }.to raise_error(Caseflow::Error::UserRepositoryError)
      end
    end
  end

  context "vacols_uniq_id" do
    subject { UserRepository.user_info_from_vacols(css_id)[:uniq_id] }

    context "when user exists in VACOLS" do
      let!(:staff) { create(:staff, slogid: "LKG564", sdomainid: css_id) }

      it "should return an ID" do
        expect(subject).to eq "LKG564"
      end

      it "should use cached value" do
        expect(VACOLS::Staff).to receive(:find_by).once
        UserRepository.user_info_from_vacols(css_id)[:uniq_id]
        # call a second time, should get from the cache
        UserRepository.user_info_from_vacols(css_id)[:uniq_id]
      end
    end

    context "when user does not exist in VACOLS" do
      it "should return nil" do
        expect(subject).to eq nil
      end
    end
  end

  context "user_info_for_idt" do
    subject { UserRepository.user_info_for_idt(css_id) }

    context "when user exists in VACOLS" do
      let!(:staff) { create(:staff, :attorney_judge_role, sdomainid: css_id) }

      it "should return judge status" do
        expect(subject[:judge_status]).to eq "acting judge"
      end

      it "should use cached value" do
        expect(VACOLS::Staff).to receive(:find_by).once
        UserRepository.user_info_for_idt(css_id)
        # call a second time, should get from the cache
        UserRepository.user_info_for_idt(css_id)
      end
    end

    context "when user does not exist in VACOLS" do
      it "should return nil" do
        expect(subject[:judge_status]).to eq(nil)
      end
    end
  end
end

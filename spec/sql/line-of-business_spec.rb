# frozen_string_literal: true

describe "Line of Business extract example", :postgres do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  let!(:vha_request_issue) { create(:request_issue, benefit_type: "vha") }
  let!(:vha_appeal_decision_issue) { create(:decision_issue, decision_review: vha_request_issue.decision_review) }

  let(:vet) { create(:veteran) }
  let!(:vha_hlr) { create(:higher_level_review, :processed, benefit_type: "vha", veteran_file_number: vet.file_number) }
  let!(:vha_hlr_decision_issue) { create(:decision_issue, decision_review: vha_hlr) }

  let(:vet2) { create(:veteran) }
  let!(:vha_sc) { create(:supplemental_claim, :processed, benefit_type: "vha", veteran_file_number: vet2.file_number) }
  let!(:vha_sc_decision_issue) { create(:decision_issue, decision_review: vha_sc) }

  before do
    # Create negative examples, such as a non-VHA appeal and non-established supplemental claims
    create(:request_issue, benefit_type: "foobar")

    create(:higher_level_review)
    create(:higher_level_review, :processed)
    create(:higher_level_review, benefit_type: "vha")

    create(:supplemental_claim)
    create(:supplemental_claim, :processed)
    create(:supplemental_claim, benefit_type: "vha")
  end

  it "compiles SQL" do
    sql_statements = read_sql("line-of-business").split(";")
    sql_statements.each do |sql|
      result = ApplicationRecord.connection.exec_query(sql)
      expect(result.to_ary).to be_a(Array)
    end
  end

  context "with hash of queries loaded" do
    shared_examples "a correct record retrieval" do |query_name|
      let(:query_hash) { read_sql_as_hash("line-of-business").split(";") }
      let(:expected_record_id) { nil }
      let(:expected_record_uuid) { nil }
      let(:expected_record_ssn) { nil }

      it "returns the record for #{query_name}" do
        query = query_hash[query_name]
        expect(query).not_to be_nil, "Could not find query #{query_name}"
        result = ApplicationRecord.connection.exec_query(query).to_ary
        expect(result.count).to be(1)
        expect(result.first["id"]).to eq(expected_record_id) if expected_record_id
        expect(result.first["uuid"]).to eq(expected_record_uuid) if expected_record_uuid
        expect(result.first["ssn"]).to eq(expected_record_ssn) if expected_record_ssn
      end
    end

    it_behaves_like("a correct record retrieval", "vha_request_issues") do
      let(:expected_record_id) { vha_request_issue.id }
    end

    it_behaves_like("a correct record retrieval", "vha_established_appeals") do
      let(:expected_record_id) { vha_request_issue.decision_review.id }
    end

    it_behaves_like("a correct record retrieval", "vha_established_hlrs") do
      let(:expected_record_id) { vha_hlr.id }
    end

    it_behaves_like("a correct record retrieval", "vha_established_scs") do
      let(:expected_record_id) { vha_sc.id }
    end

    it_behaves_like("a correct record retrieval", "vha_established_appeals_by_vet_filenumber") do
      let(:expected_record_uuid) { vha_request_issue.decision_review.uuid }
      let(:expected_record_ssn) { vha_request_issue.decision_review.veteran.ssn }
    end

    it_behaves_like("a correct record retrieval", "vha_established_hlrs_by_vet_filenumber") do
      let(:expected_record_uuid) { vha_hlr.uuid }
      let(:expected_record_ssn) { vet.ssn }
    end

    it_behaves_like("a correct record retrieval", "vha_established_scs_by_vet_filenumber") do
      let(:expected_record_uuid) { vha_sc.uuid }
      let(:expected_record_ssn) { vet2.ssn }
    end

    it_behaves_like("a correct record retrieval", "vha_appeal_decisions") do
      let(:expected_record_id) { vha_appeal_decision_issue.id }
    end

    it_behaves_like("a correct record retrieval", "vha_established_hlr_decisions") do
      let(:expected_record_id) { vha_hlr_decision_issue.id }
    end

    it_behaves_like("a correct record retrieval", "vha_established_sc_decisions") do
      let(:expected_record_id) { vha_sc_decision_issue.id }
    end
  end
end

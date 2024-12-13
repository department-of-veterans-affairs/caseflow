# frozen_string_literal: true

describe Api::V3::Issues::VACOLS::VacolsIssueSerializer, :postgres do
  context "VACOLS issue object" do
    let(:vacols_id) { "12345678" }
    let(:disposition) { nil }
    let(:disposition_date) { Time.zone.today }
    let(:soc_date) { Time.zone.today }
    let(:vacols_case) do
      create(:case_with_soc, :status_advance, case_issues: [vacols_case_issue], bfkey: vacols_id, bfdsoc: soc_date)
    end
    let(:vacols_case_issue) do
      create(
        :case_issue,
        isskey: vacols_id,
        issdc: Issue.disposition_code_for_sym(disposition),
        issdcls: disposition_date
      )
    end
    let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let(:issue) { Issue.load_from_vacols(vacols_case_issue.attributes) }

    it "should show all the fields" do
      serialized_vacols_issue = Api::V3::Issues::VACOLS::VacolsIssueSerializer.new(issue)
        .serializable_hash[:data][:attributes][:vacols_issue]

      expect(serialized_vacols_issue).not_to eq nil
      expect(serialized_vacols_issue[:id]).to eq "12345678"
      expect(serialized_vacols_issue[:notice_of_disagreement_date]).to eq appeal.nod_date
      expect(serialized_vacols_issue[:legacy_appeal_status]).to eq appeal.status
      expect(serialized_vacols_issue[:legacy_appeal_soc_date]).to eq appeal.soc_date
      expect(serialized_vacols_issue[:legacy_appeal_ssoc_dates]).to eq appeal.ssoc_dates
      expect(serialized_vacols_issue[:legacy_appeal_eligible_for_opt_in]).to eq appeal.eligible_for_opt_in?(
        receipt_date: Time.zone.today
      )
      expect(serialized_vacols_issue[:legacy_appeal_eligible_for_soc_opt_in_with_exemption]).to eq(
        appeal.eligible_for_opt_in?(receipt_date: Time.zone.today, covid_flag: true)
      )
      expect(serialized_vacols_issue[:vacols_id]).to eq issue.id
      expect(serialized_vacols_issue[:vacols_sequence_id]).to eq issue.vacols_sequence_id
      expect(serialized_vacols_issue[:eligible_for_soc_opt_in]).to eq issue.eligible_for_opt_in?
      expect(serialized_vacols_issue[:eligible_for_soc_opt_in_with_exemption])
        .to eq issue.eligible_for_opt_in?(covid_flag: true)
      expect(serialized_vacols_issue[:description]).to eq issue.friendly_description
      expect(serialized_vacols_issue[:disposition]).to eq issue.disposition
      expect(serialized_vacols_issue[:close_date]).to eq issue.close_date
      expect(serialized_vacols_issue[:note]).to eq issue.note
    end
  end
end

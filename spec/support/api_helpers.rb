# frozen_string_literal: true

require "./spec/support/shared_context/shared_context_docket_dates.rb"

module ApiHelpers
  # rubocop:disable Metrics/AbcSize
  
  def api_setup_appeal_repository_dockets
    include_context "docket dates", include_shared: true    
  end

  def api_create_legacy_appeal_complete_with_hearings(vbms_id)
    create(:legacy_appeal, vacols_case: create(
      :case,
      :type_original,
      :status_complete,
      :disposition_remanded,
      bfdrodec: Time.zone.today - 18.months,
      bfdnod: Time.zone.today - 12.months,
      bfdsoc: Time.zone.today - 9.months,
      bfd19: Time.zone.today - 8.months,
      bfssoc1: Time.zone.today - 7.months,
      bfddec: Time.zone.today - 5.months,
      remand_return_date: 2.days.ago,
      bfcorlid: vbms_id,
      bfkey: "1234567",
      case_issues: [create(
        :case_issue,
        :disposition_remanded,
        issdcls: Time.zone.today - 5.months,
        issprog: "02",
        isscode: "15",
        isslev1: "03",
        isslev2: "5252"
      )],
      case_hearings: [build(:case_hearing, :disposition_held, hearing_date: 6.months.ago)]
    ))
  end

  def api_create_legacy_appeal_post_remand(vbms_id)
    create(:legacy_appeal, vacols_case: create(
      :case,
      :assigned,
      :type_post_remand,
      :status_active,
      bfdrodec: Time.zone.today - 18.months,
      bfdnod: Time.zone.today - 12.months,
      bfdsoc: Time.zone.today - 9.months,
      bfd19: Time.zone.today - 8.months,
      bfssoc1: Time.zone.today - 7.months,
      bfssoc2: Time.zone.today - 4.months,
      bfdpdcn: Time.zone.today - 5.months,
      bfcorlid: vbms_id,
      bfkey: "7654321",
      case_issues: [create(:case_issue, issprog: "02", isscode: "15", isslev1: "03", isslev2: "5252")]
    ))
  end

  def api_create_legacy_appeal_advance(vbms_id)
    create(:legacy_appeal, vacols_case: create(
      :case,
      :type_original,
      :status_advance,
      :aod,
      bfdrodec: Time.zone.today - 12.months,
      bfdnod: Time.zone.today - 6.months,
      bfdsoc: Time.zone.today - 5.months,
      bfcorlid: vbms_id,
      case_issues: [
        create(:case_issue, issprog: "02", isscode: "15", isslev1: "04", isslev2: "5301"),
        create(
          :case_issue,
          :disposition_granted_by_aoj,
          issprog: "02",
          isscode: "15",
          isslev1: "04",
          isslev2: "5302",
          issdcls: Time.zone.today - 5.days
        )
      ]
    ))
  end
  # rubocop:enable Metrics/AbcSize
end

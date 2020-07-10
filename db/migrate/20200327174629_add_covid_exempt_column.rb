# frozen_string_literal: true

class AddCovidExemptColumn < Caseflow::Migration
  def change
    add_column :request_issues, :covid_timeliness_exempt, :boolean, comment: "If a veteran requests a timeliness exemption that is related to COVID-19, this is captured when adding a Request Issue and available for reporting."
  end
end

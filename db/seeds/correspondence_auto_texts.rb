# frozen_string_literal: true

module Seeds
  class CorrespondenceAutoTexts < Base
    def seed!
      create_auto_text_data
    end

    def create_auto_text_data
      correspondence_auto_texts.each do |text|
        AutoText.find_or_create_by(name: text)
      end
    end

    private

    def correspondence_auto_texts
      [
        "Address updated in VACOLS",
        "Decision sent to Senator or Congressman mm/dd/yy",
        "Interest noted in telephone call of mm/dd/yy",
        "Interest noted in evidence file regarding current appeal",
        "Email - responded via email on mm/dd/yy",
        "Email - written response req; confirmed receipt via email to Congress office on mm/dd/yy",
        "Possible motion pursuant to BVA decision dated mm/dd/yy",
        "Motion pursuant to BVA decision dated mm/dd/yy",
        "Statement in support of appeal by appellant",
        "Statement in support of appeal by rep",
        "Medical evidence X-Rays submitted or referred by",
        "Medical evidence clinical reports submitted or referred by",
        "Medical evidence examination reports submitted or referred by",
        "Medical evidence progress notes submitted or referred by",
        "Medical evidence physician's medical statement submitted or referred by",
        "C&P exam report",
        "Consent form (specify)",
        "Withdrawal of issues",
        "Response to BVA solicitation letter dated mm/dd/yy",
        "VAF 9 (specify)"
      ]
    end
  end
end

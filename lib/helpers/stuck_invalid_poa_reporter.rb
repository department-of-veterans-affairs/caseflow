# frozen_string_literal: true

# when an SC or HLR runs into this error, AND the associated vet doesn't have
# ANY other established EPs in the same family (040-049 for SCs; 030-039 for HLRs),
# then it's likely an Invalid POA issue, which we ask our OAR partners to fix.
class StuckInvalidPoaReporter
  ERROR = "#<Caseflow::Error::DuplicateEp: Caseflow::Error::DuplicateEp>"

  class << self
    def run
      RequestStore[:current_user] ||= User.system_user
      rows = [
        [HigherLevelReview, /^03\d$/],
        [SupplementalClaim, /^04\d$/]
      ].map { |klass, pattern| collect_jobs(klass, pattern) }
        .flatten
        .map { |job| generate_row(job) }

      CSV.generate do |csv|
        csv << [
          "Veteran File Number",
          "EP Code",
          "Claimant Type",
          "Claimant Participant ID",
          "POA Record"
        ]
        rows.uniq.each { |row| csv << row }
      end
    end

    def collect_jobs(klass, pattern)
      klass.where(establishment_error: ERROR).order(:establishment_submitted_at).reject do |cr|
        modifiers = cr.veteran.end_products.map(&:modifier)
        modifiers.any? { |mod| pattern.match?(mod) }
      end
    end

    def generate_row(review)
      unestablished = review.end_product_establishments.find { |epe| epe.reference_id.nil? }
      [
        review.veteran_file_number,
        unestablished.code,
        review.claimant.type,
        review.claimant.participant_id,
        review.claimant.representative_name.present?
      ]
    end
  end
end

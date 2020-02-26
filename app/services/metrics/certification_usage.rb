# frozen_string_literal: true

# Metric ID: 1909040936
# Metric definition:
#  (Number of appeals transferred to the Board using Caseflow /
#   Total number of appeals transferred to the Board
#  (manual certifications of paper appeals and Caseflow certifications)
#  )

class Metrics::CertificationUsage < Metrics::Base
  include Reporter

  def call
    {
      certified_total: certified_total,
      certified_paperless: certified_paperless,
      certified_with_caseflow: certified_with_caseflow,
      total_metric: percent(certified_with_caseflow, certified_total),
      paperless_metric: percent(certified_with_caseflow, certified_paperless)
    }
  end

  private

  def certifications_query
    VACOLS::Case.joins(:folder).includes(:folder).where(%(
      -- date range
      bf41stat >= ? AND bf41stat <= ? AND
      -- Original
      bfac = '1'
    ), start_date, end_date)
  end

  def certifications
    @certifications ||= certifications_query.to_a
  end

  def certified_total
    @certified_total ||= certifications.count
  end

  def certified_paperless
    @certified_paperless ||= certifications.select(&:paperless?).count
  end

  def certified_with_caseflow
    @certified_with_caseflow ||= certifications.select(&:certified_with_caseflow?).count
  end

  # currently unused, but leaving here in case we need/want to report by RO.
  def regional_office_codes
    RegionalOffice::ROS.select { |ro| ro =~ /^RO/ }
  end
end

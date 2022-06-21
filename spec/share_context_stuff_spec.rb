RSpec.configure do |rspec|
    rspec.shared_context_metadata_behavior = :apply_to_host_groups
end

RSpec.shared_context "share context stuff spec", :shared_context => :metadata do
  allow(AppealRepository).to receive(:latest_docket_month) { 11.months.ago.to_date.beginning_of_month }
  allow(AppealRepository).to receive(:regular_non_aod_docket_count) { 123_456 }
  allow(AppealRepository).to receive(:docket_counts_by_month) do
    (1.year.ago.to_date..Time.zone.today).map { |d| Date.new(d.year, d.month, 1) }.uniq.each_with_index.map do |d, i|
      {
        "year" => d.year,
        "month" => d.month,
        "cumsum_n" => i * 10_000 + 3456,
        "cumsum_ready_n" => i * 5000 + 3456
      }
        end
    end
end

RSpec.configure do |rspec|
  rspec.include_context "share context stuff spec", :include_share => true
end
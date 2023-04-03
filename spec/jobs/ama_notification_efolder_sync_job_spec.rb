# # frozen_string_literal: true

# describe AmaNotificationEfolderSyncJob, type: :job do
#   include ActiveJob::TestHelper
#   let(:current_user) { create(:user, roles: ["System Admin"]) }

#   describe "perform" do
#     # rubocop:disable Style/BlockDelimiters
#     let(:appeals) {
#       create_list(:appeal, 10)
#     }
#     let(:notifications) {
#       appeals.each do |appeal|
#         if appeal.id == 4 || appeal.id == 8
#           next
#         end

#         Notification.create!(
#           appeals_id: appeal.uuid,
#           appeals_type: "Appeal",
#           event_date: Time.now.utc.iso8601,
#           event_type: "Appeal docketed",
#           notification_type: "Email",
#           notified_at: today
#         )
#       end
#     }
#     let(:first_run_outcoded_appeals) { [Appeal.find(6), Appeal.find(7)] }
#     let(:first_run_never_synced_appeals) { Appeal.first(5) + Appeal.last(2) }
#     let(:first_run_prev_synced_appeals) { [] }

#     before do
#       notifications
#     end

#     it "get all appeals that have been recently outcoded" do
#       byebug
#     end
#   end
# end

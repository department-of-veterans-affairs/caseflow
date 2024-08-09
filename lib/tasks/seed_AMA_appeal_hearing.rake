# frozen_string_literal: true

# to create  5 AMA Appeals with hearing type video, run "bundle exec rake 'db:generate_ama_hearing[5, video, user]'""
# to create  10 AMA Appeals with hearing type virtual, run "bundle exec rake 'db:generate_ama_hearing[10, virtual, user]'""
namespace :db do
  desc "Create a seed data for AMA Appeals with hearing type video and virtual"
  task :generate_ama_hearing, [:number_of_appeals, :hearing_request_type, :user_id] => :environment do |_, args|
    num_appeals = args.number_of_appeals.to_i
    HEARING_REQUEST_TYPE = args.hearing_request_type.to_s
    USER_ID = args.user_id
    RequestStore[:current_user] = User.find_by_css_id(USER_ID)

    def create_ama_appeals(file_number, docket_number)
      request_issue = RequestIssue.create!(
        decision_review_type: "Appeal",
        nonrating_issue_category: "Unknown Issue Categor",
        type: "RequestIssue", benefit_type: "compensation",
        nonrating_issue_description: "testing"
      )
      appeal = Appeal.create!(
        docket_type: "hearing",
        original_hearing_request_type: HEARING_REQUEST_TYPE,
        stream_type: "original",
        veteran_file_number: file_number,
        stream_docket_number: docket_number,
        request_issues: [request_issue],
        receipt_date: 1.months.ago
      )

      InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      appeal.id
    end

    vets = Veteran.order(Arel.sql('RANDOM()')).first(10)
    list_id = []

    veterans_file_number = vets[0..10].pluck(:file_number)
    docket_number = 9_000_000

    begin
      num_appeals -= 1
      docket_number += 1
      file_number = veterans_file_number[rand(veterans_file_number.count)]
      list_id << create_ama_appeals(file_number, docket_number)
    end while num_appeals > 0

    list_id.each do |current_id|
      current_appeal = Appeal.where(id: current_id)
      $stdout.puts("queue/appeals/#{current_appeal[0].uuid}")
    end
  end
end

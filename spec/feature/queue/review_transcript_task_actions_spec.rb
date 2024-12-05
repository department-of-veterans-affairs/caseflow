# frozen_string_literal: true

RSpec.feature "Case Details page ReviewTranscriptTask actions" do
  let(:hearing) { create(:hearing) }
  let(:hearing_user) { create(:user) }
  let(:veteran_full_name) { hearing.appeal.veteran_full_name }

  describe "No errors found: Upload transcript to VBMS" do
    before do
      HearingAdmin.singleton.add_user(hearing_user)
      User.authenticate!(user: hearing_user)
      @task = ReviewTranscriptTask.create(
        appeal: hearing.appeal,
        assigned_to: hearing_user,
        assigned_by: User.system_user,
        parent: hearing.appeal.root_task,
        status: "assigned"
      )
      @file_name = "#{hearing.docket_number}_#{hearing.id}_Hearing.pdf"
      create(
        :transcription_file,
        hearing: hearing,
        docket_number: hearing.docket_number,
        file_name: @file_name,
        file_type: "pdf",
        aws_link: "aws_link/#{@file_name}"
      )
      create(:transcription, hearing: hearing)

      allow_any_instance_of(TasksController).to receive(:appeal).and_return(hearing.appeal)
    end

    it "displays a success banner on success" do
      visit "/queue/appeals/#{hearing.appeal.uuid}"

      click_dropdown(
        id: "available-actions",
        text: "No errors found: Upload transcript to VBMS"
      )
      fill_in "Please provide context and instructions for this action", with: "The are test notes, from our tester."

      click_on "Upload to VBMS"

      expect(page).to have_content("You have successfully uploaded #{veteran_full_name}'s final transcript to VBMS")
      expect(page).to have_content("#{veteran_full_name} #{@file_name} is now available in VBMS.")
    end
  end

  describe "Errors found and corrected: Upload transcript to VBMS" do
    before do
      HearingAdmin.singleton.add_user(hearing_user)
      User.authenticate!(user: hearing_user)

      @task = ReviewTranscriptTask.create(
        appeal: hearing.appeal,
        assigned_to: hearing_user,
        assigned_by: User.system_user,
        parent: hearing.appeal.root_task,
        status: "assigned"
      )

      @file_name = "#{hearing.docket_number}_#{hearing.id}_Hearing.pdf"

      File.write("./lib/pdfs/#{@file_name}", "fake pdf data")

      create(
        :transcription_file,
        hearing: hearing,
        docket_number: hearing.docket_number,
        file_name: @file_name,
        file_type: "pdf",
        aws_link: "aws_link/#{@file_name}"
      )

      create(:transcription, hearing: hearing)

      allow_any_instance_of(TasksController).to receive(:appeal).and_return(hearing.appeal)
    end

    after do
      File.delete("./lib/pdfs/#{@file_name}")
    end

    it "displays a success banner on success" do
      visit "/queue/appeals/#{hearing.appeal.uuid}"

      click_dropdown(
        id: "available-actions",
        text: "Errors found and corrected: Upload transcript to VBMS"
      )

      attach_file('cf-file-input', File.absolute_path("./lib/pdfs/#{@file_name}"), visible: false)

      fill_in "Please provide context and instructions for this action", with: "The are test notes, from our tester."

      click_on "Upload to VBMS"

      expect(page).to have_content("You have successfully uploaded #{veteran_full_name}'s final transcript to VBMS")
      expect(page).to have_content("#{veteran_full_name} #{@file_name} is now available in VBMS.")
    end
  end

  describe "cancel task" do
    before do
      HearingAdmin.singleton.add_user(hearing_user)
      User.authenticate!(user: hearing_user)
      @task = ReviewTranscriptTask.create(
        appeal: appeal,
        assigned_to: hearing_user,
        assigned_by: User.system_user,
        parent: appeal.root_task,
        status: "assigned"
      )
    end
    it "cancels the ReviewTranscriptTask" do
      visit "/queue/appeals/#{appeal.uuid}"

      click_dropdown(id: "available-actions", text: "Cancel task")
      fill_in "Please provide context and instructions for this action", with: "The are test notes, from our tester."
      click_on("Cancel task")

      expect(page).to have_content("ReviewTranscriptTask cancelled")

      @task.reload
      expect(@task.status).to eq("cancelled")
    end
  end
end

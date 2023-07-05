# frozen_string_literal: true

require "./app/models/batch_processes/batch_process.rb"

describe BatchProcess, :postgres do

  let!(:batch) { BatchProcess.create!(batch_type: "BatchProcssPriorityEpSync") }

  context "#find_records" do

  end


  context "#create_batch!(record)" do

  end


  context "#process_batch!" do

  end


  context "#init_counters" do

  end


  context "#batch_processing!" do

  end


  context "#batch_complete!" do

  end


  context "#increment_completed" do

  end


  context "#increment_failed" do

  end


  context "error_out_records!(record, error)" do

  end


end

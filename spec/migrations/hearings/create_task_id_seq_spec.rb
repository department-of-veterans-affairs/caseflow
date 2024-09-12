# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db", "migrate", "20240712140629_create_task_id_seq")

describe CreateTaskIdSeq do
  let(:migration) { CreateTaskIdSeq.new }

  before do
    if sequence_exists?
      migration.down
    end
  end

  after do
    if sequence_exists?
      migration.down
    end
  end

  describe "#down" do
    it "drops the task_id_seq sequence" do
      migration.up

      expect(sequence_exists?).to be true

      migration.down

      expect(sequence_exists?).to be false
    end
  end

  def sequence_exists?
    ActiveRecord::Base.connection
      .execute("SELECT EXISTS (SELECT FROM pg_class WHERE relkind = 'S' AND relname = 'task_id_seq')")
      .values[0][0]
  end
end

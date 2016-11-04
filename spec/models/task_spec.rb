describe Task do
  before do
    Task.delete_all
    Appeal.delete_all
  end
  it "persists task to DB" do
    appeal = Appeal.create(vacols_id: "vacols")
    task = Task.create(type: "ABC", appeal_id: appeal.id)
    expect(Task.find(task.id)).to be_an_instance_of(Task)
  end
end

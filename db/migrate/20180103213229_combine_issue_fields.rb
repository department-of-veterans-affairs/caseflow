class CombineIssueFields < ActiveRecord::Migration
  safety_assured

  def change
    rename_column :worksheet_issues, :description, :notes

    add_column :worksheet_issues, :description, :string

    WorksheetIssue.find_each do |worksheet_issue|
      description = ''
      description.concat(worksheet_issue.program + "\n") if worksheet_issue.program
      description.concat(worksheet_issue.name + "\n") if worksheet_issue.name
      description.concat(worksheet_issue.levels) if worksheet_issue.levels
      worksheet_issue.update_attributes! :description => description
    end

    remove_column :worksheet_issues, :program
    remove_column :worksheet_issues, :name
    remove_column :worksheet_issues, :levels
  end
end

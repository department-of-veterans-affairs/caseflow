# If you are using a Many-to-Many relationship, 
# you may tell amoeba to actually make duplicates 
# of the original related records rather than merely 
# maintaining association with the original records. 
# Cloning is easy, merely tell amoeba which fields to 
# clone in the same way you tell it which fields to include or exclude.

# This example will actually duplicate the warnings and widgets 
# in the database. If there were originally 3 warnings in the database then, 
# upon duplicating a post, you will end up with 6 warnings in the database. 
# This is in contrast to the default behavior where your new post would 
# merely be re-associated with any previously existing warnings and those 
# warnings themselves would not be duplicate.

# Configure your models with one of the styles below and then just run 
# the amoeba_dup method on your model where you would run the dup method normally:
# p = Post.create(:title => "Hello World!", :content => "Lorum ipsum dolor")
# p.comments.create(:content => "I love it!")
# p.comments.create(:content => "This sucks!")
# puts Comment.all.count # should be 2

# my_copy = p.amoeba_dup
# my_copy.save
# By default, when enabled, amoeba will copy any and all associated 
# child records automatically and associate them with the new parent record.
# You can configure the behavior to only include fields that you list or 
# to only include fields that you don't exclude. 
# puts Comment.all.count # should be 4

# This could potential help us Identify where duplicates are located in the database.
# Make a record query

# frozen_string_literal: true

# p = Post.create(:title => "Hello World!", :content => "Lorum ipsum dolor")
# p.comments.create(:content => "I love it!")
# p.comments.create(:content => "This sucks!")
# puts Comment.all.count # should be 2

# my_copy = p.amoeba_dup
# my_copy.save
# By default, when enabled, amoeba will copy any and all associated 

class SplitAppealController < ApplicationController
  def index
  end
end

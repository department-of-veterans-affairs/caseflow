# frozen_string_literal: true

class VACOLS::Issref < VACOLS::Record
  self.table_name = "issref"
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: issref
#
#  iss_code  :string(6)        indexed
#  iss_desc  :string(50)
#  lev1_code :string(6)        indexed
#  lev1_desc :string(50)
#  lev2_code :string(6)        indexed
#  lev2_desc :string(50)
#  lev3_code :string(6)        indexed
#  lev3_desc :string(50)
#  prog_code :string(6)        indexed
#  prog_desc :string(50)
#

module MasterRecordHelper
  class << self
    # This method filters master records that have children;
    # we are only interested in master records with no children
    # and children records
    def remove_master_records_with_children(records)
      children_vdkeys = records.map(&:vdkey).compact
      records.reject { |record| children?(record, children_vdkeys) }
    end

    # Fields such as 'type', 'regional_office_key', 'date' are stored in different places
    # depending whether it is a video or travel board master record
    def values_based_on_type(vacols_record)
      case vacols_record.master_record_type
      when :video
        # master record is from hearshed table
        { ro: vacols_record.folder_nr.split(" ").second,
          type: :video,
          dates: [vacols_record.hearing_date] }
      when :travel_board
        # master record is from tbshed table
        { ro: vacols_record.tbro,
          type: :travel,
          dates: days_within_range(vacols_record.tbstdate, vacols_record.tbenddate) }
      end
    end

    private

    def children?(record, children_vdkeys)
      case record.master_record_type
      when :video
        # For a video master record, the hearshed.hearing_pkseq becomes the VDKEY that links all
        # the child records (veterans scheduled for that video) to the parent record
        return children_vdkeys.map(&:to_i).include?(record.hearing_pkseq)
      when :travel_board
        # For a travel board master record, the tbsched_vdkey becomes the VDKEY that links all
        # the child records (veterans scheduled for that video) to the parent record
        # tbsched_vdkey is composed of tbshed.tbyear, tbshed.tbleg, and tbshed.tbtrip
        return children_vdkeys.include?(record.tbsched_vdkey)
      end
    end

    def days_within_range(start_date, end_date)
      dates = []
      while start_date < (end_date + 1)
        dates << start_date
        start_date += 1.day
      end
      dates
    end
  end
end

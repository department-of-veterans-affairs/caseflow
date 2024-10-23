# frozen_string_literal: true

class SearchQueryService::VacolsQuery
  def query
    <<-SQL
      select
        aod,
        "cases".bfkey vacols_id,
        "cases".bfcurloc,
        "cases".bfddec,
        "cases".bfmpro,
        "cases".bfac,
        "cases".bfcorlid,
        "correspondents".snamef,
        "correspondents".snamemi,
        "correspondents".snamel,
        "correspondents".sspare1,
        "correspondents".sspare2,
        "correspondents".sspare3,
        "correspondents".slogid,
        "folders".tinum,
        "folders".tivbms,
        "folders".tisubj2,
        (select
          JSON_ARRAYAGG(JSON_OBJECT(
            'venue' value #{case_hearing_venue_select},
            'external_id' value "h".hearing_pkseq,
            'type' value "h".hearing_type,
            'disposition' value "h".hearing_disp,
            'date' value "h".hearing_date,
            'held_by_first_name' value "s".snamef,
            'held_by_last_name' value "s".snamel,
            'notes' value "h".notes1
          ) returning CLOB)
          from hearsched "h"
          left outer join staff "s" on "s".sattyid = "h".board_member
          where "h".folder_nr="cases".bfkey
        ) hearings,
        (select
          JSON_ARRAYAGG(JSON_OBJECT(
            'id' value "i".isskey,
            'vacols_sequence_id' value "i".issseq,
            'issprog' value "i".issprog,
            'isscode' value "i".isscode,
            'isslev1' value "i".isslev1,
            'isslev2' value "i".isslev2,
            'isslev3' value "i".isslev3,
            'issdc' value "i".issdc,
            'issdesc' value "i".issdesc,
            'issdcls' value "i".issdcls,
            'issmst' value "i".issmst,
            'isspact' value "i".isspact,
            'issprog_label' value "iss".prog_desc,
            'isscode_label' value "iss".iss_desc,
            'isslev1_label' value case when "i".isslev1 is not null then
              case when "iss".lev1_code = '##' then
                "vft".ftdesc else "iss".lev1_desc
              end
            end ,
            'isslev2_label' value case when "i".isslev2 is not null then
              case when "iss".lev2_code = '##' then
                "vft".ftdesc else "iss".lev2_desc
              end
            end,
            'isslev3_label' value case when "i".isslev3 is not null then
              case when "iss".lev3_code = '##' then
                "vft".ftdesc else "iss".lev3_desc
              end
            end
          ) RETURNING CLOB)
          from issues "i"
          inner join issref "iss"
            on "i".issprog = "iss".prog_code
            and "i".isscode = "iss".iss_code
            and ("i".isslev1 is null
                or "iss".lev1_code = '##'
                or "i".isslev1 = "iss".lev1_code)
            and ("i".isslev2 is null
                or "iss".lev2_code = '##'
                or "i".isslev2 = "iss".lev2_code)
            and ("i".isslev3 is null
                or "iss".lev3_code = '##'
                or "i".isslev3 = "iss".lev3_code)
          left join vftypes "vft"
            on "vft".fttype = 'dg'
            and (("iss".lev1_code = '##' and 'dg' || "i".isslev1 = "vft".ftkey)
            or ("iss".lev2_code = '##' and 'dg' || "i".isslev2 = "vft".ftkey)
            or ("iss".lev3_code = '##' and 'dg' || "i".isslev3 = "vft".ftkey))
          where "i".isskey="cases".bfkey
        ) issues,
        (select count("hearings".hearing_pkseq) from hearsched "hearings" where "hearings".folder_nr="cases".bfkey) hearing_count,
        (select count("issues".isskey) from issues "issues" where "issues".isskey="cases".bfkey and "issues".issmst='Y') issues_mst_count,
        (select count("issues".isskey) from issues "issues" where "issues".isskey="cases".bfkey and "issues".isspact='Y') issues_pact_count
      from
        brieff "cases"
      left join folder "folders"
        on "cases".bfkey="folders".ticknum
      left join corres "correspondents"
        on "cases".bfcorkey="correspondents".stafkey
      #{VACOLS::Case::JOIN_AOD}
      where
        "cases".bfkey in (?)
    SQL
  end

  private

  def case_hearing_venue_select
    <<-SQL
      case
        when "h".hearing_type='#{VACOLS::CaseHearing::HEARING_TYPE_LOOKUP[:video]}' AND
              "h".hearing_date < '#{VACOLS::CaseHearing::VACOLS_VIDEO_HEARINGS_END_DATE}'
        then #{Rails.application.config.vacols_db_name}.HEARING_VENUE("h".vdkey)
        else "cases".bfregoff
      end
    SQL
  end
end

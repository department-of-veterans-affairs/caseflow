# frozen_string_literal: true

class SearchQueryService::Query
  def docket_number_query
    <<-SQL
      #{appeals_internal_query}
      where a.stream_docket_number=?;
    SQL
  end

  def veteran_file_number_num_params
    4
  end

  def veteran_file_number_query
    <<-SQL
      (
        #{appeals_internal_query}
        where v.ssn=? or v.file_number=?
      )
      UNION
      (
        #{legacy_appeals_internal_query}
        where v.ssn=? or v.file_number=?
      )
    SQL
  end

  def veteran_ids_query
    <<-SQL
      (
        #{appeals_internal_query}
        where v.id in (?)
      )
      UNION
      (
        #{legacy_appeals_internal_query}
        where v.id in (?)
      )
    SQL
  end

  def vacols_query
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
        "correspondents".snamel,
        "correspondents".sspare1,
        "correspondents".sspare2,
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
            'date' value "h".hearing_date
          ))
          from hearsched "h"
          where "h".folder_nr="cases".bfkey
        ) hearings,
        (select count("issues".isskey) from issues "issues" where "issues".isskey="cases".bfkey) issues_count,
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

  def legacy_appeals_internal_query
    <<-SQL
      select
        a.id,
        a.vacols_id external_id,
        'legacy_appeal' type,
        null aod_granted_for_person,
        'legacy' docket_type,
        (
          select
            jsonb_agg(la2)
          from
            (
              select
                la.*,
                (
                  select
                    row_to_json(t.*)
                  from tasks t
                  where
                    t.appeal_id=a.id and
                    t.type='RootTask' and
                    t.appeal_type='Appeal'
                  order by t.updated_at desc
                  limit 1
                ) root_task,
                (select row_to_json(v.*)) veteran
              from legacy_appeals la
              where la.id=a.id
            ) la2
        ) appeal,
        dd.decision_date,
        wm.overtime,
        pp.first_name person_first_name,
        pp.last_name person_last_name,
        v.id veteran_id,
        v.first_name veteran_first_name,
        v.last_name veteran_last_name,
        v.file_number as veteran_file_number,
        v.date_of_death,
        (
          select jsonb_agg(u2) from
          (
            select
              u.*
            from tasks t
            left join users u on
              t.assigned_to_id=u.id and
              t.assigned_to_type='User'
            where
              t.appeal_type = 'LegacyAppeal' and
              t.appeal_id=a.id and
              t.type='AttorneyTask' and
              t.status != '#{Constants.TASK_STATUSES.cancelled}'
            order by t.created_at desc
            limit 1
          ) u2
        ) assigned_attorney,
        null request_issues,
        null active_request_issues,
        null withdrawn_request_issues,
        null decision_issues,
        null hearings_count,
        '[]' hearings,
        (
          select jsonb_agg(t2) from
          (
            select
              t.*
            from tasks t
            left join organizations o on o.id=t.assigned_to_id
            left join users u on u.id=t.assigned_to_id
            where
              t.appeal_id=a.id and
              t.appeal_type='LegacyAppeal'
            order by updated_at desc
          ) t2
        ) tasks
      from legacy_appeals a
      left join claimants cl on cl.decision_review_id=a.id and cl.decision_review_type='LegacyAppeal'
      left join people pp on cl.participant_id=pp.participant_id
      left join work_modes wm on wm.appeal_id=a.id and wm.appeal_type='LegacyAppeal'
      left join decision_documents dd on dd.appeal_id=a.id and dd.appeal_type='LegacyAppeal'
      left join veterans v on v.file_number=(
        select
        case
          when right(a.vbms_id, 1) = 'C' then lpad(regexp_replace(a.vbms_id, '[^0-9]+', '', 'g'), 8, '0')
          else regexp_replace(a.vbms_id, '[^0-9]+', '', 'g')
        end
      ) or v.ssn=(
        select
        case
          when right(a.vbms_id, 1) = 'C' then lpad(regexp_replace(a.vbms_id, '[^0-9]+', '', 'g'), 8, '0')
          else regexp_replace(a.vbms_id, '[^0-9]+', '', 'g')
        end
      )
    SQL
  end

  def appeals_internal_query
    <<-SQL
      select
        a.id,
        a.uuid::varchar external_id,
        a.stream_type type,
        aod.id aod_granted_for_person,
        a.docket_type,
        (
          select jsonb_agg(a2)
          from
            (
              select
                appeals.*,
                (
                  select
                    row_to_json(t.*)
                  from tasks t
                  where
                    t.appeal_id=a.id and
                    t.type='RootTask' and
                    t.appeal_type='Appeal'
                  order by updated_at desc
                  limit 1
                ) root_task,
                (
                  select jsonb_agg(c2) from
                  (
                    select
                      c.id,
                      c.participant_id
                    from claimants c
                    where
                      c.decision_review_type = 'Appeal' and
                      c.decision_review_id=a.id
                  ) c2
                ) claimants
              from appeals
              where id=a.id
            ) a2
        ) appeal,
        dd.decision_date,
        wm.overtime,
        pp.first_name person_first_name,
        pp.last_name person_last_name,
        v.id veteran_id,
        v.first_name veteran_first_name,
        v.last_name veteran_last_name,
        v.file_number as veteran_file_number,
        v.date_of_death,
        (
          select jsonb_agg(u2) from
          (
            select
              u.*
            from tasks t
            left join users u on
              t.assigned_to_id=u.id and
              t.assigned_to_type='User'
            where
              t.appeal_type = 'Appeal' and
              t.appeal_id=a.id and
              t.type='AttorneyTask' and
              t.status != '#{Constants.TASK_STATUSES.cancelled}'
            order by t.created_at desc
            limit 1
          ) u2
        ) assigned_attorney,
        (
          select jsonb_agg(ri2) from
          (
            select
              ri.id,
              ri.benefit_type program,
              ri.notes,
              ri.decision_date,
              ri.nonrating_issue_category,
              ri.mst_status,
              ri.pact_status,
              ri.mst_status_update_reason_notes mst_justification,
              ri.pact_status_update_reason_notes pact_justification
            from request_issues ri
            where
              ri.decision_review_type='Appeal' and
              ri.decision_review_id=a.id
          ) ri2
        ) request_issues,
        (
          select jsonb_agg(ri2) from
          (
            select
              nonrating_issue_category
            from request_issues ri
            where
              ri.ineligible_reason is null and
              ri.closed_at is null and
              (ri.split_issue_status is null or ri.split_issue_status = 'in_progress') and
              ri.decision_review_type='Appeal' and
              ri.decision_review_id=a.id
          ) ri2
        ) active_request_issues,
        (
          select jsonb_agg(ri2) from
          (
            select
              nonrating_issue_category
            from request_issues ri
            where
              ri.ineligible_reason is null and
              ri.closed_status = 'widthrawn' and
              ri.decision_review_type='Appeal' and
              ri.decision_review_id=a.id
          ) ri2
        ) withdrawn_request_issues,
        (
          select jsonb_agg(di2) from
          (
            select
              di.id,
              di.disposition,
              di.description,
              di.benefit_type,
              di.diagnostic_code,
              di.mst_status,
              di.pact_status,
              array(
                  select rdi.id
                  from request_decision_issues rdi
                  where rdi.decision_issue_id=di.id
              ) request_issue_ids,
              array(
                  select rr2 from
                      (
                          select
                            rr.id,
                            rr.code,
                            rr.post_aoj
                          from remand_reasons rr
                          where rr.decision_issue_id=di.id
                      ) rr2
              ) remand_reasons
            from decision_issues di
            where
              di.decision_review_type='Appeal' and
              di.decision_review_id = a.id
          ) di2
        ) decision_issues,
        (select count(id) from hearings h where h.appeal_id=a.id) hearings_count,
        (
          select jsonb_agg(h2) from
          (
            select
              h.*,
              (
                select row_to_json(ub)
                from (select * from users u where u.id=h.updated_by_id limit 1) ub
              ) updated_by,
              (
                select row_to_json(hd2)
                from (select * from hearing_days hd where hd.id=h.hearing_day_id limit 1) hd2
              ) hearing_day
            from
              hearings h
            where
              h.appeal_id=a.id
          ) h2
        ) hearings,
        (
          select jsonb_agg(t2) from
          (
            select
              t.*
            from tasks t
            left join organizations o on o.id=t.assigned_to_id
            left join users u on u.id=t.assigned_to_id
            where
              t.appeal_id=a.id and
              t.appeal_type='Appeal'
            order by updated_at desc
          ) t2
        ) tasks
      from appeals a
      left join claimants cl on cl.decision_review_id=a.id and cl.decision_review_type='Appeal'
      left join people pp on cl.participant_id=pp.participant_id
      left join work_modes wm on wm.appeal_id=a.id and wm.appeal_type='Appeal'
      left join decision_documents dd on dd.appeal_id=a.id and dd.appeal_type='Appeal'
      left join advance_on_docket_motions aod on aod.appeal_id=a.id and aod.person_id=pp.id and aod.appeal_type='Appeal'
      left join veterans v on a.veteran_file_number=v.file_number or a.veteran_file_number=v.ssn
    SQL
  end
end

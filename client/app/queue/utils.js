/* eslint-disable max-lines */
/* eslint-disable camelcase */
import React from 'react';
import _, { capitalize, escapeRegExp } from 'lodash';
import moment from 'moment';
import { compareDesc } from 'date-fns';
import StringUtil from '../util/StringUtil';
import {
  redText,
  ISSUE_DISPOSITIONS,
  VACOLS_DISPOSITIONS,
  LEGACY_APPEAL_TYPES,
} from './constants';
import { css } from 'glamor';

import ISSUE_INFO from '../../constants/ISSUE_INFO';
import DIAGNOSTIC_CODE_DESCRIPTIONS from '../../constants/DIAGNOSTIC_CODE_DESCRIPTIONS';
import UNDECIDED_VACOLS_DISPOSITIONS_BY_ID from '../../constants/UNDECIDED_VACOLS_DISPOSITIONS_BY_ID';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES';
import TASK_STATUSES from '../../constants/TASK_STATUSES';
import REGIONAL_OFFICE_INFORMATION from '../../constants/REGIONAL_OFFICE_INFORMATION';
import HEARING_DISPOSITION_TYPES from '../../constants/HEARING_DISPOSITION_TYPES';
import COPY from '../../COPY';
import { COLORS } from '../constants/AppConstants';
import { formatDateStrUtc } from '../util/DateUtil';

/**
 * For legacy attorney checkout flow, filter out already-decided issues. Undecided
 * VACOLS disposition IDs are all numerical (1-9) or S, decided IDs are alphabetical (A-X).
 * Filter out disposition 9 because it is no longer used.
 *
 * @param {Array} issues
 * @returns {Array}
 */

export const getUndecidedIssues = (issues) =>
  _.filter(issues, (issue) => {
    if (!issue.disposition) {
      return true;
    }

    if (
      issue.disposition &&
      issue.disposition in UNDECIDED_VACOLS_DISPOSITIONS_BY_ID
    ) {
      return true;
    }
  });

export const mostRecentHeldHearingForAppeal = (appeal) => {
  const hearings = appeal.hearings.
    filter((hearing) => hearing.disposition === HEARING_DISPOSITION_TYPES.held).
    sort((h1, h2) => (h1.date < h2.date ? 1 : -1));

  return hearings.length ? hearings[0] : null;
};

export const prepareMostRecentlyHeldHearingForStore = (appealId, hearing) => {
  return {
    appealId,
    hearing: {
      heldBy: hearing.held_by,
      viewedByJudge: hearing.viewed_by_judge,
      date: hearing.date,
      type: hearing.type,
      externalId: hearing.external_id,
      disposition: hearing.disposition,
      isVirtual: hearing.is_virtual,
      scheduledForIsPast: hearing.scheduled_for_is_past,
    },
  };
};

const taskAttributesFromRawTask = (task) => {
  const decisionPreparedBy = task.attributes.decision_prepared_by?.first_name ?
    {
      firstName: task.attributes.decision_prepared_by?.first_name,
      lastName: task.attributes.decision_prepared_by?.last_name,
    } :
    null;

  return {
    uniqueId: task.id,
    isLegacy: false,
    type: task.attributes.type,
    appealType: task.attributes.appeal_type,
    addedByCssId: null,
    appealId: task.attributes.appeal_id,
    externalAppealId: task.attributes.external_appeal_id,
    assignedOn: task.attributes.assigned_at,
    closestRegionalOffice: task.attributes.closest_regional_office,
    createdAt: task.attributes.created_at,
    closedAt: task.attributes.closed_at,
    startedAt: task.attributes.started_at,
    assigneeName: task.attributes.assignee_name,
    assignedTo: {
      cssId: task.attributes.assigned_to?.css_id,
      name: task.attributes.assigned_to?.name,
      id: task.attributes.assigned_to?.id,
      isOrganization: task.attributes.assigned_to?.is_organization,
      type: task.attributes.assigned_to?.type,
    },
    assignedBy: {
      firstName: task.attributes.assigned_by?.first_name,
      lastName: task.attributes.assigned_by?.last_name,
      cssId: task.attributes.assigned_by?.css_id,
      pgId: task.attributes.assigned_by?.pg_id,
    },
    completedBy: {
      cssId: task?.attributes?.completed_by
    },
    cancelledBy: {
      cssId: task.attributes.cancelled_by?.css_id,
    },
    cancelReason: task.attributes.cancellation_reason,
    convertedBy: {
      cssId: task.attributes.converted_by?.css_id,
    },
    convertedOn: task.attributes.converted_on,
    taskId: task.id,
    parentId: task.attributes.parent_id,
    label: task.attributes.label,
    documentId: task.attributes.document_id,
    externalHearingId: task.attributes.external_hearing_id,
    workProduct: null,
    caseType: task.attributes.case_type,
    aod: task.attributes.aod,
    previousTaskAssignedOn: task.attributes.previous_task?.assigned_at,
    placedOnHoldAt: task.attributes.placed_on_hold_at,
    status: task.attributes.status,
    onHoldDuration: task.attributes.on_hold_duration,
    instructions: task.attributes.instructions,
    previous: task.attributes.previous,
    decisionPreparedBy,
    availableActions: task.attributes.available_actions,
    caseReviewId: task.attributes.attorney_case_review_id,
    timelineTitle: task.attributes.timeline_title,
    hideFromQueueTableView: task.attributes.hide_from_queue_table_view,
    hideFromTaskSnapshot: task.attributes.hide_from_task_snapshot,
    hideFromCaseTimeline: task.attributes.hide_from_case_timeline,
    availableHearingLocations: task.attributes.available_hearing_locations,
    // `powerOfAttorneyName`, `suggestedHearingLocation`,
    // `hearingRequestType`, and `isFormerTravel` are only present for
    // /hearings/scheduled/assign page, and are not returned from the API when
    // requesting the full task.
    powerOfAttorneyName: task.attributes.power_of_attorney_name,
    suggestedHearingLocation: task.attributes.suggested_hearing_location,
    hearingRequestType: task.attributes.hearing_request_type,
    isFormerTravel: task.attributes.former_travel,
    latestInformalHearingPresentationTask: {
      requestedAt:
        task.attributes.latest_informal_hearing_presentation_task?.requested_at,
      receivedAt:
        task.attributes.latest_informal_hearing_presentation_task?.received_at,
    },
    canMoveOnDocketSwitch: task.attributes.can_move_on_docket_switch,
    timerEndsAt: task.attributes.timer_ends_at,
    unscheduledHearingNotes: {
      updatedAt: task.attributes.unscheduled_hearing_notes?.updated_at,
      updatedByCssId:
        task.attributes.unscheduled_hearing_notes?.updated_by_css_id,
      notes: task.attributes.unscheduled_hearing_notes?.notes
    },
    ownedBy: task.attributes.owned_by,
    daysSinceLastStatusChange: task.attributes.days_since_last_status_change,
    daysSinceBoardIntake: task.attributes.days_since_board_intake,
    id: task.id,
    businessLine: task.attributes.business_line,
    claimant: {
      name: task.attributes.claimant?.name
    },
    veteranParticipantId: task.attributes.veteran_participant_id,
    veteranSSN: task.attributes.veteran_ssn,
    appeal_receipt_date: task.attributes.appeal_receipt_date
  };
};

export const prepareTasksForStore = (tasks) =>
  tasks.reduce((acc, task) => {
    acc[task.id] = taskAttributesFromRawTask(task);

    return acc;
  }, {});

const appealAttributesFromRawTask = (task) => ({
  id: task.attributes.appeal_id,
  type: task.attributes.appeal_type,
  externalId: task.attributes.external_appeal_id,
  docketName: task.attributes.docket_name,
  docketRangeDate: task.attributes.docket_range_date,
  isLegacyAppeal: task.attributes.docket_name === 'legacy',
  caseType: task.attributes.case_type,
  isAdvancedOnDocket: task.attributes.aod,
  overtime: task.attributes.overtime,
  contestedClaim: task.attributes.contested_claim,
  veteranAppellantDeceased: task.attributes.veteran_appellant_deceased,
  issueCount: task.attributes.issue_count,
  issueTypes: task.attributes.issue_types,
  docketNumber: task.attributes.docket_number,
  veteranFullName: task.attributes.veteran_full_name,
  veteranFileNumber: task.attributes.veteran_file_number,
  isPaperCase: task.attributes.paper_case,
});

const extractAppealsFromTasks = (tasks) => {
  return tasks.reduce((accumulator, task) => {
    if (!accumulator[task.attributes.external_appeal_id]) {
      accumulator[
        task.attributes.external_appeal_id
      ] = appealAttributesFromRawTask(task);
    }

    return accumulator;
  }, {});
};

export const extractAppealsAndAmaTasks = (tasks) => ({
  tasks: {},
  appeals: extractAppealsFromTasks(tasks),
  amaTasks: prepareTasksForStore(tasks),
});

export const tasksWithAppealsFromRawTasks = (tasks) =>
  tasks?.map((task) => ({
    ...taskAttributesFromRawTask(task),
    appeal: appealAttributesFromRawTask(task),
  }));

export const prepareLegacyTasksForStore = (tasks) => {
  const mappedLegacyTasks = tasks.map((task) => {
    return {
      uniqueId: task.attributes.external_appeal_id,
      type: task.attributes.type,
      isLegacy: true,
      appealId: task.attributes.appeal_id,
      appealType: task.attributes.appeal_type,
      externalAppealId: task.attributes.external_appeal_id,
      assignedOn: task.attributes.assigned_on,
      closedAt: null,
      startedAt: task.attributes.started_at,
      assigneeName: task.attributes.assignee_name,
      assignedTo: {
        cssId: task.attributes.assigned_to.css_id,
        isOrganization: task.attributes.assigned_to.is_organization,
        id: task.attributes.assigned_to.id,
        type: task.attributes.assigned_to.type,
        name: task.attributes.assigned_to.name,
      },
      assignedBy: {
        firstName: task.attributes.assigned_by.first_name,
        lastName: task.attributes.assigned_by.last_name,
        cssId: task.attributes.assigned_by.css_id,
        pgId: task.attributes.assigned_by.pg_id,
      },
      addedByName: task.attributes.added_by_name,
      addedByCssId: task.attributes.added_by_css_id,
      taskId: task.attributes.task_id,
      label: task.attributes.label,
      documentId: task.attributes.document_id,
      workProduct: task.attributes.work_product,
      caseType: task.attributes.case_type,
      aod: task.attributes.aod,
      previousTaskAssignedOn: task.attributes.previous_task.assigned_on,
      status: task.attributes.status,
      decisionPreparedBy: null,
      availableActions: task.attributes.available_actions,
      timelineTitle: task.attributes.timeline_title,
      hideFromQueueTableView: task.attributes.hide_from_queue_table_view,
      hideFromTaskSnapshot: task.attributes.hide_from_task_snapshot,
      hideFromCaseTimeline: task.attributes.hide_from_case_timeline,
      instructions: task.attributes.instructions,
      latestInformalHearingPresentationTask: {
        requestedAt:
          task.attributes.latest_informal_hearing_presentation_task
            ?.requested_at,
        receivedAt:
          task.attributes.latest_informal_hearing_presentation_task
            ?.received_at,
      },
    };
  });

  return _.pickBy(
    _.keyBy(mappedLegacyTasks, (task) => task.uniqueId),
    (task) => task
  );
};

export const prepareAllTasksForStore = (tasks) => {
  const amaTasks = tasks.filter((task) => {
    return !task.attributes.is_legacy;
  });
  const legacyTasks = tasks.filter((task) => {
    return task.attributes.is_legacy;
  });

  return {
    amaTasks: prepareTasksForStore(amaTasks),
    tasks: prepareLegacyTasksForStore(legacyTasks),
  };
};

export const associateTasksWithAppeals = (serverData) => {
  const {
    tasks: { data: tasks },
  } = serverData;

  return {
    tasks: prepareLegacyTasksForStore(tasks),
    appeals: extractAppealsFromTasks(tasks),
  };
};

export const prepareAppealIssuesForStore = (appeal) => {
  // Give even legacy issues an 'id' property, because other issues will have it,
  // so we can refer to this property and phase out use of vacols_sequence_id.
  let issues = appeal.attributes.issues;

  if (appeal.attributes.docket_name === 'legacy') {
    issues = issues.map((issue) => ({
      id: issue.vacols_sequence_id,
      ...issue,
    }));
  }

  return issues;
};

export const prepareAppealHearingsForStore = (appeal) =>
  appeal.attributes.hearings.map((hearing) => ({
    heldBy: hearing.held_by,
    viewedByJudge: hearing.viewed_by_judge,
    date: hearing.date,
    type: hearing.type,
    externalId: hearing.external_id,
    disposition: hearing.disposition,
    isVirtual: hearing.is_virtual,
    notes: hearing.notes,
    createdAt: hearing.created_at
  }));

const prepareAppealAvailableHearingLocationsForStore = (appeal) =>
  appeal.attributes.available_hearing_locations.map((ahl) => ({
    name: ahl.name,
    address: ahl.address,
    city: ahl.city,
    state: ahl.state,
    distance: ahl.distance,
    facilityId: ahl.facility_id,
    facilityType: ahl.facility_type,
    classification: ahl.classification,
    zipCode: ahl.zip_code,
  }));

const prepareNodDateUpdatesForStore = (appeal) => {
  let nodDateUpdates = [];

  if (appeal.attributes.nod_date_updates) {
    nodDateUpdates = appeal.attributes.nod_date_updates.map(
      (nodDateUpdate) => ({
        appealId: appeal.id,
        changeReason: nodDateUpdate.change_reason,
        newDate: nodDateUpdate.new_date,
        oldDate: nodDateUpdate.old_date,
        updatedAt: nodDateUpdate.updated_at,
        userFirstName: nodDateUpdate.updated_by.split(' ')[0],
        userLastName: nodDateUpdate.updated_by.split(' ')[
          nodDateUpdate.updated_by.split(' ').length - 1
        ],
      })
    );
  }

  return nodDateUpdates;
};

const prepareLocationHistoryForStore = (appeal) => {
  let locationHistory = [];

  if (appeal.attributes.location_history) {
    locationHistory = appeal.attributes.location_history.map((location, index) =>
      ({
        label: location.location_label,
        uniqueId: `${location.vacols_id }_${index}`,
        assignedBy: location.assigned_by,
        assignedAt: location.assigned_at,
        location: location.location_label,
        subLocation: location.sub_location,
        locationStaff: location.location_staff,
        createdAt: location.created_at,
        closedAt: location.closed_at,
        vacolsId: location.vacols_id,
        exception_flag: location.exception_flag,
        withAttorney: location['with_attorney?'],
        withJudge: location['with_judge?']
      }));
  }

  return locationHistory;
};

export const prepareAppealForStore = (appeals) => {
  const appealHash = appeals.reduce((accumulator, appeal) => {
    const {
      attributes: { issues },
    } = appeal;

    accumulator[appeal.attributes.external_id] = {
      id: appeal.id,
      appellant_hearing_email_recipient:
        appeal.attributes.appellant_hearing_email_recipient,
      representative_hearing_email_recipient:
        appeal.attributes.representative_hearing_email_recipient,
      externalId: appeal.attributes.external_id,
      docketName: appeal.attributes.docket_name,
      withdrawn: appeal.attributes.withdrawn,
      removed: appeal.attributes.removed,
      overtime: appeal.attributes.overtime,
      contestedClaim: appeal.attributes.contested_claim,
      veteranAppellantDeceased: appeal.attributes.veteran_appellant_deceased,
      withdrawalDate: formatDateStrUtc(appeal.attributes.withdrawal_date),
      isLegacyAppeal: appeal.attributes.docket_name === 'legacy',
      caseType: appeal.attributes.type,
      isAdvancedOnDocket: appeal.attributes.aod,
      issueCount: (appeal.attributes.docket_name === 'legacy' ?
        getUndecidedIssues(issues) :
        issues
      ).length,
      docketNumber: appeal.attributes.docket_number,
      assignedAttorney: appeal.attributes.assigned_attorney,
      assignedJudge: appeal.attributes.assigned_judge,
      distributedToJudge: appeal.attributes.distributed_to_a_judge,
      veteranFullName: appeal.attributes.veteran_full_name,
      veteranFileNumber: appeal.attributes.veteran_file_number,
      isPaperCase: appeal.attributes.paper_case,
      readableHearingRequestType:
        appeal.attributes.readable_hearing_request_type,
      readableOriginalHearingRequestType:
        appeal.attributes.readable_original_hearing_request_type,
      vacateType: appeal.attributes.vacate_type,
      cavcRemandsWithDashboard: appeal.attributes.cavc_remands_with_dashboard,
    };

    return accumulator;
  }, {});

  const appealDetailsHash = appeals.reduce((accumulator, appeal) => {
    accumulator[appeal.attributes.external_id] = {
      hearings: prepareAppealHearingsForStore(appeal),
      currentUserEmail: appeal.attributes.current_user_email,
      currentUserTimezone: appeal.attributes.current_user_timezone,
      completedHearingOnPreviousAppeal:
        appeal.attributes['completed_hearing_on_previous_appeal?'],
      issues: prepareAppealIssuesForStore(appeal),
      decisionIssues: appeal.attributes.decision_issues,
      substituteAppellantClaimantOptions: appeal.attributes.substitute_appellant_claimant_options,
      canEditRequestIssues: appeal.attributes.can_edit_request_issues,
      canEditCavcRemands: appeal.attributes.can_edit_cavc_remands,
      unrecognizedAppellantId: appeal.attributes.unrecognized_appellant_id,
      appellantIsNotVeteran: appeal.attributes.appellant_is_not_veteran,
      appellantFullName: appeal.attributes.appellant_full_name,
      appellantFirstName: appeal.attributes.appellant_first_name,
      appellantMiddleName: appeal.attributes.appellant_middle_name,
      appellantLastName: appeal.attributes.appellant_last_name,
      appellantSuffix: appeal.attributes.appellant_suffix,
      appellantDateOfBirth: appeal.attributes.appellant_date_of_birth,
      appellantAddress: appeal.attributes.appellant_address,
      appellantEmailAddress: appeal.attributes.appellant_email_address,
      appellantPhoneNumber: appeal.attributes.appellant_phone_number,
      appellantType: appeal.attributes.appellant_type,
      appellantPartyType: appeal.attributes.appellant_party_type,
      appellantTz: appeal.attributes.appellant_tz,
      appellantRelationship: appeal.attributes.appellant_relationship,
      contestedClaim: appeal.attributes.contested_claim,
      hasPOA: appeal.attributes.has_poa,
      assignedToLocation: appeal.attributes.assigned_to_location,
      veteranDateOfDeath: appeal.attributes.veteran_death_date,
      veteranGender: appeal.attributes.veteran_gender,
      veteranAddress: appeal.attributes.veteran_address,
      veteranParticipantId: appeal.attributes.veteran_participant_id,
      closestRegionalOffice: appeal.attributes.closest_regional_office,
      closestRegionalOfficeLabel:
        appeal.attributes.closest_regional_office_label,
      availableHearingLocations: prepareAppealAvailableHearingLocationsForStore(
        appeal
      ),
      externalId: appeal.attributes.external_id,
      efolderLink: appeal.attributes.efolder_link,
      status: appeal.attributes.status,
      decisionDate: appeal.attributes.decision_date,
      form9Date: appeal.attributes.form9_date,
      nodDate: appeal.attributes.nod_date,
      nodDateUpdates: prepareNodDateUpdatesForStore(appeal),
      certificationDate: appeal.attributes.certification_date,
      powerOfAttorney: appeal.attributes.power_of_attorney,
      cavcRemand: appeal.attributes.cavc_remand,
      regionalOffice: appeal.attributes.regional_office,
      caseflowVeteranId: appeal.attributes.caseflow_veteran_id,
      documentID: appeal.attributes.document_id,
      caseReviewId: appeal.attributes.attorney_case_review_id,
      canEditDocumentId: appeal.attributes.can_edit_document_id,
      attorneyCaseRewriteDetails:
        appeal.attributes.attorney_case_rewrite_details,
      docketSwitch: appeal.attributes.docket_switch,
      switchedDockets: appeal.attributes.switched_dockets,
      appellantSubstitution: appeal.attributes.appellant_substitution,
      substitutions: appeal.attributes.substitutions,
      hasSameAppealSubstitution:
        appeal.attributes.substitutions?.[0]?.target_appeal_uuid ===
        appeal.attributes.substitutions?.[0]?.source_appeal_uuid,
      remandSourceAppealId: appeal.attributes.remand_source_appeal_id,
      showPostCavcStreamMsg: appeal.attributes.show_post_cavc_stream_msg,
      remandJudgeName: appeal.attributes.remand_judge_name,
      hasNotifications: appeal.attributes.has_notifications,
      locationHistory: prepareLocationHistoryForStore(appeal),
    };

    return accumulator;
  }, {});

  return {
    appeals: appealHash,
    appealDetails: appealDetailsHash,
  };
};

export const prepareClaimReviewForStore = (claimReviews) => {
  const claimReviewHash = claimReviews.reduce((accumulator, claimReview) => {
    const key = `${claimReview.review_type}-${claimReview.claim_id}`;

    accumulator[key] = {
      caseflowVeteranId: claimReview.caseflow_veteran_id,
      claimantNames: claimReview.claimant_names,
      claimId: claimReview.claim_id,
      endProductStatuses: claimReview.end_product_status,
      establishmentError: claimReview.establishment_error,
      reviewType: claimReview.review_type,
      receiptDate: claimReview.receipt_date,
      veteranFileNumber: claimReview.veteran_file_number,
      veteranFullName: claimReview.veteran_full_name,
      editIssuesUrl: claimReview.caseflow_only_edit_issues_url,
    };

    return accumulator;
  }, {});

  return {
    claimReviews: claimReviewHash,
  };
};

export const renderAppealType = (appeal) => {
  const { isAdvancedOnDocket, caseType } = appeal;
  const cavc = caseType === LEGACY_APPEAL_TYPES.CAVC_REMAND;

  return (
    <React.Fragment>
      {isAdvancedOnDocket && (
        <span>
          <span {...redText}>AOD</span>,{' '}
        </span>
      )}
      {cavc ? <span {...redText}>CAVC</span> : <span>{caseType}</span>}
    </React.Fragment>
  );
};

export const renderLegacyAppealType = ({ aod, type }) => {
  const cavc = type === 'Court Remand';

  return (
    <React.Fragment>
      {aod && (
        <span>
          <span {...redText}>AOD</span>,{' '}
        </span>
      )}
      {cavc ? <span {...redText}>CAVC</span> : <span>{type}</span>}
    </React.Fragment>
  );
};

export const getDecisionTypeDisplay = (checkoutFlow) => {
  switch (checkoutFlow) {
  case DECISION_TYPES.OMO_REQUEST:
    return 'OMO';
  case DECISION_TYPES.DRAFT_DECISION:
    return 'Draft Decision';
  default:
    return StringUtil.titleCase(checkoutFlow);
  }
};

export const getIssueProgramDescription = (issue) =>
  _.get(ISSUE_INFO[issue.program], 'description', '') || 'Compensation';
export const getIssueTypeDescription = (issue) => {
  const { program, type, description } = issue;

  if (!program) {
    return description;
  }

  return _.get(ISSUE_INFO[program].levels, `${type}.description`);
};

export const getIssueDiagnosticCodeLabel = (code) => {
  const readableLabel = DIAGNOSTIC_CODE_DESCRIPTIONS[code];

  if (!readableLabel) {
    return '';
  }

  return `${code} - ${readableLabel.staff_description}`;
};

// Build case review payloads for attorney decision draft submissions as well as judge decision evaluations.
export const buildCaseReviewPayload = (
  checkoutFlow,
  decision,
  draftDecisionSubmission,
  issues,
  args = {}
) => {
  const payload = {
    data: {
      tasks: {
        type: draftDecisionSubmission ?
          'AttorneyCaseReview' :
          'JudgeCaseReview',
        ...decision.opts,
      },
    },
  };
  let isLegacyAppeal = false;

  if ('isLegacyAppeal' in args) {
    isLegacyAppeal = args.isLegacyAppeal;
    delete args.isLegacyAppeal;
  }

  if (draftDecisionSubmission) {
    _.extend(payload.data.tasks, { document_type: checkoutFlow });
  } else {
    args.factors_not_considered = _.keys(args.factors_not_considered);
    args.areas_for_improvement = _.keys(args.areas_for_improvement);
    args.positive_feedback = _.keys(args.positive_feedback);

    _.extend(payload.data.tasks, args);
  }

  if (isLegacyAppeal) {
    payload.data.tasks.issues = getUndecidedIssues(issues).map((issue) => {
      const issueAttrs = ['type', 'readjudication', 'id'];

      if (issue.disposition === VACOLS_DISPOSITIONS.REMANDED) {
        issueAttrs.push('remand_reasons');
      }

      return _.extend({}, _.pick(issue, issueAttrs), {
        disposition: _.capitalize(issue.disposition),
      });
    });
  } else {
    payload.data.tasks.issues = issues.map((issue) => {
      if (issue.disposition !== ISSUE_DISPOSITIONS.REMANDED) {
        return _.omit(issue, 'remand_reasons');
      }

      return issue;
    });
  }

  return payload;
};

/**
 * During attorney checkout flow, validate document ID field. All work
 * product document IDs will be in one of the following formats:
 * (new) /^\d{5}-\d{8}$/
 * (old) /^\d{8}\.\d{3,4}$/
 *
 * "Old" refers to decisions not prepared using the Interactive Decision Template.
 *
 * VHA work product document ID formats:
 * /^V\d/{7}\.\d{3,4}$/
 *
 * IME work product document ID formats:
 * /^M\d{7}\.\d{3,4}$/
 */
export const validateWorkProductTypeAndId = (decision) => {
  const {
    opts: { document_id: documentId, work_product: workProduct },
  } = decision;
  const newFormat = new RegExp(/^\d{5}-\d{8}$/);

  if (!workProduct) {
    return newFormat.test(documentId);
  }

  const initialChar = workProduct.includes('IME') ? 'M' : 'V';
  const regex = `^${initialChar}\\d{7}\\.\\d{3,4}$`;
  const oldFormat = new RegExp(regex);

  return oldFormat.test(documentId) || newFormat.test(documentId);
};

export const taskHasNewDocuments = (task, newDocsForAppeal) => {
  if (
    !newDocsForAppeal[task.externalAppealId] ||
    !newDocsForAppeal[task.externalAppealId].docs
  ) {
    return false;
  }

  return newDocsForAppeal[task.externalAppealId].docs.length > 0;
};

export const taskIsOnHold = (task) => {
  return task.status === TASK_STATUSES.on_hold;
};

export const taskHasCompletedHold = (task) => {
  if (task.onHoldDuration && task.placedOnHoldAt) {
    return (
      moment().
        startOf('day').
        diff(moment(task.placedOnHoldAt), 'days') >= task.onHoldDuration
    );
  }

  return false;
};

export const currentDaysOnHold = (task) => {
  if (task.onHoldDuration && task.placedOnHoldAt) {
    return moment().
      startOf('day').
      diff(moment(task.placedOnHoldAt), 'days');
  }
};

export const taskIsActive = (task) =>
  ![TASK_STATUSES.completed, TASK_STATUSES.cancelled].includes(task.status);

export const taskActionData = ({ task, match }) => {
  if (!task) {
    return {};
  }

  const { path } = match;
  const endsWith = (search, str) => {
    const esc = escapeRegExp(search);

    const pattern = new RegExp(`${esc}\\)?$`, 'gi');

    return pattern.test(str);
  };

  const relevantAction = task.availableActions.find((action) =>
    endsWith(action.value, path)
  );

  if (relevantAction && relevantAction.data) {
    return relevantAction.data;
  }

  return {};
};

export const parentTasks = (childrenTasks, allTasks) => {
  const parentTaskIds = _.map(childrenTasks, 'parentId');
  const parentTasks = parentTaskIds.map((parentId) => {
    return _.find(allTasks, ['taskId', parentId?.toString()]);
  });

  return parentTasks;
};

export const getAllChildrenTasks = (tasks, parentId) => {
  // task.uniqueId is a String and task.parentId is an Integer
  // eslint-disable-next-line eqeqeq
  const childrenTasks = tasks.filter((task) => task.parentId == parentId);

  let grandchildrenTasks = [];

  if (childrenTasks.length > 0) {

    childrenTasks.forEach((task) => {
      grandchildrenTasks = grandchildrenTasks.concat(getAllChildrenTasks(tasks, task.uniqueId));
    });

  }

  return childrenTasks.concat(grandchildrenTasks);
};

export const nullToFalse = (key, obj) => {
  if (obj[key] === null) {
    obj[key] = false;
  }

  return obj;
};

export const timelineEventsFromAppeal = ({ appeal }) => {
  const timelineEvents = [];

  // Always want the decision date
  timelineEvents.push({
    type: 'decisionDate',
    createdAt: appeal.decisionDate || null,
  });

  // Possibly add appellant substitution
  if (appeal.appellantSubstitution) {
    if (appeal.appellantSubstitution.histories) {
      appeal.appellantSubstitution.histories.map((appellantSubstitutionHistory) => {
        if (appellantSubstitutionHistory.substitution_date) {
          timelineEvents.push({
            type: 'substitutionDate',
            createdAt: appellantSubstitutionHistory.substitution_date,
          });
        }

        timelineEvents.push({
          type: 'substitutionProcessed',
          createdAt: appellantSubstitutionHistory.created_at,
          createdBy: appellantSubstitutionHistory.created_by,
          originalAppellantFullName: appellantSubstitutionHistory.original_appellant_full_name,
          originalAppellantSubstituteFullName: appellantSubstitutionHistory.original_appellant_substitute_full_name,
          currentAppellantSubstituteFullName: appellantSubstitutionHistory.current_appellant_substitute_full_name,
          currentAppellantFullName: appellantSubstitutionHistory.current_appellant_full_name
        });
      });
    } else {
      timelineEvents.push({
        type: 'substitutionDate',
        createdAt: appeal.appellantSubstitution.substitution_date,
      });

      timelineEvents.push({
        type: 'substitutionProcessed',
        createdAt: appeal.appellantSubstitution.created_at,
        createdBy: appeal.appellantSubstitution.created_by,
        originalAppellantFullName:
          appeal.appellantSubstitution.original_appellant_full_name,
        currentAppellantSubstituteFullName: appeal.appellantSubstitution.substitute_full_name,
      });
    }
  }

  // Add any edits of NOD date
  if (appeal.nodDateUpdates) {
    timelineEvents.push(
      ...appeal.nodDateUpdates.map((item) => ({
        ...item,
        type: 'nodDateUpdate',
      }))
    );
  }

  return timelineEvents;
};

export const formatSearchableDropdownOptions = (options) => {
  return _.map(options, (value, key) => {
    return { value: key,
      label: value };
  });
};

export const sortCaseTimelineEvents = (...eventArrays) => {
  // Combine disparate sets of timeline events into a single array
  const timelineEvents = [].concat(...eventArrays);

  // We want items with undefined dates (such as pending decision date) to sort to the beginning
  const sortedTimelineEvents = timelineEvents.sort((prev, next) => {
    const d1 = prev.closedAt || prev.createdAt || prev.updatedAt;
    const d2 = next.closedAt || next.createdAt || next.updatedAt;

    // In cases of null/undefined dates, we sort to the front
    if (!d1) {
      return -1;
    } else if (!d2) {
      return 1;
    }

    return compareDesc(new Date(d1), new Date(d2));
  });

  // Reverse the array for the order we actually want
  // return sortedTimelineEvents.reverse();
  if (timelineEvents[0].appealType === 'LegacyAppeal') {
    if (timelineEvents[0].assigneeName === '57' || timelineEvents[0].assigneeName === 'CASEFLOW') {
      return sortedTimelineEvents.reverse();
    }
  }

  return sortedTimelineEvents;
};

export const regionalOfficeCity = (objWithLocation, defaultToUnknown) => {
  return _.get(
    objWithLocation,
    'closestRegionalOffice.location_hash.city',
    defaultToUnknown ? COPY.UNKNOWN_REGIONAL_OFFICE : defaultToUnknown
  );
};

export const cityForRegionalOfficeCode = (code) => {
  const regionalOffice = REGIONAL_OFFICE_INFORMATION[code];

  return regionalOffice ? regionalOffice.city : COPY.UNKNOWN_REGIONAL_OFFICE;
};

export const hasDASRecord = (task, requireDasRecord) => {
  return task.appeal.isLegacyAppeal && requireDasRecord ?
    Boolean(task.taskId) :
    true;
};

export const collapseColumn = (requireDasRecord) => (task) =>
  hasDASRecord(task, requireDasRecord) ? 1 : 0;

/**
 * Method to determine whether to apply styling to the Current Assignee (location)
 * @param {object} appeal -- The appeal for which to determine the location
 * @param {number} userId -- The ID of the current user for showing "Assigned to You" cases
 * @returns {string} -- The value of the current location either as a string or JSX
 */
export const labelForLocation = (appeal, userId) => {
  // If there is no location or the appeal is cancelled, don't show a location
  if (
    !appeal.assignedToLocation ||
    ['cancelled', 'docket_switched'].includes(appeal.status)
  ) {
    return '';
  }

  // REGEX to determine the current user
  const regex = new RegExp(
    `\\b(?:BVA|VACO|VHAISA)?${appeal.assignedToLocation}\\b`
  );

  // Override label and apply styling to the current user
  if (userId.match(regex) !== null) {
    return (
      <span
        {...css({
          color: COLORS.GREEN,
        })}
      >
        {COPY.CASE_LIST_TABLE_ASSIGNEE_IS_CURRENT_USER_LABEL}
      </span>
    );
  }

  // Default return just the assigned location value
  return appeal.assignedToLocation;
};

/**
 * Method to optionally apply styling to the status column
 * @param {object} appeal -- The appeal for which to determine the status
 * @returns {string} -- The value of the current location either as a string or JSX
 */
export const statusLabel = (appeal) => {
  switch (appeal.status) {
  case 'cancelled':
    return (
      <span {...css({ color: COLORS.RED })}>{capitalize(appeal.status)}</span>
    );
  case 'docket_switched':
    return COPY.CASE_LIST_TABLE_DOCKET_SWITCH_LABEL;
  default:
    return appeal.status ?
      StringUtil.snakeCaseToCapitalized(appeal.status) :
      '';
  }
};

const getMostRecentChildTask = (parentTask, tasks) => {
  // Ignores LegacyTasks as they're only ever the children of RootTasks.
  const amaTasks = tasks.filter((task) => !task.is_legacy);

  // Sorts tasks by ID in descending order
  const sortedTasks = amaTasks.sort((task_a, task_b) => {
    return (parseInt(task_a.taskId, 10) > parseInt(task_b.taskId, 10)) ? -1 : 1;
  });

  return sortedTasks.find((task) => {
    // The taskId value is a string while parentId is an integer..
    return task.parentId === parseInt(parentTask.taskId, 10);
  });
};

export const getPreviousTaskInstructions = (parentTask, tasks) => {
  let reviewNotes = null;

  const childTask = getMostRecentChildTask(parentTask, tasks);

  if (childTask && childTask.instructions.length > 1) {
    switch (childTask.assignedTo.type) {
    case 'VhaProgramOffice':
      reviewNotes = 'Program Office';
      break;
    case 'VhaRegionalOffice':
      reviewNotes = 'VISN';
      break;
    case 'VhaCamo':
      reviewNotes = 'CAMO';
      break;
    case 'EducationRpo':
      reviewNotes = 'Regional Processing Office';
      break;
    default:
      break;
    }
  }

  const previousInstructions = reviewNotes ? childTask.instructions.slice(-1)[0] : null;

  return { reviewNotes, previousInstructions };
};

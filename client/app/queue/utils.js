/* eslint-disable max-lines */
import React from 'react';
import _, { escapeRegExp } from 'lodash';
import moment from 'moment';
import StringUtil from '../util/StringUtil';
import {
  redText,
  ISSUE_DISPOSITIONS,
  VACOLS_DISPOSITIONS,
  LEGACY_APPEAL_TYPES
} from './constants';

import ISSUE_INFO from '../../constants/ISSUE_INFO';
import DIAGNOSTIC_CODE_DESCRIPTIONS from '../../constants/DIAGNOSTIC_CODE_DESCRIPTIONS';
import UNDECIDED_VACOLS_DISPOSITIONS_BY_ID from '../../constants/UNDECIDED_VACOLS_DISPOSITIONS_BY_ID';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES';
import TASK_STATUSES from '../../constants/TASK_STATUSES';
import REGIONAL_OFFICE_INFORMATION from '../../constants/REGIONAL_OFFICE_INFORMATION';
import HEARING_DISPOSITION_TYPES from '../../constants/HEARING_DISPOSITION_TYPES';
import COPY from '../../COPY';
import { formatDateStrUtc } from '../util/DateUtil';

/**
 * For legacy attorney checkout flow, filter out already-decided issues. Undecided
 * VACOLS disposition IDs are all numerical (1-9) or S, decided IDs are alphabetical (A-X).
 * Filter out disposition 9 because it is no longer used.
 *
 * @param {Array} issues
 * @returns {Array}
 */

export const getUndecidedIssues = (issues) => _.filter(issues, (issue) => {
  if (!issue.disposition) {
    return true;
  }

  if (issue.disposition && issue.disposition in UNDECIDED_VACOLS_DISPOSITIONS_BY_ID) {
    return true;
  }
});

export const mostRecentHeldHearingForAppeal = (appeal) => {
  const hearings = appeal.hearings.
    filter((hearing) => hearing.disposition === HEARING_DISPOSITION_TYPES.held).
    sort((h1, h2) => h1.date < h2.date ? 1 : -1);

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
      scheduledForIsPast: hearing.scheduled_for_is_past
    }
  };
};

const taskAttributesFromRawTask = (task) => {
  const decisionPreparedBy = task.attributes.decision_prepared_by.first_name ? {
    firstName: task.attributes.decision_prepared_by.first_name,
    lastName: task.attributes.decision_prepared_by.last_name
  } : null;

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
    assigneeName: task.attributes.assignee_name,
    assignedTo: {
      cssId: task.attributes.assigned_to.css_id,
      name: task.attributes.assigned_to.name,
      id: task.attributes.assigned_to.id,
      isOrganization: task.attributes.assigned_to.is_organization,
      type: task.attributes.assigned_to.type
    },
    assignedBy: {
      firstName: task.attributes.assigned_by.first_name,
      lastName: task.attributes.assigned_by.last_name,
      cssId: task.attributes.assigned_by.css_id,
      pgId: task.attributes.assigned_by.pg_id
    },
    taskId: task.id,
    label: task.attributes.label,
    documentId: task.attributes.document_id,
    externalHearingId: task.attributes.external_hearing_id,
    workProduct: null,
    previousTaskAssignedOn: task.attributes.previous_task.assigned_at,
    placedOnHoldAt: task.attributes.placed_on_hold_at,
    status: task.attributes.status,
    onHoldDuration: task.attributes.on_hold_duration,
    instructions: task.attributes.instructions,
    decisionPreparedBy,
    availableActions: task.attributes.available_actions,
    caseReviewId: task.attributes.attorney_case_review_id,
    timelineTitle: task.attributes.timeline_title,
    hideFromQueueTableView: task.attributes.hide_from_queue_table_view,
    hideFromTaskSnapshot: task.attributes.hide_from_task_snapshot,
    hideFromCaseTimeline: task.attributes.hide_from_case_timeline,
    availableHearingLocations: task.attributes.available_hearing_locations,
    suggestedHearingLocation: task.attributes.suggested_hearing_location
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
  issueCount: task.attributes.issue_count,
  docketNumber: task.attributes.docket_number,
  veteranFullName: task.attributes.veteran_full_name,
  veteranFileNumber: task.attributes.veteran_file_number,
  isPaperCase: task.attributes.paper_case
});

const extractAppealsFromTasks =
  (tasks) => {
    return tasks.reduce((accumulator, task) => {
      if (!accumulator[task.attributes.external_appeal_id]) {
        accumulator[task.attributes.external_appeal_id] = appealAttributesFromRawTask(task);
      }

      return accumulator;
    }, {});
  };

export const extractAppealsAndAmaTasks =
(tasks) => ({
  tasks: {},
  appeals: extractAppealsFromTasks(tasks),
  amaTasks: prepareTasksForStore(tasks) });

export const tasksWithAppealsFromRawTasks = (tasks) => tasks.map((task) => ({
  ...taskAttributesFromRawTask(task),
  appeal: appealAttributesFromRawTask(task)
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
      assignedTo: {
        cssId: task.attributes.assigned_to.css_id,
        isOrganization: task.attributes.assigned_to.is_organization,
        id: task.attributes.assigned_to.id,
        type: task.attributes.assigned_to.type,
        name: task.attributes.assigned_to.name
      },
      assignedBy: {
        firstName: task.attributes.assigned_by.first_name,
        lastName: task.attributes.assigned_by.last_name,
        cssId: task.attributes.assigned_by.css_id,
        pgId: task.attributes.assigned_by.pg_id
      },
      addedByName: task.attributes.added_by_name,
      addedByCssId: task.attributes.added_by_css_id,
      taskId: task.attributes.task_id,
      label: task.attributes.label,
      documentId: task.attributes.document_id,
      workProduct: task.attributes.work_product,
      previousTaskAssignedOn: task.attributes.previous_task.assigned_on,
      status: task.attributes.status,
      decisionPreparedBy: null,
      availableActions: task.attributes.available_actions,
      timelineTitle: task.attributes.timeline_title,
      hideFromQueueTableView: task.attributes.hide_from_queue_table_view,
      hideFromTaskSnapshot: task.attributes.hide_from_task_snapshot,
      hideFromCaseTimeline: task.attributes.hide_from_case_timeline
    };
  });

  return _.pickBy(_.keyBy(mappedLegacyTasks, (task) => task.uniqueId), (task) => task);
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
    tasks: prepareLegacyTasksForStore(legacyTasks)
  };
};

export const associateTasksWithAppeals =
  (serverData) => {
    const {
      tasks: { data: tasks }
    } = serverData;

    return {
      tasks: prepareLegacyTasksForStore(tasks),
      appeals: extractAppealsFromTasks(tasks)
    };
  };

export const prepareAppealIssuesForStore = (appeal) => {
  // Give even legacy issues an 'id' property, because other issues will have it,
  // so we can refer to this property and phase out use of vacols_sequence_id.
  let issues = appeal.attributes.issues;

  if (appeal.attributes.docket_name === 'legacy') {
    issues = issues.map((issue) => ({
      id: issue.vacols_sequence_id,
      ...issue
    }));
  }

  return issues;
};

export const prepareAppealHearingsForStore = (appeal) => appeal.attributes.hearings.
  map((hearing) => ({
    heldBy: hearing.held_by,
    viewedByJudge: hearing.viewed_by_judge,
    date: hearing.date,
    type: hearing.type,
    externalId: hearing.external_id,
    disposition: hearing.disposition,
    isVirtual: hearing.is_virtual
  }));

const prepareAppealAvailableHearingLocationsForStore = (appeal) => appeal.attributes.
  available_hearing_locations.map((ahl) => ({
    name: ahl.name,
    address: ahl.address,
    city: ahl.city,
    state: ahl.state,
    distance: ahl.distance,
    facilityId: ahl.facility_id,
    facilityType: ahl.facility_type,
    classification: ahl.classification,
    zipCode: ahl.zip_code
  }));

export const prepareAppealForStore =
  (appeals) => {

    const appealHash = appeals.reduce((accumulator, appeal) => {
      const {
        attributes: { issues }
      } = appeal;

      accumulator[appeal.attributes.external_id] = {
        id: appeal.id,
        externalId: appeal.attributes.external_id,
        docketName: appeal.attributes.docket_name,
        withdrawn: appeal.attributes.withdrawn,
        removed: appeal.attributes.removed,
        withdrawalDate: formatDateStrUtc(appeal.attributes.withdrawal_date),
        isLegacyAppeal: appeal.attributes.docket_name === 'legacy',
        caseType: appeal.attributes.type,
        isAdvancedOnDocket: appeal.attributes.aod,
        issueCount: (appeal.attributes.docket_name === 'legacy' ? getUndecidedIssues(issues) : issues).length,
        docketNumber: appeal.attributes.docket_number,
        assignedAttorney: appeal.attributes.assigned_attorney,
        assignedJudge: appeal.attributes.assigned_judge,
        veteranFullName: appeal.attributes.veteran_full_name,
        veteranFileNumber: appeal.attributes.veteran_file_number,
        isPaperCase: appeal.attributes.paper_case,
        sanitizedHearingRequestType: appeal.attributes.sanitized_hearing_request_type,
        vacateType: appeal.attributes.vacate_type
      };

      return accumulator;
    }, {});

    const appealDetailsHash = appeals.reduce((accumulator, appeal) => {
      accumulator[appeal.attributes.external_id] = {
        hearings: prepareAppealHearingsForStore(appeal),
        completedHearingOnPreviousAppeal: appeal.attributes['completed_hearing_on_previous_appeal?'],
        issues: prepareAppealIssuesForStore(appeal),
        decisionIssues: appeal.attributes.decision_issues,
        canEditRequestIssues: appeal.attributes.can_edit_request_issues,
        appellantIsNotVeteran: appeal.attributes.appellant_is_not_veteran,
        appellantFullName: appeal.attributes.appellant_full_name,
        appellantAddress: appeal.attributes.appellant_address,
        appellantRelationship: appeal.attributes.appellant_relationship,
        assignedToLocation: appeal.attributes.assigned_to_location,
        veteranDateOfBirth: appeal.attributes.veteran_date_of_birth,
        veteranDateOfDeath: appeal.attributes.veteran_date_of_death,
        veteranGender: appeal.attributes.veteran_gender,
        veteranAddress: appeal.attributes.veteran_address,
        closestRegionalOffice: appeal.attributes.closest_regional_office,
        availableHearingLocations: prepareAppealAvailableHearingLocationsForStore(appeal),
        externalId: appeal.attributes.external_id,
        status: appeal.attributes.status,
        decisionDate: appeal.attributes.decision_date,
        form9Date: appeal.attributes.form9_date,
        nodDate: appeal.attributes.nod_date,
        certificationDate: appeal.attributes.certification_date,
        powerOfAttorney: appeal.attributes.power_of_attorney,
        regionalOffice: appeal.attributes.regional_office,
        caseflowVeteranId: appeal.attributes.caseflow_veteran_id,
        documentID: appeal.attributes.document_id,
        caseReviewId: appeal.attributes.attorney_case_review_id,
        canEditDocumentId: appeal.attributes.can_edit_document_id,
        attorneyCaseRewriteDetails: appeal.attributes.attorney_case_rewrite_details
      };

      return accumulator;
    }, {});

    return {
      appeals: appealHash,
      appealDetails: appealDetailsHash
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
      editIssuesUrl: claimReview.caseflow_only_edit_issues_url
    };

    return accumulator;
  }, {});

  return {
    claimReviews: claimReviewHash
  };
};

export const renderAppealType = (appeal) => {
  const {
    isAdvancedOnDocket,
    caseType
  } = appeal;
  const cavc = caseType === LEGACY_APPEAL_TYPES.CAVC_REMAND;

  return <React.Fragment>
    {isAdvancedOnDocket && <span><span {...redText}>AOD</span>, </span>}
    {cavc ? <span {...redText}>CAVC</span> : <span>{caseType}</span>}
  </React.Fragment>;
};

export const renderLegacyAppealType = ({ aod, type }) => {
  const cavc = type === 'Court Remand';

  return <React.Fragment>
    {aod && <span><span {...redText}>AOD</span>, </span>}
    {cavc ? <span {...redText}>CAVC</span> : <span>{type}</span>}
  </React.Fragment>;
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
  const {
    program,
    type,
    description
  } = issue;

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
  checkoutFlow, decision, draftDecisionSubmission, issues, args = {}
) => {
  const payload = {
    data: {
      tasks: {
        type: draftDecisionSubmission ? 'AttorneyCaseReview' : 'JudgeCaseReview',
        ...decision.opts
      }
    }
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
        disposition: _.capitalize(issue.disposition)
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
    opts: {
      document_id: documentId,
      work_product: workProduct
    }
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
  if (!newDocsForAppeal[task.externalAppealId] || !newDocsForAppeal[task.externalAppealId].docs) {
    return false;
  }

  return newDocsForAppeal[task.externalAppealId].docs.length > 0;
};

export const taskIsOnHold = (task) => {
  return task.status === TASK_STATUSES.on_hold;
};

export const taskHasCompletedHold = (task) => {
  if (task.onHoldDuration && task.placedOnHoldAt) {
    return moment().startOf('day').
      diff(moment(task.placedOnHoldAt), 'days') >= task.onHoldDuration;
  }

  return false;
};

export const taskIsActive = (task) => ![TASK_STATUSES.completed, TASK_STATUSES.cancelled].includes(task.status);

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

  const relevantAction = task.availableActions.find((action) => endsWith(action.value, path));

  if (relevantAction && relevantAction.data) {
    return relevantAction.data;
  }

  return null;
};

export const nullToFalse = (key, obj) => {
  if (obj[key] === null) {
    obj[key] = false;
  }

  return obj;
};

export const sortTaskList = (taskList) => {
  return taskList.sort((prev, next) => {
    return new Date(next.closedAt || next.createdAt).getTime() -
    new Date(prev.closedAt || prev.createdAt).getTime();
  });
};

export const regionalOfficeCity = (objWithLocation, defaultToUnknown) => {
  return _.get(objWithLocation, 'closestRegionalOffice.location_hash.city',
    defaultToUnknown ? COPY.UNKNOWN_REGIONAL_OFFICE : defaultToUnknown);
};

export const cityForRegionalOfficeCode = (code) => {
  const regionalOffice = REGIONAL_OFFICE_INFORMATION[code];

  return regionalOffice ? regionalOffice.city : COPY.UNKNOWN_REGIONAL_OFFICE;
};

export const hasDASRecord = (task, requireDasRecord) => {
  return (task.appeal.isLegacyAppeal && requireDasRecord) ? Boolean(task.taskId) : true;
};

export const collapseColumn = (requireDasRecord) => (task) => hasDASRecord(task, requireDasRecord) ? 1 : 0;

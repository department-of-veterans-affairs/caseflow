// @flow
import React from 'react';
import _ from 'lodash';
import moment from 'moment';
import StringUtil from '../util/StringUtil';
import {
  redText,
  USER_ROLES
} from './constants';
import type {
  Task,
  Tasks,
  LegacyAppeal,
  LegacyAppeals,
  BasicAppeal,
  BasicAppeals,
  Issue,
  Issues
} from './types/models';
import ISSUE_INFO from '../../constants/ISSUE_INFO.json';
import DIAGNOSTIC_CODE_DESCRIPTIONS from '../../constants/DIAGNOSTIC_CODE_DESCRIPTIONS.json';
import VACOLS_DISPOSITIONS_BY_ID from '../../constants/VACOLS_DISPOSITIONS_BY_ID.json';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES.json';

export const prepareTasksForStore =
  (tasks: Array<Object>):
    Tasks => {
    const mappedLegacyTasks = tasks.map((task) => {
      return {
        type: task.attributes.type,
        title: task.attributes.title,
        appealId: task.attributes.appeal_id,
        appealType: task.attributes.appeal_type,
        externalAppealId: task.attributes.external_appeal_id,
        assignedOn: task.attributes.assigned_on,
        dueOn: task.attributes.due_on,
        userId: task.attributes.user_id,
        assignedToPgId: task.attributes.assigned_to_pg_id,
        addedByName: task.attributes.added_by_name,
        addedByCssId: task.attributes.added_by_css_id,
        taskId: task.attributes.task_id,
        taskType: task.attributes.task_type,
        documentId: task.attributes.document_id,
        assignedByFirstName: task.attributes.assigned_by_first_name,
        assignedByLastName: task.attributes.assigned_by_last_name,
        workProduct: task.attributes.work_product
      };
    });

    return _.pickBy(_.keyBy(mappedLegacyTasks, 'taskId'), (task) => task);
  };

export const associateTasksWithAppeals =
  (serverData: { tasks: { data: Array<Object> } }):
    { appeals: BasicAppeals, tasks: Tasks } => {
    const {
      tasks: { data: tasks }
    } = serverData;

    const appealHash = tasks.reduce((accumulator, task) => {
      if (!accumulator[task.attributes.external_appeal_id]) {
        accumulator[task.attributes.external_appeal_id] = {
          id: task.attributes.appeal_id,
          type: task.attributes.appeal_type,
          externalId: task.attributes.external_appeal_id,
          docketName: task.attributes.docket_name,
          caseType: task.attributes.case_type,
          isAdvancedOnDocket: task.attributes.aod,
          issueCount: task.attributes.issue_count,
          docketNumber: task.attributes.docket_number,
          veteranName: task.attributes.veteran_name,
          veteranFileNumber: task.attributes.veteran_file_number,
          isPaperCase: task.attributes.paper_case
        };
      }

      return accumulator;
    }, {});

    return {
      tasks: prepareTasksForStore(tasks),
      appeals: appealHash
    };
  };

export const prepareAppealDetailsForStore =
  (appeals: Array<LegacyAppeal>):
    LegacyAppeals => {
    return _.pickBy(_.keyBy(appeals, 'attributes.external_id'), (appeal) => appeal);
  };

/*
* Sorting hierarchy:
*  1 AOD vets and CAVC remands
*  2 All other appeals (originals, remands, etc)
*
*  Sort by docket date (form 9 date) oldest to
*  newest within each group
*/
export const sortTasks = ({ tasks = {}, appeals = {} }: {tasks: Tasks, appeals: LegacyAppeals}) => _(tasks).
  partition((task) =>
    appeals[task.appealId].attributes.aod || appeals[task.appealId].attributes.type === 'Court Remand'
  ).
  flatMap((taskList) => _.sortBy(taskList, (task) => new Date(task.attributes.docket_date))).
  value();

export const renderAppealType = (appeal: BasicAppeal) => {
  const {
    isAdvancedOnDocket,
    caseType
  } = appeal;
  const cavc = caseType === 'Court Remand';

  return <React.Fragment>
    {isAdvancedOnDocket && <span><span {...redText}>AOD</span>, </span>}
    {cavc ? <span {...redText}>CAVC</span> : <span>{caseType}</span>}
  </React.Fragment>;
};

export const renderLegacyAppealType = (appeal: LegacyAppeal) => {
  const {
    attributes: {
      aod,
      type
    }
  } = appeal;
  const cavc = type === 'Court Remand';

  return <React.Fragment>
    {aod && <span><span {...redText}>AOD</span>, </span>}
    {cavc ? <span {...redText}>CAVC</span> : <span>{type}</span>}
  </React.Fragment>;
};

export const getDecisionTypeDisplay = (decision: {type?: string} = {}) => {
  const {
    type: decisionType
  } = decision;

  switch (decisionType) {
  case DECISION_TYPES.OMO_REQUEST:
    return 'OMO';
  case DECISION_TYPES.DRAFT_DECISION:
    return 'Draft Decision';
  default:
    return StringUtil.titleCase(decisionType);
  }
};

export const getIssueProgramDescription = (issue: Issue) => _.get(ISSUE_INFO[issue.program], 'description', '');
export const getIssueTypeDescription = (issue: Issue) => {
  const {
    program,
    type
  } = issue;

  console.log(`program: ${program}`); // eslint-disable-line no-console

  return _.get(ISSUE_INFO[program].levels, `${type}.description`);
};

export const getIssueDiagnosticCodeLabel = (code: string) => {
  const readableLabel = DIAGNOSTIC_CODE_DESCRIPTIONS[code];

  if (!readableLabel) {
    return false;
  }

  return `${code} - ${readableLabel.staff_description}`;
};

/**
 * For attorney checkout flow, filter out already-decided issues. Undecided
 * disposition IDs are all numerical (1-9), decided IDs are alphabetical (A-X).
 *
 * @param {Array} issues
 * @returns {Array}
 */
export const getUndecidedIssues = (issues: Issues) => _.filter(issues, (issue) =>
  !issue.disposition || (Number(issue.disposition) && issue.disposition in VACOLS_DISPOSITIONS_BY_ID)
);

export const buildCaseReviewPayload = (
  decision: Object, userRole: string, issues: Issues, args: Object = {}
): Object => {
  const payload = {
    data: {
      tasks: {
        type: `${userRole}CaseReview`,
        ...decision.opts
      }
    }
  };

  if (userRole === USER_ROLES.ATTORNEY) {
    _.extend(payload.data.tasks, { document_type: decision.type });
  } else {
    args.factors_not_considered = _.keys(args.factors_not_considered);
    args.areas_for_improvement = _.keys(args.areas_for_improvement);

    _.extend(payload.data.tasks, args);
  }

  payload.data.tasks.issues = getUndecidedIssues(issues).map((issue) => _.extend({},
    _.pick(issue, ['vacols_sequence_id', 'remand_reasons', 'type', 'readjudication']),
    { disposition: _.capitalize(issue.disposition) }
  ));

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
export const validateWorkProductTypeAndId = (decision: {opts: Object}) => {
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

export const getTaskDaysWaiting = (task: Task) => moment().startOf('day').
  diff(moment(task.assignedOn), 'days');

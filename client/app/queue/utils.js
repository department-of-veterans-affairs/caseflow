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
  Issue,
  Issues
} from './types/models';
import ISSUE_INFO from '../../constants/ISSUE_INFO.json';
import DIAGNOSTIC_CODE_DESCRIPTIONS from '../../constants/DIAGNOSTIC_CODE_DESCRIPTIONS.json';
import VACOLS_DISPOSITIONS_BY_ID from '../../constants/VACOLS_DISPOSITIONS_BY_ID.json';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES.json';

export const associateTasksWithAppeals =
  (serverData: { appeals: { data: Array<LegacyAppeal> }, tasks: Array<void> | { data: Array<Task> } }):
    { appeals: LegacyAppeals, tasks: Tasks } => {
    const {
      appeals: { data: appeals },
      tasks: outerTasks
    } = serverData;

    const result = {
      appeals: {},
      tasks: {}
    };

    for (const appeal of appeals) {
      if (appeal) {
        result.appeals[appeal.attributes.vacols_id] = appeal;
      }
    }
    if (Array.isArray(outerTasks)) {
      return result;
    }

    const tasks = outerTasks.data;

    _.each(tasks, (task) => {
      task.appealId = task.id;
    });

    for (const task of tasks) {
      if (task) {
        result.tasks[task.id] = task;
      }
    }

    return result;
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

export const renderAppealType = ({aod, type}: {aod: boolean, type: string}) => {
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
  diff(moment(task.attributes.assigned_on), 'days');

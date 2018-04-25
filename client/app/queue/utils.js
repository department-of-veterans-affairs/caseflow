import React from 'react';
import _ from 'lodash';
import StringUtil from '../util/StringUtil';
import {
  redText,
  DECISION_TYPES
} from './constants';
import ISSUE_INFO from '../../../constants/ISSUE_INFO.json';
import STAFF_DIAGNOSTIC_CODE_DESCRIPTIONS from '../../../constants/STAFF_DIAGNOSTIC_CODE_DESCRIPTIONS.json';

export const associateTasksWithAppeals = (serverData = {}) => {
  const {
    appeals: { data: appeals },
    tasks: { data: tasks }
  } = serverData;

  // todo: Attorneys currently only have one task per appeal, but future users might have multiple
  _.each(tasks, (task) => {
    task.vacolsId = _(appeals).
      filter((appeal) => appeal.attributes.vacols_id === task.attributes.appeal_id).
      map('attributes.vacols_id').
      head();
  });

  const tasksById = _.keyBy(tasks, 'id');
  const appealsById = _.keyBy(appeals, 'attributes.vacols_id');

  return {
    appeals: appealsById,
    tasks: tasksById
  };
};

/*
* Sorting hierarchy:
*  1 AOD vets and CAVC remands
*  2 All other appeals (originals, remands, etc)
*
*  Sort by docket date (form 9 date) oldest to
*  newest within each group
*/
export const sortTasks = ({ tasks = {}, appeals = {} }) => {
  const partitionedTasks = _.partition(tasks, (task) =>
    appeals[task.vacolsId].attributes.aod || appeals[task.vacolsId].attributes.type === 'Court Remand'
  );

  _.each(partitionedTasks, _.sortBy('attributes.docket_date'));
  _.each(partitionedTasks, _.reverse);

  return _.flatten(partitionedTasks);
};

export const renderAppealType = (appeal) => {
  const {
    attributes: { aod, type }
  } = appeal;
  const cavc = type === 'Court Remand';

  return <React.Fragment>
    {aod && <span><span {...redText}>AOD</span>, </span>}
    {cavc ? <span {...redText}>CAVC</span> : <span>{type}</span>}
  </React.Fragment>;
};

export const getDecisionTypeDisplay = (decision = {}) => {
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

export const getIssueProgramDescription = (issue) => _.get(ISSUE_INFO[issue.program], 'description', '');
export const getIssueTypeDescription = (issue) => {
  const {
    program,
    type
  } = issue;

  return _.get(ISSUE_INFO[program].levels, `${type}.description`);
};

export const getIssueDiagnosticCodeLabel = (code) => {
  const readableLabel = STAFF_DIAGNOSTIC_CODE_DESCRIPTIONS[code];

  if (!readableLabel) {
    return false;
  }

  return `${code} - ${_.capitalize(readableLabel)}`;
};

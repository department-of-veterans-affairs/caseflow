import * as React from 'react';

import COPY from '../../../COPY';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';

export const claimantColumn = () => {
  return {
    header: COPY.CASE_LIST_TABLE_TASK_CLAIMANT_NAME_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.CLAIMANT_NAME.name,
    backendCanSort: true,
    valueFunction: (task) => {
      return <a href={`/decision_reviews/${task.businessLine}/tasks/${task.id}`}>{task.claimant.name}</a>;
    },
    getSortValue: (task) => task.claimant.name
  };
};

export const veteranParticipantIdColumn = () => {
  return {
    header: COPY.CASE_LIST_TABLE_TASK_VETERAN_PARTICIPANT_ID_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.VETERAN_PARTICIPANT_ID.name,
    backendCanSort: true,
    valueFunction: (task) => task.veteranParticipantId,
    getSortValue: (task) => task.veteranParticipantId
  };
};

export const veteranSsnColumn = () => {
  return {
    header: COPY.CASE_LIST_TABLE_TASK_VETERAN_SSN_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.VETERAN_SSN.name,
    backendCanSort: true,
    valueFunction: (task) => task.veteranSSN,
    getSortValue: (task) => task.veteranSSN
  };
};

export const decisionReviewTypeColumn = (tasks) => {
  return {
    header: 'Type',
    name: 'type',
    align: 'left',
    valueFunction: (task) => task.type,
    label: 'Filter by type',
    valueName: 'type',
    enableFilter: true,
    tableData: tasks,
    columnName: 'type',
    anyFiltersAreSet: true,
    order: -2
  };
};

export const customIssueTypesColumn = (tasks, filterOptions = []) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_ISSUE_CATEGORIES_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name,
    backendCanSort: true,
    enableFilter: true,
    anyFiltersAreSet: true,
    filterOptions,
    order: 1,
    label: 'Filter by issue type',
    columnName: 'issueTypesColumn',
    valueName: 'issueTypesColumn',
    tableData: tasks,
    valueFunction: (task) => {
      const commaDelimitedIssueTypes = task.appeal.issueTypes;

      // Remove duplicates from the comma delimited list of issues
      const uniqueIssueTypes = [...new Set(commaDelimitedIssueTypes?.split(','))];

      // return uniqueIssueTypes.map((type) => (<span> {type} <br /> </span>));

      // return uniqueIssueTypes.map((type) => (<p key={type}> {type} </p>));

      // TODO: Might change this to be something other than p tags.
      return uniqueIssueTypes.length > 1 ?
        uniqueIssueTypes.map((type) => (<p key={type}> {type} </p>)) :
        uniqueIssueTypes[0];

      // return uniqueIssueTypes.join(',');
    },
    getSortValue: (task) => task.appeal.issueTypes
  };
};

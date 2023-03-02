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
    order: -1
  };
};

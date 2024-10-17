import * as React from 'react';

import COPY from '../../../COPY';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';
import { DateString } from '../../util/DateUtil';

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

export const pendingIssueModificationColumn = () => {
  return {
    header: COPY.CASE_LIST_TABLE_TASK_PENDING_REQUESTS_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.PENDING_ISSUE_MODIFICATION_COUNT.name,
    valueFunction: (task) => task.appeal.pendingIssueModificationCount,
    backendCanSort: true,
    getSortValue: (task) => task.appeal.pendingIssueModificationCount
  };
};

export const vhaTaskCompletedDateColumn = () => {
  return {
    header: COPY.CASE_LIST_TABLE_COMPLETED_ON_DATE_COLUMN_TITLE,
    name: 'completedOnDateColumn',
    valueFunction: (task) => task.closedAt ? <DateString date={task.closedAt} /> : null,
    backendCanSort: true,
    enableFilter: true,
    anyFiltersAreSet: true,
    filterType: 'date-picker',
    filterSettings: {
      buttons: false,
      position: 'right',
      options: 'additional'
    },
    columnName: 'closedAt',
    valueName: 'Date Completed',
    label: 'Date Completed',
    getSortValue: (task) => task.closedAt ? new Date(task.closedAt) : null
  };
};

import * as React from 'react';
import moment from 'moment';
import pluralize from 'pluralize';

import { css } from 'glamor';

import ContinuousProgressBar from 'app/components/ContinuousProgressBar';
import IhpDaysWaitingTooltip from 'app/queue/components/IhpDaysWaitingTooltip';

import { taskHasCompletedHold, hasDASRecord, collapseColumn } from 'app/queue/utils';
import { DateString, daysSinceAssigned, daysSincePlacedOnHold } from '../../util/DateUtil';

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

export const issueCountColumn = (requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_TASK_ISSUE_COUNT_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
    valueFunction: (task) => hasDASRecord(task, requireDasRecord) ? task.appeal.issueCount : null,
    span: collapseColumn(requireDasRecord),
    backendCanSort: true,
    getSortValue: (task) => hasDASRecord(task, requireDasRecord) ? task.appeal.issueCount : null
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

export const daysWaitingColumn = (requireDasRecord) => {
  const daysWaitingStyle = css({ display: 'inline-block' });

  return {
    header: COPY.CASE_LIST_TABLE_TASK_DAYS_WAITING_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
    span: collapseColumn(requireDasRecord),
    tooltip: <React.Fragment>Calendar days since <br /> this case was assigned</React.Fragment>,
    valueFunction: (task) => {
      const assignedDays = daysSinceAssigned(task);
      const onHoldDays = daysSincePlacedOnHold(task);

      return <IhpDaysWaitingTooltip {...task.latestInformalHearingPresentationTask} taskId={task.uniqueId}>
        <div className={daysWaitingStyle}>
          <span className={taskHasCompletedHold(task) ? 'cf-red-text' : ''}>
            {assignedDays} {pluralize('day', assignedDays)}
          </span>
          { taskHasCompletedHold(task) &&
          <ContinuousProgressBar level={onHoldDays} limit={task.onHoldDuration} warning /> }
        </div>
      </IhpDaysWaitingTooltip>;
    },
    backendCanSort: true,
    getSortValue: (task) => moment().startOf('day').
      diff(moment(task.assignedOn), 'days')
  };
};

export const taskCompletedDateColumn = () => {
  return {
    header: COPY.CASE_LIST_TABLE_COMPLETED_ON_DATE_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name,
    valueFunction: (task) => task.closedAt ? <DateString date={task.closedAt} /> : null,
    backendCanSort: true,
    getSortValue: (task) => task.closedAt ? new Date(task.closedAt) : null
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

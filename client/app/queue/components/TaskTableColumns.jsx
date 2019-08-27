import React from 'react';
import _ from 'lodash';
import moment from 'moment';

import {
  CATEGORIES,
  redText,
  LEGACY_APPEAL_TYPES,
  DOCKET_NAME_FILTERS
} from '../constants';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG.json';
import COPY from '../../../COPY.json';

import DocketTypeBadge from '../../components/DocketTypeBadge';
import HearingBadge from './HearingBadge';
import OnHoldLabel, { numDaysOnHold } from './OnHoldLabel';
import ReaderLink from '../ReaderLink';
import CaseDetailsLink from '../CaseDetailsLink';
import ContinuousProgressBar from '../../components/ContinuousProgressBar';

import { renderAppealType, taskHasCompletedHold, actionNameOfTask, regionalOfficeCity } from '../utils';

import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';

export const claimantColumn = () => {
  return {
    header: 'Claimant',
    valueFunction: (task) => {
      return <a href={`/decision_reviews/${task.business_line}/tasks/${task.id}`}>{task.claimant.name}</a>;
    },
    getSortValue: (task) => task.claimant.name
  };
};

export const veteranParticipantIdColumn = () => {
  return {
    header: 'Veteran Participant Id',
    valueFunction: (task) => task.veteranParticipantId,
    getSortValue: (task) => task.veteranParticipantId
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

export const taskColumn = (tasks) => {
  return {
    header: COPY.CASE_LIST_TABLE_TASKS_COLUMN_TITLE,
    name: QUEUE_CONFIG.TASK_TYPE_COLUMN,
    enableFilter: true,
    tableData: tasks,
    columnName: 'label',
    anyFiltersAreSet: true,
    customFilterLabels: CO_LOCATED_ADMIN_ACTIONS,
    label: 'Filter by task',
    valueName: 'label',
    valueFunction: (task) => actionNameOfTask(task),
    backendCanSort: true,
    getSortValue: (task) => actionNameOfTask(task)
  };
};

export const regionalOfficeColumn = (tasks) => {
  return {
    header: COPY.CASE_LIST_TABLE_REGIONAL_OFFICE_COLUMN_TITLE,
    name: QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN,
    enableFilter: true,
    tableData: tasks,
    columnName: 'closestRegionalOffice.location_hash.city',
    anyFiltersAreSet: true,
    label: 'Filter by regional office',
    backendCanSort: true,
    valueFunction: (task) => {
      return regionalOfficeCity(task, true);
    },
    getSortValue: (task) => regionalOfficeCity(task)
  };
};

export const hearingBadgeColumn = () => {
  return {
    header: '',
    name: QUEUE_CONFIG.HEARING_BADGE_COLUMN,
    valueFunction: (task) => <HearingBadge task={task} />
  };
};

const hasDASRecord = (task, requireDasRecord) => {
  return (task.appeal.isLegacyAppeal && requireDasRecord) ? Boolean(task.taskId) : true;
};
const collapseColumn = (requireDasRecord) => (task) => hasDASRecord(task, requireDasRecord) ? 1 : 0;

export const detailsColumn = (tasks, requireDasRecord, userRole) => {
  return {
    header: COPY.CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE,
    name: QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
    valueFunction: (task) => <CaseDetailsLink
      task={task}
      appeal={task.appeal}
      userRole={userRole}
      disabled={!hasDASRecord(task, requireDasRecord)} />,
    backendCanSort: true,
    getSortValue: (task) => {
      const vetName = task.appeal.veteranFullName.split(' ');
      // only take last, first names. ignore middle names/initials

      return `${_.last(vetName)} ${vetName[0]}`;
    }
  };
};

export const docketNumberColumn = (tasks, requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
    name: QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
    enableFilter: true,
    tableData: tasks,
    columnName: 'appeal.docketName',
    customFilterLabels: DOCKET_NAME_FILTERS,
    anyFiltersAreSet: true,
    label: 'Filter by docket name',
    valueName: 'docketName',
    backendCanSort: true,
    valueFunction: (task) => {
      if (!hasDASRecord(task, requireDasRecord)) {
        return null;
      }

      return <React.Fragment>
        <DocketTypeBadge name={task.appeal.docketName} number={task.appeal.docketNumber} />
        <span>{task.appeal.docketNumber}</span>
      </React.Fragment>;
    },
    span: collapseColumn(requireDasRecord),
    getSortValue: (task) => {
      if (!hasDASRecord(task, requireDasRecord)) {
        return null;
      }

      return `${task.appeal.docketName || ''} ${task.appeal.docketNumber}`;
    }
  };
};

export const typeColumn = (tasks, requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE,
    name: QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
    enableFilter: true,
    tableData: tasks,
    columnName: 'appeal.caseType',
    anyFiltersAreSet: true,
    label: 'Filter by type',
    valueName: 'caseType',
    valueFunction: (task) => hasDASRecord(task, requireDasRecord) ?
      renderAppealType(task.appeal) :
      <span {...redText}>{COPY.ATTORNEY_QUEUE_TABLE_TASK_NEEDS_ASSIGNMENT_ERROR_MESSAGE}</span>,
    span: (task) => hasDASRecord(task, requireDasRecord) ? 1 : 5,
    getSortValue: (task) => {
      // We append a * before the docket number if it's a priority case since * comes before
      // numbers in sort order, this forces these cases to the top of the sort.
      if (task.appeal.isAdvancedOnDocket || task.appeal.caseType === LEGACY_APPEAL_TYPES.CAVC_REMAND) {
        return `*${task.appeal.docketNumber}`;
      }

      return task.appeal.docketNumber;
    }
  };
};

export const issueCountColumn = (requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_ISSUE_COUNT_COLUMN_TITLE,
    name: QUEUE_CONFIG.ISSUE_COUNT_COLUMN,
    valueFunction: (task) => hasDASRecord(task, requireDasRecord) ? task.appeal.issueCount : null,
    span: collapseColumn(requireDasRecord),
    backendCanSort: true,
    getSortValue: (task) => hasDASRecord(task, requireDasRecord) ? task.appeal.issueCount : null
  };
};

export const assignedToColumn = (tasks) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_LOCATION_COLUMN_TITLE,
    name: QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN,
    enableFilter: true,
    tableData: tasks,
    columnName: 'assignedTo.name',
    anyFiltersAreSet: true,
    label: 'Filter by assignee',
    valueFunction: (task) => task.assignedTo.name,
    getSortValue: (task) => task.assignedTo.name
  };
};

export const daysWaitingColumn = (requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_TASK_DAYS_WAITING_COLUMN_TITLE,
    name: QUEUE_CONFIG.DAYS_WAITING_COLUMN,
    span: collapseColumn(requireDasRecord),
    tooltip: <React.Fragment>Calendar days since <br /> this case was assigned</React.Fragment>,
    align: 'center',
    valueFunction: (task) => {
      return <React.Fragment>
        <span className={taskHasCompletedHold(task) ? 'cf-red-text' : ''}>{moment().startOf('day').
          diff(moment(task.assignedOn), 'days')}</span>
        {taskHasCompletedHold(task) ? <ContinuousProgressBar level={moment().startOf('day').
          diff(task.placedOnHoldAt, 'days')} limit={task.onHoldDuration} warning /> : null}
      </React.Fragment>;
    },
    backendCanSort: true,
    getSortValue: (task) => moment().startOf('day').
      diff(moment(task.assignedOn), 'days')
  };
};

export const daysOnHoldColumn = (requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE,
    name: QUEUE_CONFIG.TASK_HOLD_LENGTH_COLUMN,
    span: collapseColumn(requireDasRecord),
    tooltip: <React.Fragment>Calendar days since <br /> this case was placed on hold</React.Fragment>,
    align: 'center',
    valueFunction: (task) => {
      return <React.Fragment>
        <OnHoldLabel task={task} />
        <ContinuousProgressBar limit={task.onHoldDuration} level={moment().startOf('day').
          diff(task.placedOnHoldAt, 'days')} />
      </React.Fragment>;
    },
    backendCanSort: true,
    getSortValue: (task) => numDaysOnHold(task)
  };
};

export const readerLinkColumn = (requireDasRecord, includeNewDocsIcon) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE,
    name: QUEUE_CONFIG.DOCUMENT_COUNT_READER_LINK_COLUMN,
    span: collapseColumn(requireDasRecord),
    valueFunction: (task) => {
      if (!hasDASRecord(task, requireDasRecord)) {
        return null;
      }

      return <ReaderLink appealId={task.externalAppealId}
        analyticsSource={CATEGORIES.QUEUE_TABLE}
        redirectUrl={window.location.pathname}
        appeal={task.appeal}
        newDocsIcon={includeNewDocsIcon}
        task={task}
        docCountBelowLink />;
    }
  };
};

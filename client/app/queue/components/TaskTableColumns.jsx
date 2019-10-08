import * as React from 'react';
import moment from 'moment';
import _ from 'lodash';

import DocketTypeBadge from '../../components/DocketTypeBadge';
import HearingBadge from './HearingBadge';
import CaseDetailsLink from '../CaseDetailsLink';
import ReaderLink from '../ReaderLink';
import ContinuousProgressBar from '../../components/ContinuousProgressBar';
import OnHoldLabel, { numDaysOnHold } from './OnHoldLabel';

import { taskHasCompletedHold, hasDASRecord, collapseColumn, actionNameOfTask, regionalOfficeCity,
  renderAppealType } from '../utils';

import COPY from '../../../COPY.json';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG.json';
import DOCKET_NAME_FILTERS from '../../../constants/DOCKET_NAME_FILTERS.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';

import {
  CATEGORIES,
  redText
} from '../constants';

export const docketNumberColumn = (tasks, filterOptions, requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
    name: QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
    enableFilter: true,
    tableData: tasks,
    columnName: 'appeal.docketName',
    customFilterLabels: DOCKET_NAME_FILTERS,
    filterOptions,
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

export const hearingBadgeColumn = () => {
  return {
    header: '',
    name: QUEUE_CONFIG.HEARING_BADGE_COLUMN,
    valueFunction: (task) => <HearingBadge task={task} />
  };
};

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

export const taskColumn = (tasks, filterOptions) => {
  return {
    header: COPY.CASE_LIST_TABLE_TASKS_COLUMN_TITLE,
    name: QUEUE_CONFIG.TASK_TYPE_COLUMN,
    enableFilter: true,
    tableData: tasks,
    columnName: 'label',
    anyFiltersAreSet: true,
    customFilterLabels: CO_LOCATED_ADMIN_ACTIONS,
    filterOptions,
    label: 'Filter by task',
    valueName: 'label',
    valueFunction: (task) => actionNameOfTask(task),
    backendCanSort: true,
    getSortValue: (task) => actionNameOfTask(task)
  };
};

export const regionalOfficeColumn = (tasks, filterOptions) => {
  return {
    header: COPY.CASE_LIST_TABLE_REGIONAL_OFFICE_COLUMN_TITLE,
    name: QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN,
    enableFilter: true,
    tableData: tasks,
    columnName: 'closestRegionalOffice.location_hash.city',
    anyFiltersAreSet: true,
    filterOptions,
    label: 'Filter by regional office',
    backendCanSort: true,
    valueFunction: (task) => {
      return regionalOfficeCity(task, true);
    },
    getSortValue: (task) => regionalOfficeCity(task)
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

export const typeColumn = (tasks, filterOptions, requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE,
    name: QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
    enableFilter: true,
    tableData: tasks,
    columnName: 'appeal.caseType',
    backendCanSort: true,
    anyFiltersAreSet: true,
    filterOptions,
    label: 'Filter by type',
    valueName: 'caseType',
    valueFunction: (task) => hasDASRecord(task, requireDasRecord) ?
      renderAppealType(task.appeal) :
      <span {...redText}>{COPY.ATTORNEY_QUEUE_TABLE_TASK_NEEDS_ASSIGNMENT_ERROR_MESSAGE}</span>,
    span: (task) => hasDASRecord(task, requireDasRecord) ? 1 : 5,
    getSortValue: (task) => {
      const sortString = `${task.appeal.caseType} ${task.appeal.docketNumber}`;

      // We append a * before the docket number if it's a priority case since * comes before
      // numbers in sort order, this forces these cases to the top of the sort.
      return task.appeal.isAdvancedOnDocket ? `*${sortString}` : sortString;
    }
  };
};

export const assignedToColumn = (tasks, filterOptions) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_LOCATION_COLUMN_TITLE,
    name: QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN,
    backendCanSort: true,
    enableFilter: true,
    tableData: tasks,
    columnName: 'assignedTo.name',
    anyFiltersAreSet: true,
    filterOptions,
    label: 'Filter by assignee',
    valueFunction: (task) => task.assignedTo.name,
    getSortValue: (task) => task.assignedTo.name
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
        { taskHasCompletedHold(task) ? <ContinuousProgressBar level={moment().startOf('day').
          diff(task.placedOnHoldAt, 'days')} limit={task.onHoldDuration} warning /> : null }
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

export const completedToNameColumn = () => {
  return {
    header: COPY.CASE_LIST_TABLE_COMPLETED_BACK_TO_NAME_COLUMN_TITLE,
    name: QUEUE_CONFIG.TASK_ASSIGNER_COLUMN,
    backendCanSort: true,
    valueFunction: (task) =>
      task.assignedBy ? `${task.assignedBy.firstName} ${task.assignedBy.lastName}` : null,
    getSortValue: (task) => task.assignedBy ? task.assignedBy.lastName : null
  };
};

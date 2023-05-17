/* eslint-disable max-lines */
import * as React from 'react';
import moment from 'moment';
import pluralize from 'pluralize';
import { isEmpty } from 'lodash';
import { css } from 'glamor';

import DocketTypeBadge from 'app/components/DocketTypeBadge';
import BadgeArea from 'app/components/badges/BadgeArea';
import CaseDetailsLink from '../CaseDetailsLink';
import ReaderLink from '../ReaderLink';
import ContinuousProgressBar from 'app/components/ContinuousProgressBar';
import OnHoldLabel, { numDaysOnHold } from './OnHoldLabel';
import IhpDaysWaitingTooltip from './IhpDaysWaitingTooltip';
import TranscriptionTaskTooltip from './TranscriptionTaskTooltip';

import { taskHasCompletedHold, hasDASRecord, collapseColumn, regionalOfficeCity, renderAppealType } from '../utils';
import { DateString, daysSinceAssigned, daysSincePlacedOnHold } from '../../util/DateUtil';

import COPY from '../../../COPY';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';
import DOCKET_NAME_FILTERS from '../../../constants/DOCKET_NAME_FILTERS';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS';

import {
  CATEGORIES,
  redText
} from '../constants';

export const docketNumberColumn = (tasks, filterOptions, requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name,
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

export const documentIdColumn = () => {
  return {
    header: COPY.CASE_LIST_TABLE_DOCUMENT_ID_COLUMN_TITLE,
    valueFunction: (task) => {
      const preparer = task.decisionPreparedBy || task.assignedBy;

      if (!preparer.firstName) {
        return task.documentId;
      }

      const nameAbbrev = `${preparer.firstName.substring(0, 1)}. ${preparer.lastName}`;

      if ((!task.documentId) || (isEmpty(task.documentId))) {
        return;
      }

      return <React.Fragment>
        {task.documentId}<br />from {nameAbbrev}
      </React.Fragment>;
    }
  };
};

export const badgesColumn = () => {
  return {
    header: '',
    name: QUEUE_CONFIG.COLUMNS.BADGES.name,
    valueFunction: (task) => <BadgeArea task={task} />
  };
};

export const detailsColumn = (tasks, requireDasRecord, userRole) => {
  return {
    header: COPY.CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
    valueFunction: (task) => <CaseDetailsLink
      task={task}
      appeal={task.appeal}
      userRole={userRole}
      disabled={!hasDASRecord(task, requireDasRecord)} />,
    backendCanSort: true,
    getSortValue: (task) => {
      const vetName = task.appeal.veteranFullName.split(' ');
      // only take last, first names. ignore middle names/initials

      return `${vetName[vetName.length - 1]} ${vetName[0]}`;
    }
  };
};

export const boardIntakeColumn = (requireDasRecord) => {
  const boardIntakeStyle = css({ display: 'inline-block' });

  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_BOARD_INTAKE_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.BOARD_INTAKE.name,
    span: collapseColumn(requireDasRecord),
    tooltip: <React.Fragment>Calendar days since <br /> this case was assigned</React.Fragment>,
    align: 'center',
    valueFunction: (task) => {
      const assignedDays = daysSinceAssigned(task);
      const onHoldDays = daysSincePlacedOnHold(task);

      return <IhpDaysWaitingTooltip {...task.latestInformalHearingPresentationTask}>
        <div className={boardIntakeStyle}>
          <span className={taskHasCompletedHold(task) ? 'cf-red-text' : ''}>
            {assignedDays} {pluralize('day', assignedDays)} ago
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

export const lastActionColumn = (requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_LAST_ACTION_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.LAST_ACTION.name,
    span: collapseColumn(requireDasRecord),
    tooltip: <React.Fragment>Calendar days since <br /> this case's status last changed</React.Fragment>,
    align: 'center',
    valueFunction: (task) => `${task.daysSinceLastStatusChange} days ago`,
    backendCanSort: true,
    getSortValue: (task) => numDaysOnHold(task)
  };
};

export const taskOwnerColumn = (tasks, filterOptions) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_TASK_OWNER_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.TASK_OWNER.name,
    tableData: tasks,
    columnName: 'label',
    customFilterLabels: CO_LOCATED_ADMIN_ACTIONS,
    filterOptions,
    label: 'Filter by owner',
    valueName: 'label',
    valueFunction: (task) => task.ownedBy,
    getSortValue: (task) => task.label
  };
};

export const vamcOwnerColumn = (tasks, filterOptions) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_VAMC_OWNER_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.VAMC_OWNER.name,
    tableData: tasks,
    columnName: 'label',
    customFilterLabels: CO_LOCATED_ADMIN_ACTIONS,
    filterOptions,
    label: 'Filter by owner',
    valueName: 'label',
    valueFunction: (task) => task.ownedBy,
    getSortValue: (task) => task.label
  };
};

export const taskColumn = (tasks, filterOptions) => {
  return {
    header: COPY.CASE_LIST_TABLE_TASKS_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
    enableFilter: true,
    tableData: tasks,
    columnName: 'label',
    anyFiltersAreSet: true,
    customFilterLabels: CO_LOCATED_ADMIN_ACTIONS,
    filterOptions,
    label: 'Filter by task',
    valueName: 'label',
    valueFunction: (task) => {
      if (task.label !== QUEUE_CONFIG.TRANSCRIPTION_TASK_LABEL) {
        return task.label;
      }

      return <TranscriptionTaskTooltip instructions={task.instructions.join('\n')} taskId={task.uniqueId}>
        <div>
          {task.label}
        </div>
      </TranscriptionTaskTooltip>;
    },
    backendCanSort: true,
    getSortValue: (task) => task.label
  };
};

export const assignedByColumn = () => {
  return {
    header: COPY.CASE_LIST_TABLE_TASK_ASSIGNED_BY_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.TASK_ASSIGNED_BY.name,
    backendCanSort: true,
    valueFunction: (task) =>
      task.assignedBy ? `${task.assignedBy.firstName} ${task.assignedBy.lastName}` : null,
    getSortValue: (task) => task.assignedBy ? task.assignedBy.lastName : null
  };
};

export const regionalOfficeColumn = (tasks, filterOptions) => {
  return {
    header: COPY.CASE_LIST_TABLE_REGIONAL_OFFICE_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name,
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
    name: QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
    valueFunction: (task) => hasDASRecord(task, requireDasRecord) ? task.appeal.issueCount : null,
    span: collapseColumn(requireDasRecord),
    backendCanSort: true,
    getSortValue: (task) => hasDASRecord(task, requireDasRecord) ? task.appeal.issueCount : null
  };
};

export const issueTypesColumn = (tasks, filterOptions, requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_ISSUE_CATEGORIES_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name,
    backendCanSort: true,
    enableFilter: true,
    anyFiltersAreSet: true,
    filterOptions,
    tableData: tasks,
    label: 'Filter by issue type',
    columnName: 'appeal.issueTypes',
    valueName: 'Issue Type',
    multiValueDelimiter: ',',
    enableFilterTextTransform: false,
    span: collapseColumn(requireDasRecord),
    valueFunction: (task) => {
      if (!hasDASRecord(task, requireDasRecord)) {
        return null;
      }

      const commaDelimitedIssueTypes = task.appeal.issueTypes;

      // Remove duplicates from the comma delimited list of issue types
      // Also sort the request issue type alphabetically
      const uniqueIssueTypes = [...new Set(commaDelimitedIssueTypes?.split(','))].
        sort((stringA, stringB) => stringA.localeCompare(stringB));

      return uniqueIssueTypes.length > 1 ?
        uniqueIssueTypes.map((type) => (<p key={type}> {type} </p>)) :
        uniqueIssueTypes[0];
    },
    getSortValue: (task) => (
      hasDASRecord(task, requireDasRecord) ? [...new Set(task.appeal.issueTypes?.split(','))].
        sort((stringA, stringB) => stringA.localeCompare(stringB)) : null
    )
  };
};

export const typeColumn = (tasks, filterOptions, requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
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
    name: QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name,
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
    name: QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name,
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

export const readerLinkColumnWithNewDocsIcon = (requireDasRecord) => readerLinkColumn(requireDasRecord, true);

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

export const daysSinceIntakeColumn = (requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_BOARD_INTAKE,
    name: QUEUE_CONFIG.COLUMNS.BOARD_INTAKE.name,
    span: collapseColumn(requireDasRecord),
    tooltip: <React.Fragment>Calendar days since <br /> this case was assigned</React.Fragment>,
    align: 'center',
    valueFunction: (task) => {
      return `${task.daysSinceBoardIntake} days ago`;
    },
    backendCanSort: true,
    getSortValue: (task) => task.daysSinceBoardIntake
  };
};

export const receiptDateColumn = () => {
  return {
    header: COPY.CASE_LIST_TABLE_10182,
    name: QUEUE_CONFIG.COLUMNS.RECEIPT_DATE_INTAKE.name,
    align: 'center',
    valueFunction: (task) => {
      return moment(task.appeal_receipt_date).format('MM/DD/YYYY');
    },
    backendCanSort: true,
    getSortValue: (task) => task.appeal_receipt_date
  };
};

export const daysOnHoldColumn = (requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.TASK_HOLD_LENGTH.name,
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

export const daysSinceLastActionColumn = (requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_LAST_ACTION_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.DAYS_SINCE_LAST_ACTION.name,
    span: collapseColumn(requireDasRecord),
    tooltip: <React.Fragment>Calendar days since <br /> this case's status last changed</React.Fragment>,
    align: 'center',
    valueFunction: (task) => `${task.daysSinceLastStatusChange} days ago`,
    backendCanSort: true,
    getSortValue: (task) => numDaysOnHold(task)
  };
};

export const completedToNameColumn = () => {
  return {
    header: COPY.CASE_LIST_TABLE_COMPLETED_BACK_TO_NAME_COLUMN_TITLE,
    name: QUEUE_CONFIG.COLUMNS.TASK_ASSIGNER.name,
    backendCanSort: true,
    valueFunction: (task) =>
      task.assignedBy ? `${task.assignedBy.firstName} ${task.assignedBy.lastName}` : null,
    getSortValue: (task) => task.assignedBy ? task.assignedBy.lastName : null
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

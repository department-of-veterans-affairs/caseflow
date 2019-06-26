/**
 * Base class for all task tables in Caseflow. Used primarily throughout Queue but also used
 * in a few other places. Task tables can:
 *   - be filtered by column
 *   - be placed inside tabs
 */

import * as React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import moment from 'moment';
import pluralize from 'pluralize';
import { bindActionCreators } from 'redux';

import QueueTable from '../QueueTable';
import Checkbox from '../../components/Checkbox';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import HearingBadge from './HearingBadge';
import OnHoldLabel, { numDaysOnHold } from './OnHoldLabel';
import ReaderLink from '../ReaderLink';
import CaseDetailsLink from '../CaseDetailsLink';
import ContinuousProgressBar from '../../components/ContinuousProgressBar';

import { setSelectionOfTaskOfUser } from '../QueueActions';
import { renderAppealType, taskHasCompletedHold, actionNameOfTask, regionalOfficeCity } from '../utils';
import { DateString } from '../../util/DateUtil';
import {
  CATEGORIES,
  redText,
  LEGACY_APPEAL_TYPES,
  COLUMN_NAMES,
  DOCKET_NAME_FILTERS
} from '../constants';
import COPY from '../../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';

const hasDASRecord = (task, requireDasRecord) => {
  return (task.appeal.isLegacyAppeal && requireDasRecord) ? Boolean(task.taskId) : true;
};

const collapseColumn = (requireDasRecord) => (task) => hasDASRecord(task, requireDasRecord) ? 1 : 0;

export const docketNumberColumn = (tasks, requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
    enableFilter: true,
    tableData: tasks,
    columnName: 'appeal.docketName',
    customFilterLabels: DOCKET_NAME_FILTERS,
    anyFiltersAreSet: true,
    label: 'Filter by docket name',
    valueName: 'docketName',
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
    valueFunction: (task) => <HearingBadge task={task} />
  };
};

export const detailsColumn = (tasks, requireDasRecord, userRole) => {
  return {
    header: COPY.CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE,
    valueFunction: (task) => <CaseDetailsLink
      task={task}
      appeal={task.appeal}
      userRole={userRole}
      disabled={!hasDASRecord(task, requireDasRecord)} />,
    getSortValue: (task) => {
      const vetName = task.appeal.veteranFullName.split(' ');
      // only take last, first names. ignore middle names/initials

      return `${_.last(vetName)} ${vetName[0]}`;
    }
  };
};

export const taskColumn = (tasks) => {
  return {
    header: COPY.CASE_LIST_TABLE_TASKS_COLUMN_TITLE,
    enableFilter: true,
    tableData: tasks,
    columnName: 'label',
    anyFiltersAreSet: true,
    customFilterLabels: CO_LOCATED_ADMIN_ACTIONS,
    label: 'Filter by task',
    valueName: 'label',
    valueFunction: (task) => actionNameOfTask(task),
    getSortValue: (task) => actionNameOfTask(task)
  };
};

export const regionalOfficeColumn = (tasks) => {
  return {
    header: COPY.CASE_LIST_TABLE_REGIONAL_OFFICE_COLUMN_TITLE,
    enableFilter: true,
    tableData: tasks,
    columnName: 'closestRegionalOffice.location_hash.city',
    anyFiltersAreSet: true,
    label: 'Filter by regional office',
    valueFunction: (task) => {
      return regionalOfficeCity(task, true);
    },
    getSortValue: (task) => regionalOfficeCity(task)
  };
};

export const issueCountColumn = (requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_ISSUE_COUNT_COLUMN_TITLE,
    valueFunction: (task) => hasDASRecord(task, requireDasRecord) ? task.appeal.issueCount : null,
    span: collapseColumn(requireDasRecord),
    getSortValue: (task) => hasDASRecord(task, requireDasRecord) ? task.appeal.issueCount : null
  };
};

export const typeColumn = (tasks, requireDasRecord) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE,
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

export const assignedToColumn = (tasks) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_LOCATION_COLUMN_TITLE,
    enableFilter: true,
    tableData: tasks,
    columnName: 'assignedTo.name',
    anyFiltersAreSet: true,
    label: 'Filter by assignee',
    valueFunction: (task) => task.assignedTo.name,
    getSortValue: (task) => task.assignedTo.name
  };
};

export const readerLinkColumn = (requireDasRecord, includeNewDocsIcon) => {
  return {
    header: COPY.CASE_LIST_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE,
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
    getSortValue: (task) => moment().startOf('day').
      diff(moment(task.assignedOn), 'days')
  };
};

export class TaskTableUnconnected extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.uniqueId

  isTaskSelected = (uniqueId) => {
    if (!this.props.isTaskAssignedToUserSelected) {
      return false;
    }

    const isTaskSelected = this.props.isTaskAssignedToUserSelected[this.props.userId] || {};

    return isTaskSelected[uniqueId] || false;
  }

  taskHasDASRecord = (task) => {
    return hasDASRecord(task, this.props.requireDasRecord);
  }

  collapseColumnIfNoDASRecord = (task) => this.taskHasDASRecord(task) ? 1 : 0

  caseHearingColumn = () => {
    return this.props.includeHearingBadge ? hearingBadgeColumn() : null;
  }

  caseSelectColumn = () => {
    return this.props.includeSelect ? {
      header: COPY.CASE_LIST_TABLE_SELECT_COLUMN_TITLE,
      valueFunction: (task) => <Checkbox
        name={task.uniqueId}
        hideLabel
        value={this.isTaskSelected(task.uniqueId)}
        onChange={(selected) => this.props.setSelectionOfTaskOfUser({
          userId: this.props.userId,
          taskId: task.uniqueId,
          selected
        })} />
    } : null;
  }

  caseDetailsColumn = () => {
    return this.props.includeDetailsLink ?
      detailsColumn(this.props.tasks, this.props.requireDasRecord, this.props.userRole) :
      null;
  }

  caseTaskColumn = () => {
    return this.props.includeTask ? taskColumn(this.props.tasks) : null;
  }

  caseDocumentIdColumn = () => {
    return this.props.includeDocumentId ? {
      header: COPY.CASE_LIST_TABLE_DOCUMENT_ID_COLUMN_TITLE,
      valueFunction: (task) => {
        const firstName = task.decisionPreparedBy ? task.decisionPreparedBy.firstName : task.assignedBy.firstName;
        const lastName = task.decisionPreparedBy ? task.decisionPreparedBy.lastName : task.assignedBy.lastName;

        if (!firstName) {
          return task.documentId;
        }

        const nameAbbrev = `${firstName.substring(0, 1)}. ${lastName}`;

        return <React.Fragment>
          {task.documentId}<br />from {nameAbbrev}
        </React.Fragment>;
      }
    } : null;
  }

  caseTypeColumn = () => {
    return this.props.includeType ? typeColumn(this.props.tasks, this.props.requireDasRecord) : null;
  }

  caseAssignedToColumn = () => {
    return this.props.includeAssignedTo ? assignedToColumn(this.props.tasks) : null;
  }

  caseDocketNumberColumn = () => {
    return this.props.includeDocketNumber ? docketNumberColumn(this.props.tasks, this.props.requireDasRecord) : null;
  }

  caseIssueCountColumn = () => {
    return this.props.includeIssueCount ? issueCountColumn(this.props.requireDasRecord) : null;
  }

  caseDueDateColumn = () => {
    return this.props.includeDueDate ? {
      header: COPY.CASE_LIST_TABLE_DAYS_WAITING_COLUMN_TITLE,
      tooltip: <React.Fragment>Calendar days this case <br /> has been assigned to you</React.Fragment>,
      align: 'center',
      valueFunction: (task) => {
        if (!this.taskHasDASRecord(task)) {
          return null;
        }

        const daysWaiting = moment().startOf('day').
          diff(moment(task.assignedOn), 'days');

        return <React.Fragment>
          {daysWaiting} {pluralize('day', daysWaiting)}
        </React.Fragment>;
      },
      span: this.collapseColumnIfNoDASRecord,
      getSortValue: (task) => moment().startOf('day').
        diff(moment(task.assignedOn), 'days')
    } : null;
  }

  caseDaysWaitingColumn = () => {
    return this.props.includeDaysWaiting ? daysWaitingColumn(this.props.requireDasRecord) : null;
  }

  caseDaysOnHoldColumn = () => (this.props.includeDaysOnHold ? {
    header: COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE,
    align: 'center',
    valueFunction: (task) => {
      return <React.Fragment>
        <OnHoldLabel task={task} />
        <ContinuousProgressBar limit={task.onHoldDuration} level={moment().startOf('day').
          diff(task.placedOnHoldAt, 'days')} />
      </React.Fragment>;
    },
    getSortValue: (task) => numDaysOnHold(task)
  } : null)

  completedDateColumn = () => {
    return this.props.includeCompletedDate ? {
      header: COPY.CASE_LIST_TABLE_COMPLETED_ON_DATE_COLUMN_TITLE,
      valueFunction: (task) => task.closedAt ? <DateString date={task.closedAt} /> : null,
      getSortValue: (task) => task.closedAt ? <DateString date={task.closedAt} /> : null
    } : null;
  }

  completedToNameColumn = () => {
    return this.props.includeCompletedToName ? {
      header: COPY.CASE_LIST_TABLE_COMPLETED_BACK_TO_NAME_COLUMN_TITLE,
      valueFunction: (task) =>
        task.assignedBy ? `${task.assignedBy.firstName} ${task.assignedBy.lastName}` : null,
      getSortValue: (task) => task.assignedBy ? task.assignedBy.lastName : null
    } : null;
  }

  caseReaderLinkColumn = () => {
    return !this.props.userIsVsoEmployee && this.props.includeReaderLink ?
      readerLinkColumn(this.props.requireDasRecord, this.props.includeNewDocsIcon) :
      null;
  }

  caseRegionalOfficeColumn = () => {
    return this.props.includeRegionalOffice ? regionalOfficeColumn(this.props.tasks) : null;
  }

  getQueueColumns = () =>
    _.orderBy((this.props.customColumns || []).concat(
      _.compact([
        this.caseHearingColumn(),
        this.caseSelectColumn(),
        this.caseDetailsColumn(),
        this.caseTaskColumn(),
        this.caseRegionalOfficeColumn(),
        this.caseDocumentIdColumn(),
        this.caseTypeColumn(),
        this.caseAssignedToColumn(),
        this.caseDocketNumberColumn(),
        this.caseIssueCountColumn(),
        this.caseDueDateColumn(),
        this.caseDaysWaitingColumn(),
        this.caseDaysOnHoldColumn(),
        this.completedDateColumn(),
        this.completedToNameColumn(),
        this.caseReaderLinkColumn()
      ])), ['order'], ['desc']);

  getDefaultSortableColumn = () => {
    if (this.props.defaultSortIdx) {
      return this.props.defaultSortIdx;
    }

    const index = _.findIndex(this.getQueueColumns(),
      (column) => column.header === COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE);

    if (index >= 0) {
      return index;
    }

    return _.findIndex(this.getQueueColumns(), (column) => column.getSortValue);
  }

  render = () => <QueueTable
    columns={this.getQueueColumns}
    rowObjects={this.props.tasks}
    getKeyForRow={this.props.getKeyForRow || this.getKeyForRow}
    defaultSort={{ sortColIdx: this.getDefaultSortableColumn() }}
    alternateColumnNames={COLUMN_NAMES}
    useTaskPagesApi={this.props.useTaskPagesApi || false}
    casesPerPage={this.props.tasksPerPage}
    numberOfPages={this.props.numberOfPages}
    totalTaskCount={this.props.totalTaskCount}
    taskPagesApiEndpoint={this.props.taskPagesApiEndpoint}
    enablePagination
    rowClassNames={(task) =>
      this.taskHasDASRecord(task) || !this.props.requireDasRecord ? null : 'usa-input-error'} />;
}

const mapStateToProps = (state) => ({
  isTaskAssignedToUserSelected: state.queue.isTaskAssignedToUserSelected,
  userIsVsoEmployee: state.ui.userIsVsoEmployee,
  userRole: state.ui.userRole,
  tasksAssignedByBulk: state.queue.tasksAssignedByBulk,
  organizationId: state.ui.activeOrganization.id
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({ setSelectionOfTaskOfUser }, dispatch)
);

export default (connect(mapStateToProps, mapDispatchToProps)(TaskTableUnconnected));

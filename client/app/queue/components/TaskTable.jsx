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
import PropTypes from 'prop-types';

import QueueTable from '../QueueTable';
import Checkbox from '../../components/Checkbox';
import { docketNumberColumn, badgesColumn, detailsColumn, taskColumn, regionalOfficeColumn, daysWaitingColumn,
  issueCountColumn, typeColumn, assignedToColumn, readerLinkColumn, daysOnHoldColumn, completedToNameColumn,
  taskCompletedDateColumn, documentIdColumn } from './TaskTableColumns';

import { setSelectionOfTaskOfUser } from '../QueueActions';
import { hasDASRecord } from '../utils';
import COPY from '../../../COPY';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';

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

  caseBadgesColumn = () => {
    return this.props.includeBadges ? badgesColumn() : null;
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
    return this.props.includeDocumentId ? documentIdColumn(this.props.tasks) : null;
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
      name: QUEUE_CONFIG.COLUMNS.TASK_DUE_DATE.name,
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
      backendCanSort: true,
      getSortValue: (task) => moment().startOf('day').
        diff(moment(task.assignedOn), 'days')
    } : null;
  }

  caseDaysWaitingColumn = () => {
    return this.props.includeDaysWaiting ? daysWaitingColumn(this.props.requireDasRecord) : null;
  }

  caseDaysOnHoldColumn = () => {
    return this.props.includeDaysOnHold ? daysOnHoldColumn(this.props.requireDasRecord) : null;
  }

  completedDateColumn = () => {
    return this.props.includeCompletedDate ? taskCompletedDateColumn() : null;
  }

  caseCompletedToNameColumn = () => {
    return this.props.includeCompletedToName ? completedToNameColumn() : null;
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
        this.caseBadgesColumn(),
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
        this.caseCompletedToNameColumn(),
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
    columns={this.getQueueColumns()}
    rowObjects={this.props.tasks}
    getKeyForRow={this.props.getKeyForRow || this.getKeyForRow}
    defaultSort={{ sortColIdx: this.getDefaultSortableColumn() }}
    enablePagination
    rowClassNames={(task) =>
      this.taskHasDASRecord(task) || !this.props.requireDasRecord ? null : 'usa-input-error'} />;
}

TaskTableUnconnected.propTypes = {
  isTaskAssignedToUserSelected: PropTypes.object,
  userId: PropTypes.number,
  requireDasRecord: PropTypes.bool,
  includeBadges: PropTypes.bool,
  includeSelect: PropTypes.bool,
  setSelectionOfTaskOfUser: PropTypes.func,
  includeDetailsLink: PropTypes.bool,
  tasks: PropTypes.array,
  userRole: PropTypes.string,
  includeTask: PropTypes.bool,
  includeDocumentId: PropTypes.bool,
  includeType: PropTypes.bool,
  includeAssignedTo: PropTypes.bool,
  includeDocketNumber: PropTypes.bool,
  includeIssueCount: PropTypes.bool,
  includeDueDate: PropTypes.bool,
  includeDaysWaiting: PropTypes.bool,
  includeDaysOnHold: PropTypes.bool,
  includeCompletedDate: PropTypes.bool,
  includeCompletedToName: PropTypes.bool,
  userIsVsoEmployee: PropTypes.bool,
  includeReaderLink: PropTypes.bool,
  includeNewDocsIcon: PropTypes.bool,
  includeRegionalOffice: PropTypes.bool,
  customColumns: PropTypes.array,
  defaultSortIdx: PropTypes.number,
  getKeyForRow: PropTypes.func
};

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

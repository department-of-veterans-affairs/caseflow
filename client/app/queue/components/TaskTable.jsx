/**
 * Base class for all task tables in Caseflow. Used primarily throughout Queue but also used
 * in a few other places. Task tables can:
 *   - be filtered by column
 *   - be placed inside tabs
 */
import * as React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import QueueTable from '../QueueTable';
import Checkbox from '../../components/Checkbox';
import {
  docketNumberColumn,
  badgesColumn,
  detailsColumn,
  daysWaitingColumn,
  issueCountColumn,
  typeColumn,
  readerLinkColumn,
  taskCompletedDateColumn,
} from './TaskTableColumns';
import { setSelectionOfTaskOfUser } from '../QueueActions';
import { hasDASRecord } from '../utils';
import COPY from '../../../COPY';
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

  caseTypeColumn = () => {
    return this.props.includeType ? typeColumn(this.props.tasks, this.props.requireDasRecord) : null;
  }

  caseDocketNumberColumn = () => {
    return this.props.includeDocketNumber ? docketNumberColumn(this.props.tasks, this.props.requireDasRecord) : null;
  }

  caseIssueCountColumn = () => {
    return this.props.includeIssueCount ? issueCountColumn(this.props.requireDasRecord) : null;
  }

  caseDaysWaitingColumn = () => {
    return this.props.includeDaysWaiting ? daysWaitingColumn(this.props.requireDasRecord) : null;
  }

  completedDateColumn = () => {
    return this.props.includeCompletedDate ? taskCompletedDateColumn() : null;
  }

  caseReaderLinkColumn = () => {
    return !this.props.userIsVsoEmployee && this.props.includeReaderLink ?
      readerLinkColumn(this.props.requireDasRecord, this.props.includeNewDocsIcon) :
      null;
  }

  getQueueColumns = () =>
    _.orderBy((this.props.customColumns || []).concat(
      _.compact([
        this.caseBadgesColumn(),
        this.caseSelectColumn(),
        this.caseDetailsColumn(),
        this.caseTypeColumn(),
        this.caseDocketNumberColumn(),
        this.caseIssueCountColumn(),
        this.caseDaysWaitingColumn(),
        this.completedDateColumn(),
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
      this.taskHasDASRecord(task) || !this.props.requireDasRecord ? null : 'usa-input-error'}
    taskPagesApiEndpoint={this.props.taskPagesApiEndpoint}
    useTaskPagesApi={this.props.useTaskPagesApi}
    tabPaginationOptions={this.props.tabPaginationOptions}
  />;
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
  includeType: PropTypes.bool,
  includeDocketNumber: PropTypes.bool,
  includeIssueCount: PropTypes.bool,
  includeDaysWaiting: PropTypes.bool,
  includeCompletedDate: PropTypes.bool,
  userIsVsoEmployee: PropTypes.bool,
  includeReaderLink: PropTypes.bool,
  includeNewDocsIcon: PropTypes.bool,
  customColumns: PropTypes.array,
  defaultSortIdx: PropTypes.number,
  getKeyForRow: PropTypes.func,
  taskPagesApiEndpoint: PropTypes.string,
  useTaskPagesApi: PropTypes.bool,
  tabPaginationOptions: PropTypes.object
};

const mapStateToProps = (state) => ({
  isTaskAssignedToUserSelected: state.queue.isTaskAssignedToUserSelected,
  userIsVsoEmployee: state.ui.userIsVsoEmployee,
  userRole: state.ui.userRole,
  organizationId: state.ui.activeOrganization.id
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({ setSelectionOfTaskOfUser }, dispatch)
);

export default (connect(mapStateToProps, mapDispatchToProps)(TaskTableUnconnected));

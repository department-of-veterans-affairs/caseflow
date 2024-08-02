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
  issueTypesColumn,
  typeColumn,
  readerLinkColumn,
  taskCompletedDateColumn,
} from './TaskTableColumns';
import { setSelectionOfTaskOfUser } from '../QueueActions';
import { hasDASRecord } from '../utils';
import COPY from '../../../COPY';
import { updateQueueTableCache } from '../caching/queueTableCache.slice';
export class TaskTableUnconnected extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.uniqueId

  isTaskSelected = (uniqueId) => {
    if (!this.props.isTaskAssignedToUserSelected) {
      return false;
    }
    const isTaskSelected = this.props.isTaskAssignedToUserSelected[this.props.userId] || {};

    return isTaskSelected[uniqueId]?.selected || false;
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
          selected,
          task
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

  caseIssueTypesColumn = () => {
    return this.props.includeIssueTypes ? issueTypesColumn() : null;
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
        this.caseIssueTypesColumn(),
        this.caseDaysWaitingColumn(),
        this.completedDateColumn(),
        this.caseReaderLinkColumn()
      ])), ['order'], ['desc']);

  getDefaultSortHash = () => {
    if (this.props.defaultSort) {
      return this.props.defaultSort;
    }
  }

  render = () => <QueueTable
    columns={this.getQueueColumns()}
    rowObjects={this.props.tasks}
    getKeyForRow={this.props.getKeyForRow || this.getKeyForRow}
    defaultSort={this.getDefaultSortHash()}
    enablePagination
    onHistoryUpdate={this.props.onHistoryUpdate}
    preserveFilter={this.props.preserveQueueFilter}
    rowClassNames={(task) =>
      (this.taskHasDASRecord(task) || !this.props.requireDasRecord) ? null : 'usa-input-error'}
    taskPagesApiEndpoint={this.props.taskPagesApiEndpoint}
    useTaskPagesApi={this.props.useTaskPagesApi}
    tabPaginationOptions={this.props.tabPaginationOptions}
    useReduxCache={this.props.useReduxCache}
    reduxCache={this.props.queueTableResponseCache}
    updateReduxCache={this.props.updateQueueTableCache}
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
  includeIssueTypes: PropTypes.bool,
  includeDaysWaiting: PropTypes.bool,
  includeCompletedDate: PropTypes.bool,
  userIsVsoEmployee: PropTypes.bool,
  includeReaderLink: PropTypes.bool,
  includeNewDocsIcon: PropTypes.bool,
  customColumns: PropTypes.array,
  defaultSort: PropTypes.shape({
    sortColName: PropTypes.string,
    sortAscending: PropTypes.bool
  }),
  getKeyForRow: PropTypes.func,
  taskPagesApiEndpoint: PropTypes.string,
  useTaskPagesApi: PropTypes.bool,
  tabPaginationOptions: PropTypes.object,
  onHistoryUpdate: PropTypes.func,
  preserveQueueFilter: PropTypes.bool,
  queueTableResponseCache: PropTypes.object,
  updateQueueTableCache: PropTypes.func,
  useReduxCache: PropTypes.bool,
};

const mapStateToProps = (state) => ({
  isTaskAssignedToUserSelected: state.queue.isTaskAssignedToUserSelected,
  userIsVsoEmployee: state.ui.userIsVsoEmployee,
  userRole: state.ui.userRole,
  organizationId: state.ui.activeOrganization.id,
  queueTableResponseCache: state.caching.queueTable.cachedResponses
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({ setSelectionOfTaskOfUser, updateQueueTableCache }, dispatch)
);

export default (connect(mapStateToProps, mapDispatchToProps)(TaskTableUnconnected));

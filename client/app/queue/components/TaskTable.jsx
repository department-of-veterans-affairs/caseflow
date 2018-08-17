// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import moment from 'moment';
import pluralize from 'pluralize';
import { bindActionCreators } from 'redux';

import Table from '../../components/Table';
import Checkbox from '../../components/Checkbox';
import ReaderLink from '../ReaderLink';
import CaseDetailsLink from '../CaseDetailsLink';

import { setSelectionOfTaskOfUser } from '../QueueActions';
import { renderAppealType } from '../utils';
import { DateString } from '../../util/DateUtil';
import { CATEGORIES, redText } from '../constants';
import COPY from '../../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';

import type {
  TaskWithAppeal,
  Task
} from '../types/models';

type Params = {|
  includeSelect?: boolean,
  includeDetailsLink?: boolean,
  includeTask?: boolean,
  includeDocumentId?: boolean,
  includeType?: boolean,
  includeDocketNumber?: boolean,
  includeIssueCount?: boolean,
  includeDueDate?: boolean,
  includeDaysWaiting?: boolean,
  includeDaysOnHold?: boolean,
  includeReaderLink?: boolean,
  includeDocumentCount?: boolean,
  requireDasRecord?: boolean,
  tasks: Array<TaskWithAppeal>,
  userId?: string,
|};

type Props = Params & {|
  setSelectionOfTaskOfUser: Function,
  isTaskAssignedToUserSelected?: Object
|};

class TaskTable extends React.PureComponent<Props> {
  getKeyForRow = (rowNumber, object) => object.appeal.id

  isTaskSelected = (externalAppealId) => {
    if (!this.props.isTaskAssignedToUserSelected) {
      return false;
    }

    const isTaskSelected = this.props.isTaskAssignedToUserSelected[this.props.userId] || {};

    return isTaskSelected[externalAppealId] || false;
  }

  taskHasDASRecord = (task: TaskWithAppeal) => {
    if (task.appeal.docketName === 'Legacy' && this.props.requireDasRecord) {
      return task.taskId;
    }

    return true;
  }

  collapseColumnIfNoDASRecord = (task) => this.taskHasDASRecord(task) ? 1 : 0

  caseSelectColumn = () => {
    return this.props.includeSelect ? {
      header: COPY.CASE_LIST_TABLE_SELECT_COLUMN_TITLE,
      valueFunction:
        (task) => {
          return <Checkbox
            name={task.externalAppealId}
            hideLabel
            value={this.isTaskSelected(task.externalAppealId)}
            onChange={
              (checked) => this.props.setSelectionOfTaskOfUser(
                { userId: this.props.userId,
                  taskId: task.externalAppealId,
                  selected: checked })
            } />;
        }
    } : null;
  }

  caseDetailsColumn = () => {
    return this.props.includeDetailsLink ? {
      header: COPY.CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE,
      valueFunction: (task) => <CaseDetailsLink
        task={task}
        appeal={task.appeal}
        disabled={!this.taskHasDASRecord(task)} />,
      getSortValue: (task) => {
        const vetName = task.appeal.veteranFullName.split(' ');
        // only take last, first names. ignore middle names/initials

        return `${_.last(vetName)} ${vetName[0]}`;
      }
    } : null;
  }

  actionNameOfTask = (task: TaskWithAppeal) => CO_LOCATED_ADMIN_ACTIONS[task.action]

  caseTaskColumn = () => {
    return this.props.includeTask ? {
      header: COPY.CASE_LIST_TABLE_TASKS_COLUMN_TITLE,
      valueFunction: (task) => this.actionNameOfTask(task),
      getSortValue: (task) => this.actionNameOfTask(task)
    } : null;
  }

  caseDocumentIdColumn = () => {
    return this.props.includeDocumentId ? {
      header: COPY.CASE_LIST_TABLE_DOCUMENT_ID_COLUMN_TITLE,
      valueFunction: (task) => {
        if (!task.assignedBy.firstName) {
          return task.documentId;
        }
        const firstInitial = String.fromCodePoint(task.assignedBy.firstName.codePointAt(0));
        const nameAbbrev = `${firstInitial}. ${task.assignedBy.lastName}`;

        return <React.Fragment>
          {task.documentId}<br />from {nameAbbrev}
        </React.Fragment>;
      }
    } : null;
  }

  caseTypeColumn = () => {
    return this.props.includeType ? {
      header: COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE,
      valueFunction: (task) => this.taskHasDASRecord(task) ?
        renderAppealType(task.appeal) :
        <span {...redText}>{COPY.ATTORNEY_QUEUE_TABLE_TASK_NEEDS_ASSIGNMENT_ERROR_MESSAGE}</span>,
      span: (task) => this.taskHasDASRecord(task) ? 1 : 5,
      getSortValue: (task) => {
        // We append a * before the docket number if it's a priority case since * comes before
        // numbers in sort order, this forces these cases to the top of the sort.
        if (task.appeal.isAdvancedOnDocket || task.appeal.caseType === 'Court Remand') {
          return `*${task.appeal.docketNumber}`;
        }

        return task.appeal.docketNumber;
      }
    } : null;
  }

  caseDocketNumberColumn = () => {
    return this.props.includeDocketNumber ? {
      header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
      valueFunction: (task) => this.taskHasDASRecord(task) ? task.appeal.docketNumber : null,
      span: this.collapseColumnIfNoDASRecord,
      getSortValue: (task) => this.taskHasDASRecord(task) ? task.appeal.docketNumber : null
    } : null;
  }

  caseIssueCountColumn = () => {
    return this.props.includeIssueCount ? {
      header: COPY.CASE_LIST_TABLE_APPEAL_ISSUE_COUNT_COLUMN_TITLE,
      valueFunction: (task) => this.taskHasDASRecord(task) ? task.appeal.issueCount : null,
      span: this.collapseColumnIfNoDASRecord,
      getSortValue: (task) => this.taskHasDASRecord(task) ? task.appeal.issueCount : null
    } : null;
  }

  caseDueDateColumn = () => {
    return this.props.includeDueDate ? {
      header: COPY.CASE_LIST_TABLE_DAYS_WAITING_COLUMN_TITLE,
      tooltip: <React.Fragment>Calendar days this case <br /> has been assigned to you</React.Fragment>,
      valueFunction: (task) => {
        if (!this.taskHasDASRecord(task)) {
          return null;
        }

        const daysWaiting = moment().
          diff(moment(task.assignedOn), 'days');

        return <React.Fragment>
          {daysWaiting} {pluralize('day', daysWaiting)} - <DateString date={task.dueOn} />
        </React.Fragment>;
      },
      span: this.collapseColumnIfNoDASRecord,
      getSortValue: (task) => {
        return moment().diff(moment(task.assignedOn), 'days');
      }
    } : null;
  }

  caseDaysWaitingColumn = () => {
    return this.props.includeDaysWaiting ? {
      header: COPY.CASE_LIST_TABLE_TASK_DAYS_WAITING_COLUMN_TITLE,
      valueFunction: (task) => {
        return moment().startOf('day').
          diff(moment(task.assignedOn), 'days');
      },
      span: this.collapseColumnIfNoDASRecord,
      getSortValue: (task) => {
        return moment().startOf('day').
          diff(moment(task.assignedOn), 'days');
      }
    } : null;
  }

  numDaysOnHold = (task: Task) => moment().diff(task.placedOnHoldAt, 'days')

  caseDaysOnHoldColumn = () => (this.props.includeDaysOnHold ? {
    header: COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE,
    valueFunction: (task: Task) => {
      return `${this.numDaysOnHold(task)} of ${task.onHoldDuration || '?'}`;
    },
    getSortValue: (task: Task) => this.numDaysOnHold(task)
  } : null)

  caseReaderLinkColumn = () => {
    return this.props.includeReaderLink ? {
      header: COPY.CASE_LIST_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE,
      span: this.collapseColumnIfNoDASRecord,
      valueFunction: (task) => {
        if (!this.taskHasDASRecord(task)) {
          return null;
        }

        return <ReaderLink appealId={task.externalAppealId}
          analyticsSource={CATEGORIES.QUEUE_TABLE}
          redirectUrl={window.location.pathname}
          appeal={task.appeal} />;
      }
    } : null;
  }

  getQueueColumns = () : Array<{ header: string, span?: Function, valueFunction: Function, getSortValue?: Function }> =>
    _.compact([
      this.caseSelectColumn(),
      this.caseDetailsColumn(),
      this.caseTaskColumn(),
      this.caseDocumentIdColumn(),
      this.caseTypeColumn(),
      this.caseDocketNumberColumn(),
      this.caseIssueCountColumn(),
      this.caseDueDateColumn(),
      this.caseDaysWaitingColumn(),
      this.caseDaysOnHoldColumn(),
      this.caseReaderLinkColumn()
    ]);

  getDefaultSortableColumn = () => {
    const index = _.findIndex(this.getQueueColumns(),
      (column) => column.header === COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE);

    if (index >= 0) {
      return index;
    }

    return _.findIndex(this.getQueueColumns(), (column) => column.getSortValue);
  }

  render = () => {
    const { tasks } = this.props;

    return <Table
      columns={this.getQueueColumns}
      rowObjects={tasks}
      getKeyForRow={this.getKeyForRow}
      defaultSort={{ sortColIdx: this.getDefaultSortableColumn() }}
      rowClassNames={(task) =>
        this.taskHasDASRecord(task) || !this.props.requireDasRecord ? null : 'usa-input-error'} />;
  }
}

const mapStateToProps = (state) => _.pick(state.queue, 'isTaskAssignedToUserSelected');

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    setSelectionOfTaskOfUser
  }, dispatch)
);

export default (connect(mapStateToProps, mapDispatchToProps)(TaskTable): React.ComponentType<Params>);

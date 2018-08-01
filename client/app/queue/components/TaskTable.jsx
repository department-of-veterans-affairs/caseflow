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

import type {
  LegacyAppeals
} from '../types/models';

type Params = {|
  includeSelect?: boolean,
  includeDetailsLink?: boolean,
  includeDocumentId?: boolean,
  includeType?: boolean,
  includeDocketNumber?: boolean,
  includeIssueCount?: boolean,
  includeDueDate?: boolean,
  includeDaysWaiting?: boolean,
  includeReaderLink?: boolean,
  includeDocumentCount?: boolean,
  requireDasRecord?: boolean,
  appeals: LegacyAppeals,
  userId: ?string,
|};

type Props = Params & {|
  setSelectionOfTaskOfUser: Function,
  isTaskAssignedToUserSelected?: Object
|};

class TaskTable extends React.PureComponent<Props> {
  getKeyForRow = (rowNumber, object) => object.id

  isTaskSelected = (taskId) => {
    if (!this.props.isTaskAssignedToUserSelected) {
      return false;
    }

    const isTaskSelected = this.props.isTaskAssignedToUserSelected[this.props.userId] || {};

    return isTaskSelected[taskId] || false;
  }

  appealHasDASRecord = (appeal) => {
    if (this.props.requireDasRecord) {
      return appeal.tasks.some((task) => task.taskId);
    }

    return true;
  }

  oldestTask = (appeal) => {
    if (!appeal.tasks) {
      return null;
    }

    return appeal.tasks.reduce((oldestTask, task) => {
      if (oldestTask === null) {
        return task;
      }
      if (moment(task.assignedOn).isBefore(moment(oldestTask.assignedOn))) {
        return task;
      }

      return oldestTask;

    }, null);
  }

  collapseColumnIfNoDASRecord = (appeal) => this.appealHasDASRecord(appeal) ? 1 : 0

  caseSelectColumn = () => {
    return this.props.includeSelect ? {
      header: COPY.CASE_LIST_TABLE_SELECT_COLUMN_TITLE,
      valueFunction:
        (appeal) => {
          const task = this.oldestTask(appeal);

          if (!task) {
            return null;
          }

          return <Checkbox
            name={task.id}
            hideLabel
            value={this.isTaskSelected(task.id)}
            onChange={
              (checked) =>
                this.props.setSelectionOfTaskOfUser(
                  { userId: this.props.userId,
                    taskId: task.id,
                    selected: checked })} />;
        }
    } : null;
  }

  caseDetailsColumn = () => {
    return this.props.includeDetailsLink ? {
      header: COPY.CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE,
      valueFunction: (appeal) => <CaseDetailsLink
        task={this.oldestTask(appeal)}
        appeal={appeal}
        disabled={!this.appealHasDASRecord(appeal)} />,
      getSortValue: (appeal) => {
        const vetName = appeal.veteranName.split(' ');
        // only take last, first names. ignore middle names/initials

        return `${_.last(vetName)} ${vetName[0]}`;
      }
    } : null;
  }

  caseDocumentIdColumn = () => {
    return this.props.includeDocumentId ? {
      header: COPY.CASE_LIST_TABLE_DOCUMENT_ID_COLUMN_TITLE,
      valueFunction: (appeal) => {
        const task = this.oldestTask(appeal);

        if (!task) {
          return null;
        }

        if (!task.assignedByFirstName) {
          return task.documentId;
        }
        const firstInitial = String.fromCodePoint(task.assignedByFirstName.codePointAt(0));
        const nameAbbrev = `${firstInitial}. ${task.assignedByLastName}`;

        return <React.Fragment>
          {task.documentId}<br />from {nameAbbrev}
        </React.Fragment>;
      }
    } : null;
  }

  caseTypeColumn = () => {
    return this.props.includeType ? {
      header: COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE,
      valueFunction: (appeal) => this.appealHasDASRecord(appeal) ?
        renderAppealType(appeal) :
        <span {...redText}>{COPY.ATTORNEY_QUEUE_TABLE_TASK_NEEDS_ASSIGNMENT_ERROR_MESSAGE}</span>,
      span: (appeal) => this.appealHasDASRecord(appeal) ? 1 : 5,
      getSortValue: (appeal) => {
        // We append a * before the docket number if it's a priority case since * comes before
        // numbers in sort order, this forces these cases to the top of the sort.
        if (appeal.isAdvancedOnDocket || appeal.caseType === 'Court Remand') {
          return `*${appeal.docketNumber}`;
        }

        return appeal.docketNumber;
      }
    } : null;
  }

  caseDocketNumberColumn = () => {
    return this.props.includeDocketNumber ? {
      header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
      valueFunction: (appeal) => this.appealHasDASRecord(appeal) ? appeal.docketNumber : null,
      span: this.collapseColumnIfNoDASRecord,
      getSortValue: (appeal) => this.appealHasDASRecord(appeal) ? appeal.docketNumber : null
    } : null;
  }

  caseIssueCountColumn = () => {
    return this.props.includeIssueCount ? {
      header: COPY.CASE_LIST_TABLE_APPEAL_ISSUE_COUNT_COLUMN_TITLE,
      valueFunction: (appeal) => this.appealHasDASRecord(appeal) ? appeal.issues.length : null,
      span: this.collapseColumnIfNoDASRecord,
      getSortValue: (appeal) => this.appealHasDASRecord(appeal) ? appeal.issues.length : null
    } : null;
  }

  caseDueDateColumn = () => {
    return this.props.includeDueDate ? {
      header: COPY.CASE_LIST_TABLE_DAYS_WAITING_COLUMN_TITLE,
      tooltip: <React.Fragment>Calendar days this case <br /> has been assigned to you</React.Fragment>,
      valueFunction: (appeal) => {
        if (!this.appealHasDASRecord(appeal)) {
          return null;
        }

        const task = this.oldestTask(appeal);

        if (!task) {
          return null;
        }

        const daysWaiting = moment().
          diff(moment(task.assignedOn), 'days');

        return <React.Fragment>
          {daysWaiting} {pluralize('day', daysWaiting)} - <DateString date={task.dueOn} />
        </React.Fragment>;
      },
      span: this.collapseColumnIfNoDASRecord,
      getSortValue: (appeal) => {
        const task = this.oldestTask(appeal);

        if (!task) {
          return 0;
        }

        return moment().diff(moment(task.assignedOn), 'days');
      }
    } : null;
  }

  caseDaysWaitingColumn = () => {
    return this.props.includeDaysWaiting ? {
      header: COPY.CASE_LIST_TABLE_TASK_DAYS_WAITING_COLUMN_TITLE,
      valueFunction: (appeal) => {
        const task = this.oldestTask(appeal);

        if (!task) {
          return null;
        }

        return moment().startOf('day').
          diff(moment(task.assignedOn), 'days');
      },
      span: this.collapseColumnIfNoDASRecord,
      getSortValue: (appeal) => {
        const task = this.oldestTask(appeal);

        if (!task) {
          return null;
        }

        return moment().startOf('day').
          diff(moment(task.assignedOn), 'days');
      }
    } : null;
  }

  caseReaderLinkColumn = () => {
    return this.props.includeReaderLink ? {
      header: COPY.CASE_LIST_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE,
      span: this.collapseColumnIfNoDASRecord,
      valueFunction: (appeal) => {
        if (!this.appealHasDASRecord(appeal)) {
          return null;
        }

        return <ReaderLink appealId={appeal.vacolsId}
          analyticsSource={CATEGORIES.QUEUE_TABLE}
          redirectUrl={window.location.pathname}
          appeal={appeal} />;
      }
    } : null;
  }

  getQueueColumns = () : Array<{ header: string, span?: Function, valueFunction: Function, getSortValue?: Function }> =>
    _.compact([
      this.caseSelectColumn(),
      this.caseDetailsColumn(),
      this.caseDocumentIdColumn(),
      this.caseTypeColumn(),
      this.caseDocketNumberColumn(),
      this.caseIssueCountColumn(),
      this.caseDueDateColumn(),
      this.caseDaysWaitingColumn(),
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
    const { appeals } = this.props;

    return <Table
      columns={this.getQueueColumns}
      rowObjects={appeals}
      getKeyForRow={this.getKeyForRow}
      defaultSort={{ sortColIdx: this.getDefaultSortableColumn() }}
      rowClassNames={(appeal) =>
        this.appealHasDASRecord(appeal) || !this.props.requireDasRecord ? null : 'usa-input-error'} />;
  }
}

const mapStateToProps = (state) => _.pick(state.queue, 'isTaskAssignedToUserSelected');

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    setSelectionOfTaskOfUser
  }, dispatch)
);

export default (connect(mapStateToProps, mapDispatchToProps)(TaskTable): React.ComponentType<Params>);

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
import AppealDocumentCount from '../AppealDocumentCount';

import {
  appealsByAssigneeCssIdSelector,
  appealsWithTasks
} from '../selectors';
import { setSelectionOfTaskOfUser } from '../QueueActions';
import { sortTasks, renderAppealType } from '../utils';
import { DateString } from '../../util/DateUtil';
import { CATEGORIES, redText } from '../constants';
import COPY from '../../../COPY.json';

import type {
  LegacyAppeals
} from '../types/models';

type Props = {|
  appeals: LegacyAppeals,
  userId: ?string
|};

class TaskTable extends React.PureComponent<Props> {
  getKeyForRow = (rowNumber, object) => object.id
  
  isTaskSelected = (taskId) => {
    const isTaskSelected = this.props.isTaskAssignedToUserSelected[this.props.userId] || {};

    return isTaskSelected[taskId] || false;
  }

  appealHasDASRecord = (appeal) => {
    if (this.props.requireDasRecord) {
      return appeal.tasks.some((task) => task.attributes.task_id);
    } else {
      return true;
    }
  }

  oldestTask = (appeal) => appeal.tasks.reduce((oldestTask, task) => {
    if (oldestTask === null) {
      return task;
    } else {
      if (moment(task.attributes.assigned_on).isBefore(moment(oldestTask.attributes.assigned_on))) {
        return task
      } else {
        return oldestTask
      }
    }
  }, null)

  collapseColumnIfNoDASRecord = (appeal) => this.appealHasDASRecord(appeal) ? 1 : 0

  caseSelectColumn = () => {
    return this.props.includeSelect ? {
      header: COPY.CASE_LIST_TABLE_SELECT_COLUMN_TITLE,
      valueFunction:
        (appeal) => {
          const task = this.oldestTask(appeal);

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
        task={appeal.tasks[0]}
        appeal={appeal}
        disabled={!this.appealHasDASRecord(appeal)} />,
      getSortValue: (appeal) => {
        const vetName = appeal.attributes['veteran_full_name'].split(' ');
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

        if (!task.attributes.assigned_by_first_name) {
          return task.attributes.document_id;
        }
        const firstInitial = String.fromCodePoint(task.attributes.assigned_by_first_name.codePointAt(0));
        const nameAbbrev = `${firstInitial}. ${task.attributes.assigned_by_last_name}`;

        return <React.Fragment>
          {task.attributes.document_id}<br />from {nameAbbrev}
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
      span: (appeal) => this.appealHasDASRecord(appeal) ? 1 : 5
    } : null;
  }

  caseDocketNumberColumn = () => {
    return this.props.includeDocketNumber ? {
      header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
      valueFunction: (appeal) => this.appealHasDASRecord(appeal) ? appeal.attributes.docket_number : null,
      span: this.collapseColumnIfNoDASRecord,
      getSortValue: (appeal) => this.appealHasDASRecord(appeal) ? appeal.attributes.docket_number : null
    } : null;
  }

  caseIssueCountColumn = () => {
    return this.props.includeIssueCount ? {
      header: COPY.CASE_LIST_TABLE_APPEAL_ISSUE_COUNT_COLUMN_TITLE,
      valueFunction: (appeal) => this.appealHasDASRecord(appeal) ? appeal.attributes.issues.length : null,
      span: this.collapseColumnIfNoDASRecord,
      getSortValue: (appeal) => this.appealHasDASRecord(appeal) ? appeal.attributes.issues.length : null
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

        const daysWaiting = moment().
          diff(moment(task.attributes.assigned_on), 'days');

        return <React.Fragment>
          {daysWaiting} {pluralize('day', daysWaiting)} - <DateString date={task.attributes.due_on} />
        </React.Fragment>;
      },
      span: this.collapseColumnIfNoDASRecord,
      getSortValue: (appeal) => moment().diff(moment(this.oldestTask(appeal).attributes.assigned_on), 'days')
    } : null;
  }

  caseDaysWaitingColumn = () => {
    return this.props.includeDaysWaiting ? {
      header: COPY.CASE_LIST_TABLE_TASK_DAYS_WAITING_COLUMN_TITLE,
      valueFunction: (appeal) => moment().startOf('day').
        diff(moment(this.oldestTask(appeal).attributes.assigned_on), 'days'),
      span: this.collapseColumnIfNoDASRecord,
      getSortValue: (appeal) => moment().startOf('day').
        diff(moment(this.oldestTask(appeal).attributes.assigned_on), 'days')
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

        return <ReaderLink appealId={appeal.id}
          analyticsSource={CATEGORIES.QUEUE_TABLE}
          redirectUrl={window.location.pathname}
          appeal={appeal} />;
      }
    } : null;
  }

  caseDocumentCount = () => {
    return this.props.includeDocumentCount ? {
      header: COPY.JUDGE_QUEUE_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE,
      valueFunction: (appeal) => <AppealDocumentCount appeal={appeal} />
    } : null;
  }

  getQueueColumns = () => _.compact([
    this.caseSelectColumn(),
    this.caseDetailsColumn(),
    this.caseDocumentIdColumn(),
    this.caseTypeColumn(), 
    this.caseDocketNumberColumn(),
    this.caseIssueCountColumn(),
    this.caseDocumentCount(),
    this.caseDueDateColumn(),
    this.caseDaysWaitingColumn(),
    this.caseReaderLinkColumn()
  ]);

  getFirstSortableColumn = () => {
    return _.findIndex(this.getQueueColumns(), (column) => column.getSortValue)
  }

  render = () => {
    const { appeals } = this.props;

    return <Table
      columns={this.getQueueColumns}
      rowObjects={appeals}
      getKeyForRow={this.getKeyForRow}
      defaultSort={{ sortColIdx: this.getFirstSortableColumn() }}
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

export default (connect(mapStateToProps, mapDispatchToProps)(TaskTable): React.ComponentType<Props>);

// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import moment from 'moment';
import pluralize from 'pluralize';

import Table from '../components/Table';
import ReaderLink from './ReaderLink';
import CaseDetailsLink from './CaseDetailsLink';

import {
  appealsByAssigneeCssIdSelector,
  appealsWithTasks
} from './selectors';
import { sortTasks, renderAppealType } from './utils';
import { DateString } from '../util/DateUtil';
import { CATEGORIES, redText } from './constants';
import COPY from '../../COPY.json';

import type {
  LegacyAppeals
} from './types/models';

type Props = {|
  appeals: LegacyAppeals,
  featureToggles: Object
|};

class AttorneyTaskTable extends React.PureComponent<Props> {
  getKeyForRow = (rowNumber, object) => object.id
  
  appealHasDASRecord = (appeal) => appeal.tasks.some((task) => task.attributes.task_id)

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

  getQueueColumns = () => [{
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
  }, {
    header: COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE,
    valueFunction: (appeal) => this.appealHasDASRecord(appeal) ?
      renderAppealType(appeal) :
      <span {...redText}>{COPY.ATTORNEY_QUEUE_TABLE_TASK_NEEDS_ASSIGNMENT_ERROR_MESSAGE}</span>,
    span: (appeal) => this.appealHasDASRecord(appeal) ? 1 : 5
  }, {
    header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
    valueFunction: (appeal) => this.appealHasDASRecord(appeal) ? appeal.attributes.docket_number : null,
    span: this.collapseColumnIfNoDASRecord,
    getSortValue: (appeal) => this.appealHasDASRecord(appeal) ? appeal.attributes.docket_number : null
  }, {
    header: COPY.CASE_LIST_TABLE_APPEAL_ISSUE_COUNT_COLUMN_TITLE,
    valueFunction: (appeal) => this.appealHasDASRecord(appeal) ? appeal.attributes.issues.length : null,
    span: this.collapseColumnIfNoDASRecord,
    getSortValue: (appeal) => this.appealHasDASRecord(appeal) ? appeal.attributes.issues.length : null
  }, {
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
  }, {
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
  }];

  render = () => {
    const { appeals } = this.props;

    return <Table
      columns={this.getQueueColumns}
      rowObjects={appeals}
      getKeyForRow={this.getKeyForRow}
      defaultSort={{ sortColIdx: 0 }}
      rowClassNames={(appeal) => this.appealHasDASRecord(appeal) ? null : 'usa-input-error'} />;
  }
}

const mapStateToProps = (state) => {
  const {
    ui: {
      featureToggles
    }
  } = state;

  return {
    appeals: appealsByAssigneeCssIdSelector(state),
    featureToggles
  };
};

export default (connect(mapStateToProps)(AttorneyTaskTable): React.ComponentType<Props>);

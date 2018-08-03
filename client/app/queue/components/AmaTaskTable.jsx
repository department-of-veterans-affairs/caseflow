// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import moment from 'moment';

import Table from '../../components/Table';
import ReaderLink from '../ReaderLink';

import { CATEGORIES } from '../constants';
import COPY from '../../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import { renderAppealType } from '../utils';

import type {
  AmaTask
} from '../types/models';

type Params = {|
  tasks: Array<AmaTask>
|};

type Props = Params;

class AmaTaskTable extends React.PureComponent<Props> {
  getKeyForRow = (rowNumber, task) => task.id

  caseDetailsColumn = () => {
    return {
      header: COPY.CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE,
      valueFunction:
        (task: AmaTask) => <a href={`/queue/appeals/${task.attributes.external_id}`}>
          {task.attributes.veteran_name} ({task.attributes.veteran_file_number})</a>
    };
  }

  caseTypeColumn = () => ({
    header: COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE,
    valueFunction: (task: AmaTask) => renderAppealType({ aod: task.attributes.aod,
      type: task.attributes.case_type })
  })

  caseTaskColumn = () => ({
    header: COPY.CASE_LIST_TABLE_TASKS_COLUMN_TITLE,
    valueFunction: (task: AmaTask) => CO_LOCATED_ADMIN_ACTIONS[task.attributes.title]
  })

  caseDocketNumberColumn = () => ({
    header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
    valueFunction: (task) => task.attributes.docket_number
  })

  caseDaysWaitingColumn = () => ({
    header: COPY.CASE_LIST_TABLE_TASK_DAYS_WAITING_COLUMN_TITLE,
    valueFunction: (task) => {
      return moment().startOf('day').
        diff(moment(task.attributes.assigned_at), 'days');
    }
  })

  caseReaderLinkColumn = () => ({
    header: COPY.CASE_LIST_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE,
    valueFunction: (task: AmaTask) => {
      return <ReaderLink appealId={task.attributes.external_id}
        analyticsSource={CATEGORIES.QUEUE_TABLE}
        redirectUrl={window.location.pathname}
        appeal={{ attributes: { vacols_id: task.attributes.external_id,
          paper_case: false } }} />;
    }
  })

  getQueueColumns = () : Array<{ header: string, span?: Function, valueFunction: Function, getSortValue?: Function }> =>
    _.compact([
      this.caseDetailsColumn(),
      this.caseTypeColumn(),
      this.caseTaskColumn(),
      this.caseDocketNumberColumn(),
      this.caseDaysWaitingColumn(),
      this.caseReaderLinkColumn()
    ]);

  render = () => {
    const { tasks } = this.props;

    return <Table
      columns={this.getQueueColumns}
      rowObjects={tasks}
      getKeyForRow={this.getKeyForRow} />;
  }
}

const mapStateToProps = () => ({});

export default (connect(mapStateToProps)(AmaTaskTable): React.ComponentType<Params>);

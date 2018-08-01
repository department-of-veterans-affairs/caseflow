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
import AppealDocumentCount from '../AppealDocumentCount';

import { setSelectionOfTaskOfUser } from '../QueueActions';
import { renderAppealType } from '../utils';
import { DateString } from '../../util/DateUtil';
import { CATEGORIES, redText } from '../constants';
import COPY from '../../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';

import type {
  LegacyAppeals,
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
        (task: AmaTask) => <a href={`/queue/appeals/${task.attributes.appeal_id}`}>
          {task.attributes.veteran_name} ({task.attributes.veteran_file_number})</a>
    };
  }

  caseTaskColumn = () => ({
    header: COPY.CASE_LIST_TABLE_TASKS_COLUMN_TITLE,
    valueFunction: (task: AmaTask) => CO_LOCATED_ADMIN_ACTIONS[task.attributes.title]
  })

  getQueueColumns = () : Array<{ header: string, span?: Function, valueFunction: Function, getSortValue?: Function }> =>
    _.compact([
      this.caseDetailsColumn(),
      this.caseTaskColumn()
    ]);

  render = () => {
    const { tasks } = this.props;
    console.log(tasks);

    return <Table
      columns={this.getQueueColumns}
      rowObjects={tasks}
      getKeyForRow={this.getKeyForRow} />;
  }
}

const mapStateToProps = () => ({});

export default (connect(mapStateToProps)(AmaTaskTable): React.ComponentType<Params>);

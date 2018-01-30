import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';

import Table from '../components/Table';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SmallLoader from '../components/SmallLoader';
import ReaderLink from './ReaderLink';

import { setAppealDocCount } from './QueueActions';
import { sortTasks } from './utils';
import ApiUtil from '../util/ApiUtil';
import { LOGO_COLORS } from '../constants/AppConstants';

// 'red' isn't contrasty enough w/white, raises Sniffybara::PageNotAccessibleError when testing
const redText = css({ color: '#E60000' });

class QueueTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.id;
  getAppealForTask = (task) => this.props.appeals[task.appealId];

  getQueueColumns = () => [
    {
      header: 'Decision Task Details',
      valueFunction: (task) => <Link>
        {this.getAppealForTask(task).attributes.veteran_full_name} ({this.getAppealForTask(task).attributes.vacols_id})
      </Link>
    },
    {
      header: 'Type(s)',
      valueFunction: (task) => {
        const {
          attributes: { aod, type }
        } = this.getAppealForTask(task);
        const cavc = type === 'Court Remand';
        const valueToRender = <div>
          {aod && <span><span {...redText}>AOD</span>, </span>}
          {cavc ? <span {...redText}>CAVC</span> : <span>{type}</span>}
        </div>;

        return <div>{valueToRender}</div>;
      }
    },
    {
      header: 'Docket Number',
      valueFunction: (task) => this.getAppealForTask(task).attributes.docket_number
    },
    {
      header: 'Issues',
      valueFunction: (task) => this.getAppealForTask(task).attributes.issues.length
    },
    {
      header: 'Due Date',
      valueFunction: (task) => moment(task.attributes.due_on).format('MM/DD/YY')
    },
    {
      header: 'Reader Documents',
      valueFunction: (task) => <LoadingDataDisplay
        createLoadPromise={this.createLoadPromise(task)}
        errorComponent="span"
        failStatusMessageProps={{}}
        failStatusMessageChildren={<ReaderLink appealId={task.appealId} />}
        loadingComponent={SmallLoader}
        loadingComponentProps={{
          message: 'Loading...',
          spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
          component: Link,
          componentProps: {
            href: `/reader/appeal/${this.getAppealForTask(task).attributes.vacols_id}/documents`
          }
        }}>
        <ReaderLink appealId={task.appealId} />
      </LoadingDataDisplay>
    }
  ];

  createLoadPromise = (task) => () => {
    const url = this.getAppealForTask(task).attributes.number_of_documents_url;
    const requestOptions = {
      withCredentials: true,
      timeout: true,
      headers: { 'FILE-NUMBER': task.appealId }
    };

    return ApiUtil.get(url, requestOptions).
      then((response) => {
        const resp = JSON.parse(response.text);
        const docCount = resp.data.attributes.documents.length;

        this.props.setAppealDocCount({
          ..._.pick(task, 'appealId'),
          docCount
        });
      });
  };

  render = () => <Table
    columns={this.getQueueColumns}
    rowObjects={sortTasks(_.pick(this.props, 'tasks', 'appeals'))}
    getKeyForRow={this.getKeyForRow}
  />;
}

QueueTable.propTypes = {
  tasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired
};

const mapStateToProps = (state) => _.pick(state.queue.loadedQueue, 'tasks', 'appeals');

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setAppealDocCount
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(QueueTable);

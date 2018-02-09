import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { css } from 'glamor';

import Table from '../components/Table';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SmallLoader from '../components/SmallLoader';
import ReaderLink from './ReaderLink';

import { setAppealDocCount, loadAppealDocCountFail } from './QueueActions';
import { sortTasks } from './utils';
import { DateString } from '../util/DateUtil';
import ApiUtil from '../util/ApiUtil';
import { LOGO_COLORS } from '../constants/AppConstants';
import { redText, CATEGORIES } from './constants';
import { COLORS as COMMON_COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

const subHeadStyle = css({
  fontSize: 'small',
  color: COMMON_COLORS.GREY_MEDIUM
});

class QueueTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.id;
  getAppealForTask = (task, attr) => {
    const appeal = this.props.appeals[task.vacolsId];

    return attr ? _.get(appeal.attributes, attr) : appeal;
  };
  veteranIsAppellant = (task) => _.isNull(this.getAppealForTask(task, 'appellant_full_name'));

  getQueueColumns = () => [
    {
      header: 'Decision Task Details',
      valueFunction: (task) => <span>
        <Link to={`/tasks/${task.vacolsId}`}>
          {this.getAppealForTask(task, 'veteran_full_name')} ({task.vacolsId})
        </Link>
        {!this.veteranIsAppellant(task) && <React.Fragment>
          <br />
          <span {...subHeadStyle}>Veteran is not the appellant</span>
        </React.Fragment>}
      </span>
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
      valueFunction: (task) => this.getAppealForTask(task, 'docket_number')
    },
    {
      header: 'Issues',
      valueFunction: (task) => this.getAppealForTask(task, 'issues.length')
    },
    {
      header: 'Due Date',
      valueFunction: (task) => <DateString date={task.attributes.due_on} />
    },
    {
      header: 'Reader Documents',
      valueFunction: (task) => <LoadingDataDisplay
        createLoadPromise={this.createLoadPromise(task)}
        errorComponent="span"
        failStatusMessageChildren={<ReaderLink vacolsId={task.vacolsId} />}
        loadingComponent={SmallLoader}
        loadingComponentProps={{
          message: 'Loading...',
          spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
          component: Link,
          componentProps: {
            href: `/reader/appeal/${task.vacolsId}/documents`
          }
        }}>
        <ReaderLink vacolsId={task.vacolsId} analyticsSource={CATEGORIES.QUEUE_TABLE} />
      </LoadingDataDisplay>
    }
  ];

  createLoadPromise = (task) => () => {
    if (!_.isUndefined(this.props.appeals[task.vacolsId].attributes.docCount)) {
      return Promise.resolve();
    }

    const url = this.getAppealForTask(task, 'number_of_documents_url');
    const requestOptions = {
      withCredentials: true,
      timeout: true,
      headers: { 'FILE-NUMBER': task.vacolsId }
    };

    return ApiUtil.get(url, requestOptions).
      then((response) => {
        const resp = JSON.parse(response.text);
        const docCount = resp.data.attributes.documents.length;

        this.props.setAppealDocCount({
          ..._.pick(task, 'vacolsId'),
          docCount
        });
      }, () => this.props.loadAppealDocCountFail(task.vacolsId));
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
  setAppealDocCount,
  loadAppealDocCountFail
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(QueueTable);

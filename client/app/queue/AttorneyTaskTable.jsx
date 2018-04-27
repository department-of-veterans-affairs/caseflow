import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';

import Table from '../components/Table';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SmallLoader from '../components/SmallLoader';
import ReaderLink from './ReaderLink';
import CaseDetailsLink from './CaseDetailsLink';
import SelectCheckoutFlowDropdown from './components/SelectCheckoutFlowDropdown';

import { setAppealDocCount, loadAppealDocCountFail } from './QueueActions';
import { sortTasks, renderAppealType } from './utils';
import { DateString } from '../util/DateUtil';
import ApiUtil from '../util/ApiUtil';
import { LOGO_COLORS } from '../constants/AppConstants';
import { CATEGORIES, redText } from './constants';

class AttorneyTaskTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.id;
  getAppealForTask = (task, attr) => {
    const appeal = this.props.appeals[task.vacolsId];

    return attr ? _.get(appeal.attributes, attr) : appeal;
  };

  getCaseDetailsLink = (task) => <CaseDetailsLink task={task} appeal={this.getAppealForTask(task)} />;

  collapseColumnIfNoDASRecord = (task) => task.attributes.task_id ? 1 : 0;

  getQueueColumns = () => {
    const columns = [{
      header: 'Case Details',
      valueFunction: this.getCaseDetailsLink
    }, {
      header: 'Type(s)',
      valueFunction: (task) => task.attributes.task_id ?
        renderAppealType(this.getAppealForTask(task)) :
        <span {...redText}>Please ask your judge to assign this case to you in DAS</span>,
      span: (task) => task.attributes.task_id ? 1 : 5
    }, {
      header: 'Docket Number',
      valueFunction: (task) => task.attributes.task_id ? this.getAppealForTask(task, 'docket_number') : null,
      span: this.collapseColumnIfNoDASRecord
    }, {
      header: 'Issues',
      valueFunction: (task) => task.attributes.task_id ? this.getAppealForTask(task, 'issues.length') : null,
      span: this.collapseColumnIfNoDASRecord
    }, {
      header: 'Due Date',
      valueFunction: (task) => task.attributes.task_id ? <DateString date={task.attributes.due_on} /> : null,
      span: this.collapseColumnIfNoDASRecord
    }, {
      header: 'Reader Documents',
      span: this.collapseColumnIfNoDASRecord,
      valueFunction: (task) => {
        if (!task.attributes.task_id) {
          return null;
        }
        const redirectUrl = encodeURIComponent(window.location.pathname);
        const href = `/reader/appeal/${task.vacolsId}/documents?queue_redirect_url=${redirectUrl}`;
        const docCount = this.props.appeals[task.vacolsId].attributes.docCount;

        return <LoadingDataDisplay
          createLoadPromise={this.createLoadPromise(task)}
          errorComponent="span"
          failStatusMessageChildren={<ReaderLink vacolsId={task.vacolsId}
            analyticsSource={CATEGORIES.QUEUE_TABLE}
            redirectUrl={window.location.pathname}
            docCount={docCount} />}
          loadingComponent={SmallLoader}
          loadingComponentProps={{
            message: 'Loading...',
            spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
            component: Link,
            componentProps: {
              href
            }
          }}>
          <ReaderLink vacolsId={task.vacolsId}
            analyticsSource={CATEGORIES.QUEUE_TABLE}
            redirectUrl={window.location.pathname}
            docCount={docCount} />
        </LoadingDataDisplay>;
      }
    }];

    if (this.props.featureToggles.phase_two) {
      columns.push({
        header: 'Action',
        span: this.collapseColumnIfNoDASRecord,
        valueFunction: (task) => <SelectCheckoutFlowDropdown
          constructRoute={(route) => `tasks/${task.vacolsId}/${route}`}
          vacolsId={task.vacolsId} />
      });
    }

    return columns;
  };

  createLoadPromise = (task) => () => {
    if (!_.isUndefined(this.getAppealForTask(task, 'docCount'))) {
      return Promise.resolve();
    }

    const url = this.getAppealForTask(task, 'number_of_documents_url');
    const vbmsId = this.getAppealForTask(task, 'vbms_id');
    const requestOptions = {
      withCredentials: true,
      timeout: true,
      headers: { 'FILE-NUMBER': vbmsId }
    };

    return ApiUtil.get(url, requestOptions).
      then((response) => {
        const resp = JSON.parse(response.text);
        const docCount = resp.data.attributes.documents.length;

        this.props.setAppealDocCount(
          task.vacolsId,
          docCount
        );
      }, () => this.props.loadAppealDocCountFail(task.vacolsId));
  };

  render = () => <Table
    columns={this.getQueueColumns}
    rowObjects={sortTasks(_.pick(this.props, 'tasks', 'appeals'))}
    getKeyForRow={this.getKeyForRow}
    rowClassNames={(task) => task.attributes.task_id ? null : 'usa-input-error'}
  />;
}

AttorneyTaskTable.propTypes = {
  tasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired,
  featureToggles: PropTypes.object
};

const mapStateToProps = (state) => _.pick(state.queue.loadedQueue, 'tasks', 'appeals');

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setAppealDocCount,
  loadAppealDocCountFail
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AttorneyTaskTable);

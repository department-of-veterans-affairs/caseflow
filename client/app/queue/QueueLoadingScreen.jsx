import _ from 'lodash';
import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import querystring from 'querystring';

import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import COPY from '../../COPY';
import { getMinutesToMilliseconds } from '../util/DateUtil';
import { associateTasksWithAppeals } from './utils';

import {
  onReceiveQueue,
  setAttorneysOfJudge,
  fetchAllAttorneys,
  fetchAmaTasksOfUser
} from './QueueActions';
import { setUserId, setTargetUserCssId } from './uiReducer/uiActions';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES';
import WindowUtil from '../util/WindowUtil';

class QueueLoadingScreen extends React.PureComponent {
  maybeLoadAmaQueue = (targetUserId, targetUserRole) => {
    const {
      userId,
      appeals,
      amaTasks,
      loadedUserId
    } = this.props;

    if (!_.isEmpty(amaTasks) && !_.isEmpty(appeals) && loadedUserId === userId && !this.queueConfigIsStale()) {
      return Promise.resolve();
    }

    this.props.setUserId(userId);

    return this.props.fetchAmaTasksOfUser(targetUserId, targetUserRole);
  }

  // When navigating between team and individual queues the configs we get from the back-end could be stale and return
  // the team queue config. In such situations we want to refetch the queue config from the back-end.
  queueConfigIsStale = () => {
    const config = this.props.queueConfig;

    // If no queue config is in state (may be using attorney or judge queue) then it is not stale.
    if (config && config.table_title && config.table_title !== COPY.USER_QUEUE_PAGE_TABLE_TITLE) {
      return true;
    }

    return false;
  }

  maybeLoadLegacyQueue = (targetUserId, targetUserRole) => {
    const {
      userId,
      loadedUserId,
      tasks,
      appeals
    } = this.props;

    if (targetUserRole !== USER_ROLE_TYPES.attorney && targetUserRole !== USER_ROLE_TYPES.judge) {
      return Promise.resolve();
    }

    const userQueueLoaded = !_.isEmpty(tasks) && !_.isEmpty(appeals) && loadedUserId === targetUserId;
    const urlToLoad = this.props.urlToLoad || `/queue/${targetUserId}`;

    if (userQueueLoaded) {
      return Promise.resolve();
    }

    const requestOptions = {
      timeout: { response: getMinutesToMilliseconds(5) }
    };

    return ApiUtil.get(urlToLoad, requestOptions).then((response) => {
      this.props.onReceiveQueue({
        amaTasks: {},
        ...associateTasksWithAppeals(response.body)
      });
      this.props.setUserId(userId);
    });
  };

  maybeLoadJudgeData = (targetUserId) => {
    if (this.props.userRole !== USER_ROLE_TYPES.judge && !this.props.loadAttorneys) {
      return Promise.resolve();
    }

    this.props.fetchAllAttorneys();

    return ApiUtil.get(`/users?role=Attorney&judge_id=${targetUserId}`).
      then((resp) => this.props.setAttorneysOfJudge(resp.body.attorneys));
  }

  createLoadPromise = () => {
    const queryString = querystring.parse(this.props.location.search.replace(/^\?/, ''));
    const isScmUser = queryString.scm?.toLowerCase() === 'true';

    const targetUserId = (isScmUser) ? this.props.match.params.userId : this.props.userId;
    const targetUserCssId = (isScmUser) ? queryString.judge_css_id : this.props.userCssId;
    const targetUserRole = (isScmUser) ? USER_ROLE_TYPES.judge : this.props.userRole;

    this.props.setTargetUserCssId(targetUserCssId);

    return Promise.all([
      this.maybeLoadAmaQueue(targetUserId, targetUserRole),
      this.maybeLoadLegacyQueue(targetUserId, targetUserRole),
      this.maybeLoadJudgeData(targetUserId)
    ]);
  }

  render = () => {
    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load your cases.<br />
      Please <a onClick={WindowUtil.reloadWithPOST}>refresh the page</a> and try again.
    </div>;

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading your cases...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load your cases'
      }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.props.children}
    </LoadingDataDisplay>;

    return <div className="usa-grid">
      {loadingDataDisplay}
    </div>;
  };
}

QueueLoadingScreen.propTypes = {
  amaTasks: PropTypes.object,
  appeals: PropTypes.object,
  children: PropTypes.node,
  fetchAllAttorneys: PropTypes.func,
  fetchAmaTasksOfUser: PropTypes.func,
  loadedUserId: PropTypes.number,
  loadAttorneys: PropTypes.bool,
  location: PropTypes.object,
  match: PropTypes.object,
  onReceiveQueue: PropTypes.func,
  queueConfig: PropTypes.object,
  setAttorneysOfJudge: PropTypes.func,
  setUserId: PropTypes.func,
  setTargetUserCssId: PropTypes.func,
  tasks: PropTypes.object,
  urlToLoad: PropTypes.string,
  userId: PropTypes.number,
  userCssId: PropTypes.string,
  userRole: PropTypes.string
};

const mapStateToProps = (state) => {
  const { tasks, amaTasks, appeals } = state.queue;

  return {
    tasks,
    appeals,
    amaTasks,
    loadedUserId: state.ui.loadedUserId,
    queueConfig: state.queue.queueConfig
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveQueue,
  setAttorneysOfJudge,
  fetchAllAttorneys,
  fetchAmaTasksOfUser,
  setUserId,
  setTargetUserCssId
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(QueueLoadingScreen));

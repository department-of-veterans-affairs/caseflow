import _ from 'lodash';
import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

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
import { setUserId, setTargetUser } from './uiReducer/uiActions';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES';
import WindowUtil from '../util/WindowUtil';

class QueueLoadingScreen extends React.PureComponent {
  maybeLoadAmaQueue = (chosenUserId) => {
    const {
      userId,
      userRole,
      appeals,
      amaTasks,
      loadedUserId
    } = this.props;

    if (!_.isEmpty(amaTasks) && !_.isEmpty(appeals) && loadedUserId === userId && !this.queueConfigIsStale()) {
      return Promise.resolve();
    }

    this.props.setUserId(userId);

    return this.props.fetchAmaTasksOfUser(chosenUserId, userRole);
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

  maybeLoadLegacyQueue = (chosenUserId) => {
    const {
      userId,
      userRole,
      loadedUserId,
      tasks,
      appeals
    } = this.props;

    if (userRole !== USER_ROLE_TYPES.attorney && userRole !== USER_ROLE_TYPES.judge) {
      return Promise.resolve();
    }

    const userQueueLoaded = !_.isEmpty(tasks) && !_.isEmpty(appeals) && loadedUserId === chosenUserId;
    const urlToLoad = this.props.urlToLoad || `/queue/${chosenUserId}`;

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

  maybeLoadJudgeData = (chosenUserId) => {
    if (this.props.userRole !== USER_ROLE_TYPES.judge && !this.props.loadAttorneys) {
      return Promise.resolve();
    }

    this.props.fetchAllAttorneys();

    return ApiUtil.get(`/users?role=Attorney&judge_id=${chosenUserId}`).
      then((resp) => this.props.setAttorneysOfJudge(resp.body.attorneys));
  }

  maybeLoadTargetUserInfo = () => {
    const userUrlParam = this.props.match?.params.userId;

    if (!userUrlParam) {
      return Promise.resolve();
    }

    if (this.isUserId(userUrlParam)) {
      const targetUserId = parseInt(userUrlParam, 10);

      return ApiUtil.get(`/user?id=${targetUserId}`).then((resp) =>
      this.props.setTargetUser(resp.body.user));
    }

    return ApiUtil.get(`/user?css_id=${userUrlParam}`).then((resp) =>
      this.props.setTargetUser(resp.body.user));
  }

  isUserId = (str) => {
    try {
      const id = parseInt(str, 10);

      if (isNaN(id) || id < 0) {
        return false;
      }

      return id.toString() === str;
    } catch (err) {
      return false;
    }
  }

  createLoadPromise = () => {
    return this.maybeLoadTargetUserInfo().then(() => {
      const chosenUserId = this.props.targetUserId || this.props.userId;

      return Promise.all([
        this.maybeLoadAmaQueue(chosenUserId),
        this.maybeLoadLegacyQueue(chosenUserId),
        this.maybeLoadJudgeData(chosenUserId)
      ]);
    });
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
  // `loadedUserId` is set by `setUserId`
  loadedUserId: PropTypes.number,
  loadAttorneys: PropTypes.bool,
  location: PropTypes.object,
  match: PropTypes.object,
  onReceiveQueue: PropTypes.func,
  queueConfig: PropTypes.object,
  setAttorneysOfJudge: PropTypes.func,
  setUserId: PropTypes.func,
  setTargetUser: PropTypes.func,
  tasks: PropTypes.object,
  targetUserId: PropTypes.number,
  urlToLoad: PropTypes.string,
  // `userId` refers to logged-in user and provided by app/views/queue/index.html.erb via QueueApp.jsx
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
    queueConfig: state.queue.queueConfig,
    targetUserId: state.ui.targetUser?.id
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveQueue,
  setAttorneysOfJudge,
  fetchAllAttorneys,
  fetchAmaTasksOfUser,
  setUserId,
  setTargetUser
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(QueueLoadingScreen));

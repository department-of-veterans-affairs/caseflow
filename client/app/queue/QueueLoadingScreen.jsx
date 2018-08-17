// @flow
import _ from 'lodash';
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import { associateTasksWithAppeals } from './utils';

import { onReceiveQueue, setAttorneysOfJudge, fetchAllAttorneys, fetchAmaTasksOfUser } from './QueueActions';
import { setUserId } from './uiReducer/uiActions';
import type { Appeals, Tasks } from './types/models';
import type { State, UsersById } from './types/state';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';

type Params = {|
  userId: number,
  userCssId: string,
  userRole: string,
  appealId?: string,
  children: React.Node,
  userCanAccessQueue: boolean,
  urlToLoad?: string
|};

type Props = Params & {|
  // From state
  tasks: Tasks,
  appeals: Appeals,
  amaTasks: Tasks,
  loadedUserId: number,
  judges: UsersById,
  // Action creators
  onReceiveQueue: typeof onReceiveQueue,
  setAttorneysOfJudge: typeof setAttorneysOfJudge,
  fetchAllAttorneys: typeof fetchAllAttorneys,
  fetchAmaTasksOfUser: Function,
  setUserId: typeof setUserId
|};

class QueueLoadingScreen extends React.PureComponent<Props> {
  maybeLoadAmaQueue = () => {
    const {
      userId,
      appeals,
      amaTasks,
      userRole,
      loadedUserId
    } = this.props;

    if (!_.isEmpty(amaTasks) && !_.isEmpty(appeals) && loadedUserId === userId) {
      return Promise.resolve();
    }

    return this.props.fetchAmaTasksOfUser(userId, userRole).
      then(() => this.props.setUserId(userId));
  }

  maybeLoadLegacyQueue = () => {
    const {
      userId,
      loadedUserId,
      tasks,
      appeals,
      userRole
    } = this.props;

    if (userRole !== USER_ROLE_TYPES.attorney && userRole !== USER_ROLE_TYPES.judge) {
      return Promise.resolve();
    }

    const userQueueLoaded = !_.isEmpty(tasks) && !_.isEmpty(appeals) && loadedUserId === userId;
    const urlToLoad = this.props.urlToLoad || `/queue/${userId}`;

    if (userQueueLoaded) {
      return Promise.resolve();
    }

    return ApiUtil.get(urlToLoad, { timeout: { response: 5 * 60 * 1000 } }).then((response) => {
      this.props.onReceiveQueue({
        amaTasks: {},
        ...associateTasksWithAppeals(JSON.parse(response.text))
      });
      this.props.setUserId(userId);
    });
  };

  maybeLoadJudgeData = () => {
    if (this.props.userRole !== USER_ROLE_TYPES.judge) {
      return Promise.resolve();
    }

    this.props.fetchAllAttorneys();

    return ApiUtil.get(`/users?role=Attorney&judge_css_id=${this.props.userCssId}`).
      then((resp) => this.props.setAttorneysOfJudge(resp.body.attorneys));
  }

  createLoadPromise = () => Promise.all([
    this.maybeLoadAmaQueue(),
    this.maybeLoadLegacyQueue(),
    this.maybeLoadJudgeData()
  ]);

  reload = () => window.location.reload();

  render = () => {
    // If the current user cannot access queue return early to avoid making the request for queues that would happen
    // as a result of createLoadPromise().
    if (!this.props.userCanAccessQueue) {
      return this.props.children;
    }

    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load your cases.<br />
      Please <a onClick={this.reload}>refresh the page</a> and try again.
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

const mapStateToProps = (state: State) => {
  const { tasks, amaTasks, appeals } = state.queue;

  return {
    tasks,
    appeals,
    amaTasks,
    loadedUserId: state.ui.loadedUserId
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveQueue,
  setAttorneysOfJudge,
  fetchAllAttorneys,
  fetchAmaTasksOfUser,
  setUserId
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(QueueLoadingScreen): React.ComponentType<Params>);

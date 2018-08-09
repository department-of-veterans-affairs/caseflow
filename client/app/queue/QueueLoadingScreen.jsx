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
import type { Appeals, Tasks } from './types/models';
import type { State, UsersById } from './types/state';
import { USER_ROLES } from './constants';

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
  loadedUserId: number,
  judges: UsersById,
  // Action creators
  onReceiveQueue: typeof onReceiveQueue,
  setAttorneysOfJudge: typeof setAttorneysOfJudge,
  fetchAllAttorneys: typeof fetchAllAttorneys,
  fetchAmaTasksOfUser: typeof fetchAmaTasksOfUser
|};

class QueueLoadingScreen extends React.PureComponent<Props> {
  loadRelevantCases = () => {
    const promises = [];

    promises.push(this.maybeLoadLegacyQueue());
    promises.push(this.props.fetchAmaTasksOfUser(this.props.userId, this.props.userRole));

    return Promise.all(promises);
  }

  maybeLoadLegacyQueue = () => {
    const {
      userId,
      loadedUserId,
      tasks,
      appeals,
      userRole
    } = this.props;

    if (userRole !== USER_ROLES.ATTORNEY && userRole !== USER_ROLES.JUDGE) {
      return Promise.resolve();
    }

    const userQueueLoaded = !_.isEmpty(tasks) && !_.isEmpty(appeals) && loadedUserId === userId;
    const urlToLoad = this.props.urlToLoad || `/queue/${userId}`;

    if (userQueueLoaded) {
      return Promise.resolve();
    }

    return ApiUtil.get(urlToLoad, { timeout: { response: 5 * 60 * 1000 } }).then((response) =>
      this.props.onReceiveQueue({
        ...associateTasksWithAppeals(JSON.parse(response.text)),
        userId
      }));
  };

  loadAttorneysOfJudge = () => {
    return ApiUtil.get(`/users?role=Attorney&judge_css_id=${this.props.userCssId}`).
      then(
        (resp) => {
          this.props.setAttorneysOfJudge(resp.body.attorneys);
        });
  }

  maybeLoadJudgeData = () => {
    if (this.props.userRole !== USER_ROLES.JUDGE) {
      return Promise.resolve();
    }
    this.props.fetchAllAttorneys();

    return this.loadAttorneysOfJudge();
  }

  createLoadPromise = () => Promise.all([
    this.loadRelevantCases(),
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
  const { tasks, appeals } = state.queue;

  return {
    tasks,
    appeals,
    loadedUserId: state.ui.loadedUserId
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveQueue,
  setAttorneysOfJudge,
  fetchAllAttorneys,
  fetchAmaTasksOfUser
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(QueueLoadingScreen): React.ComponentType<Params>);

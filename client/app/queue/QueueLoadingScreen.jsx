// @flow
import _ from 'lodash';
import PropTypes from 'prop-types';
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import { associateTasksWithAppeals } from './utils';

import { setActiveAppeal, setActiveTask } from './CaseDetail/CaseDetailActions';
import { onReceiveQueue, setAttorneysOfJudge, fetchAllAttorneys } from './QueueActions';
import type { LegacyAppeal, LegacyAppeals, Tasks } from './types/models';
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
  appeals: LegacyAppeals,
  loadedUserId: number,
  activeAppeal: LegacyAppeal,
  judges: UsersById,
  // Action creators
  onReceiveQueue: typeof onReceiveQueue,
  setActiveAppeal: typeof setActiveAppeal,
  setActiveTask: typeof setActiveTask,
  setAttorneysOfJudge: typeof setAttorneysOfJudge,
  fetchAllAttorneys: typeof fetchAllAttorneys
|};

class QueueLoadingScreen extends React.PureComponent<Props> {
  loadRelevantCases = () => {
    const promises = [];

    if (this.props.appealId) {
      promises.push(this.loadActiveAppealAndTask(this.props.appealId));
    }
    promises.push(this.loadQueue());

    return Promise.all(promises);
  }

  loadQueue = () => {
    const {
      userId,
      loadedUserId,
      tasks,
      appeals
    } = this.props;
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

  loadActiveAppealAndTask = (appealId) => {
    const {
      activeAppeal,
      appeals,
      tasks,
      userRole
    } = this.props;

    if (activeAppeal) {
      return Promise.resolve();
    }

    if (appeals && appealId in appeals) {
      this.props.setActiveAppeal(appeals[appealId]);
      this.props.setActiveTask(tasks[appealId]);

      return Promise.resolve();
    }

    return Promise.all([
      ApiUtil.get(`/appeals/${appealId}`).then((response) => {
        this.props.setActiveAppeal(response.body.appeal);
      }),
      ApiUtil.get(`/appeals/${appealId}/tasks?role=${userRole}`).then((response) => {
        const task = response.body.tasks[0];

        task.appealId = task.id;
        this.props.setActiveTask(task);
      })
    ]);
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

QueueLoadingScreen.propTypes = {
  userId: PropTypes.number.isRequired,
  appealId: PropTypes.string
};

const mapStateToProps = (state: State) => {
  const { tasks, appeals } = state.queue;

  return {
    tasks,
    appeals,
    activeAppeal: state.caseDetail.activeAppeal,
    loadedUserId: state.ui.loadedUserId
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveQueue,
  setActiveAppeal,
  setActiveTask,
  setAttorneysOfJudge,
  fetchAllAttorneys
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(QueueLoadingScreen): React.ComponentType<Params>);

// @flow
import _ from 'lodash';
import PropTypes from 'prop-types';
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import { prepareAppealDetailsForStore, prepareTasksForStore } from './utils';

import { setActiveAppeal, setActiveTask } from './CaseDetail/CaseDetailActions';
import { onReceiveAppealDetails, onReceiveTasks, setAttorneysOfJudge, fetchAllAttorneys } from './QueueActions';
import type { LegacyAppeal, LegacyAppeals, Tasks } from './types/models';
import type { State, UsersById } from './types/state';
import { USER_ROLES } from './constants';

type Params = {|
  userId: number,
  userCssId: string,
  userRole: string,
  appealId?: string,
  children: React.ChildrenArray<React.Node>,
  userCanAccessQueue: boolean,
  urlToLoad?: string
|};

type Props = Params & {|
  // From state
  tasks: Tasks,
  appealDetails: LegacyAppeals,
  loadedUserId: number,
  activeAppeal: LegacyAppeal,
  judges: UsersById,
  // Action creators
  setAttorneysOfJudge: typeof setAttorneysOfJudge,
  fetchAllAttorneys: typeof fetchAllAttorneys
|};

class CaseDetailLoadingScreen extends React.PureComponent<Props> {
  loadActiveAppealAndTask = () => {
    const {
      appealId,
      appealDetails,
      tasks,
      userRole
    } = this.props;

    const appealPromise = ApiUtil.get(`/appeals/${appealId}`).then((response) => {
      this.props.onReceiveAppealDetails({ appeals: prepareAppealDetailsForStore([response.body.appeal]) });
    });
    const taskPromise = ApiUtil.get(`/appeals/${appealId}/tasks?role=${userRole}`).then((response) => {
      this.props.onReceiveTasks({ tasks: prepareTasksForStore(response.body.tasks) })
    })
    let promises = []; 

    if (!appealDetails || !(appealId in appealDetails)) {
      promises.push(appealPromise);
    }

    if (!tasks || !(appealId in tasks)) {
      promises.push(taskPromise);
    }

    return Promise.all(promises);
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
    this.loadActiveAppealAndTask(),
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

CaseDetailLoadingScreen.propTypes = {
  userId: PropTypes.number.isRequired,
  appealId: PropTypes.string
};

const mapStateToProps = (state: State) => {
  const { tasks, appealDetails } = state.queue;

  return {
    tasks,
    appealDetails,
    loadedUserId: state.ui.loadedUserId
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveTasks,
  onReceiveAppealDetails,
  setAttorneysOfJudge,
  fetchAllAttorneys
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(CaseDetailLoadingScreen): React.ComponentType<Params>);

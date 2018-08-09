// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import { prepareAppealForStore, prepareTasksForStore } from './utils';

import { onReceiveAppealDetails, onReceiveTasks, setAttorneysOfJudge, fetchAllAttorneys } from './QueueActions';
import type { Appeal, Appeals, Tasks } from './types/models';
import type { State, UsersById } from './types/state';
import { USER_ROLES } from './constants';

type Params = {|
  userId: number,
  userCssId: string,
  userRole: string,
  appealId: string,
  children: React.Node,
  userCanAccessQueue: boolean
|};

type Props = Params & {|
  // From state
  tasks: Tasks,
  appealDetails: Appeals,
  loadedUserId: number,
  activeAppeal: Appeal,
  judges: UsersById,
  // Action creators
  setAttorneysOfJudge: typeof setAttorneysOfJudge,
  fetchAllAttorneys: typeof fetchAllAttorneys,
  onReceiveTasks: typeof onReceiveTasks,
  onReceiveAppealDetails: typeof onReceiveAppealDetails
|};

class CaseDetailLoadingScreen extends React.PureComponent<Props> {
  loadActiveAppealAndTask = () => {
    const {
      appealId,
      appealDetails,
      tasks,
      userRole
    } = this.props;

    const promises = [];

    if (!appealDetails || !(appealId in appealDetails)) {
      promises.push(
        ApiUtil.get(`/appeals/${appealId}`).then((response) => {
          this.props.onReceiveAppealDetails(prepareAppealForStore([response.body.appeal]));
        })
      );
    }

    if (!tasks || _.filter(tasks, (task) => task.externalAppealId === appealId).length === 0) {
      promises.push(
        ApiUtil.get(`/appeals/${appealId}/tasks?role=${userRole}`).then((response) => {
          this.props.onReceiveTasks({ tasks: prepareTasksForStore(response.body.tasks) });
        })
      );
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
    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load this case.<br />
      Please <a onClick={this.reload}>refresh the page</a> and try again.
    </div>;

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading this case...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load this case'
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

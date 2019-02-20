import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import { prepareAppealForStore, prepareAllTasksForStore } from './utils';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';

import { onReceiveAppealDetails, onReceiveTasks, setAttorneysOfJudge, fetchAllAttorneys } from './QueueActions';

class CaseDetailLoadingScreen extends React.PureComponent {
  loadActiveAppealAndTask = () => {
    const {
      appealId,
      appealDetails,
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

    const taskPromise = ApiUtil.get(`/appeals/${appealId}/tasks?role=${userRole}`).then((response) => {

      const allTasks = prepareAllTasksForStore(response.body.tasks);

      this.props.onReceiveTasks({
        tasks: allTasks.tasks,
        amaTasks: allTasks.amaTasks
      });

    });

    promises.push(taskPromise);

    return Promise.all(promises);
  };

  loadAttorneysOfJudge = () => {
    return ApiUtil.get(`/users?role=Attorney&judge_id=${this.props.userId}`).
      then(
        (resp) => {
          this.props.setAttorneysOfJudge(resp.body.attorneys);
        });
  }

  maybeLoadJudgeData = () => {
    if (this.props.userRole !== USER_ROLE_TYPES.judge) {
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

const mapStateToProps = (state) => {
  const { amaTasks, tasks, appealDetails } = state.queue;

  return {
    caseflowTasks: amaTasks,
    vacolsTasks: tasks,
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

export default (connect(mapStateToProps, mapDispatchToProps)(CaseDetailLoadingScreen));

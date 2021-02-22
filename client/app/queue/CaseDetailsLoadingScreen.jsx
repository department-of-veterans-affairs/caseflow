import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import WindowUtil from '../util/WindowUtil';
import { prepareAppealForStore, prepareAllTasksForStore } from './utils';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES';
import COPY from '../../COPY';
import PropTypes from 'prop-types';

import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState
} from './uiReducer/uiActions';
import { onReceiveAppealDetails, onReceiveTasks, setAttorneysOfJudge, fetchAllAttorneys } from './QueueActions';

class CaseDetailsLoadingScreen extends React.PureComponent {
  componentWillUnmount = () => {
    if (!this.props.preventReset) {
      this.props.resetSaveState();
      this.props.resetSuccessMessages();
      this.props.resetErrorMessages();
    }
  }

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

  render = () => {
    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load this case.<br />
      Please <a onClick={WindowUtil.reloadWithPOST}>refresh the page</a> and try again.
    </div>;

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      key={this.props.appealId}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading this case...'
      }}
      failStatusMessageProps={{
        title: COPY.CASE_DETAILS_LOADING_FAILURE_TITLE
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
  fetchAllAttorneys,
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState
}, dispatch);

CaseDetailsLoadingScreen.propTypes = {
  children: PropTypes.array,
  appealId: PropTypes.string,
  userId: PropTypes.number,
  onReceiveTasks: PropTypes.func,
  userRole: PropTypes.string,
  appealDetails: PropTypes.object,
  onReceiveAppealDetails: PropTypes.func,
  setAttorneysOfJudge: PropTypes.func,
  fetchAllAttorneys: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  resetSaveState: PropTypes.func,
  preventReset: PropTypes.bool
};

export default (connect(mapStateToProps, mapDispatchToProps)(CaseDetailsLoadingScreen));

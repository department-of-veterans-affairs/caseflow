import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import { getMinutesToMilliseconds } from '../util/DateUtil';
import { associateTasksWithAppeals } from './utils';

import {
  onReceiveQueue,
  setAttorneysOfJudge,
  fetchAllAttorneys,
  fetchVhaProgramOffices,
  fetchAmaTasksOfUser,
  fetchCamoTasks,
  fetchSpecialtyCaseTeamTasks
} from './QueueActions';
import { setUserId, setTargetUser } from './uiReducer/uiActions';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES';
import WindowUtil from '../util/WindowUtil';

class QueueLoadingScreen extends React.PureComponent {
  loadAmaQueue = (chosenUserId) => {
    const {
      userId,
      userRole,
      type,
      userIsCamoEmployee,
      userIsSCTCoordinator
    } = this.props;

    this.props.setUserId(userId);

    // Get the user role in the url params if this is an assign queue page
    const urlSearchParams = new URLSearchParams(window.location.search);
    const role = urlSearchParams.get('role');

    if (role === 'camo' && userIsCamoEmployee && type === 'assign') {
      return this.props.fetchCamoTasks(chosenUserId, userRole, type);
    }

    if (role === 'sct_coordinator' && userIsSCTCoordinator && type === 'assign') {
      return this.props.fetchSpecialtyCaseTeamTasks(chosenUserId, userRole, type);
    }

    return this.props.fetchAmaTasksOfUser(chosenUserId, userRole, type);
  }

  loadLegacyQueue = (chosenUserId) => {
    const {
      userId,
      userRole
    } = this.props;

    if (userRole !== USER_ROLE_TYPES.attorney && userRole !== USER_ROLE_TYPES.judge) {
      return Promise.resolve();
    }

    const urlToLoad = this.props.urlToLoad || `/queue/${chosenUserId}`;
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
    if (!this.props.loadJudgeData || !this.props.loadAttorneys) {
      return Promise.resolve();
    }

    this.props.fetchAllAttorneys();

    return ApiUtil.get(`/users?role=Attorney&judge_id=${chosenUserId}`).
      then((resp) => this.props.setAttorneysOfJudge(resp.body.attorneys));
  }

  maybeLoadCamoData = (userIsCamoEmployee) => {
    if (!userIsCamoEmployee) {
      return Promise.resolve();
    }

    this.props.fetchVhaProgramOffices();
  }

  maybeLoadTargetUserInfo = () => {
    const userUrlParam = this.props.match?.params.userId;

    if (!userUrlParam) {
      return Promise.resolve();
    }

    if (this.isUserId(userUrlParam)) {
      const targetUserId = parseInt(userUrlParam, 10);

      return ApiUtil.get(`/user?id=${targetUserId}`).then((resp) => {
        this.props.setTargetUser(resp.body.user);

        // Ensure the user is returned
        return resp.body.user;
      });
    }

    return ApiUtil.get(`/user?css_id=${userUrlParam}`).then((resp) => {
      this.props.setTargetUser(resp.body.user);

      // Ensure the user is returned
      return resp.body.user;
    });
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
    return this.maybeLoadTargetUserInfo().then((result) => {
      const chosenUserId = result?.id || this.props.targetUserId || this.props.userId;
      const userIsCamoEmployee = this.props.userIsCamoEmployee;

      return Promise.all([
        this.loadAmaQueue(chosenUserId),
        this.loadLegacyQueue(chosenUserId),
        this.maybeLoadJudgeData(chosenUserId),
        this.maybeLoadCamoData(userIsCamoEmployee)
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
  fetchVhaProgramOffices: PropTypes.func,
  fetchAmaTasksOfUser: PropTypes.func,
  fetchCamoTasks: PropTypes.func,
  fetchSpecialtyCaseTeamTasks: PropTypes.func,
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
  type: PropTypes.string,
  urlToLoad: PropTypes.string,
  // `userId` refers to logged-in user and provided by app/views/queue/index.html.erb via QueueApp.jsx
  userId: PropTypes.number,
  userCssId: PropTypes.string,
  userRole: PropTypes.string,
  loadJudgeData: PropTypes.bool,
  userIsCamoEmployee: PropTypes.bool,
  userIsSCTCoordinator: PropTypes.bool
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
  fetchVhaProgramOffices,
  fetchAmaTasksOfUser,
  fetchCamoTasks,
  fetchSpecialtyCaseTeamTasks,
  setUserId,
  setTargetUser
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(QueueLoadingScreen));

import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import { NavLink } from 'react-router-dom';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import { fullWidth } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import ApiUtil from '../util/ApiUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SmallLoader from '../components/SmallLoader';
import { LOGO_COLORS } from '../constants/AppConstants';
import {
  setAttorneysOfJudge, fetchTasksAndAppealsOfAttorney, setSelectionOfTaskOfUser, fetchAllAttorneys
} from './QueueActions';
import { unassignedAppealsSelector, getAppealsByUserId } from './selectors';
import { sortTasks } from './utils';
import PageRoute from '../components/PageRoute';
import AssignedCasesPage from './AssignedCasesPage';
import UnassignedCasesPage from './UnassignedCasesPage';

class JudgeAssignTaskListView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();
  };

  switchLink = () => <Link to={`/queue/${this.props.userId}/review`}>Switch to Review Cases</Link>

  createLoadPromise = () => {
    this.props.fetchAllAttorneys();

    const requestOptions = {
      timeout: true
    };

    return ApiUtil.get(`/users?role=Attorney&judge_css_id=${this.props.userCssId}`, requestOptions).
      then(
        (response) => {
          const resp = JSON.parse(response.text);

          this.props.setAttorneysOfJudge(resp.attorneys);
          for (const attorney of resp.attorneys) {
            this.props.fetchTasksAndAppealsOfAttorney(attorney.id);
          }
        });
  }

  caseCountOfAttorney = (attorneyId) => {
    const { tasksAndAppealsOfAttorney, appealsByUserId } = this.props;

    return attorneyId in tasksAndAppealsOfAttorney &&
      tasksAndAppealsOfAttorney[attorneyId].state === 'LOADED' ?
      (appealsByUserId[attorneyId] ? appealsByUserId[attorneyId].length.toString() : 0) :
      '?';
  }

  render = () => {
    const { userId, attorneysOfJudge, match } = this.props;

    return <AppSegment filledBackground>
      <div>
        <div {...fullWidth} {...css({ marginBottom: '2em' })}>
          <h1>Assign {this.props.unassignedAppealsCount} Cases</h1>
          {this.switchLink()}
        </div>
        <div className="usa-width-one-fourth">
          <LoadingDataDisplay
            createLoadPromise={this.createLoadPromise}
            errorComponent="span"
            failStatusMessageProps={{ title: 'Unknown failure' }}
            failStatusMessageChildren={<span>Failed to load sidebar</span>}
            loadingComponent={SmallLoader}
            loadingComponentProps={{
              message: 'Loading...',
              spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
              component: 'span'
            }}>
            <ul className="usa-sidenav-list">
              <li>
                <NavLink to={`/queue/${userId}/assign`} activeClassName="usa-current" exact>
                  Cases to Assign ({this.props.unassignedAppealsCount})
                </NavLink>
              </li>
              {attorneysOfJudge.
                map((attorney) => <li key={attorney.id}>
                  <NavLink to={`/queue/${userId}/assign/${attorney.id}`} activeClassName="usa-current" exact>
                    {attorney.full_name} ({this.caseCountOfAttorney(attorney.id)})
                  </NavLink>
                </li>)}
            </ul>
          </LoadingDataDisplay>
        </div>
        <div className="usa-width-three-fourths">
          <PageRoute
            exact
            path={match.url}
            title="Cases to Assign | Caseflow"
            render={
              () => <UnassignedCasesPage
                userId={this.props.userId.toString()} />}
          />
          <PageRoute
            path={`${match.url}/:attorneyId`}
            title="Assigned Cases | Caseflow"
            component={AssignedCasesPage}
          />
        </div>
      </div>
    </AppSegment>;
  };
}

JudgeAssignTaskListView.propTypes = {
  attorneysOfJudge: PropTypes.array.isRequired,
  tasksAndAppealsOfAttorney: PropTypes.object.isRequired
};

const mapStateToProps = (state) => {
  const {
    queue: {
      attorneysOfJudge,
      tasksAndAppealsOfAttorney
    },
    ui: {
      featureToggles
    }
  } = state;

  return {
    unassignedAppealsCount: unassignedAppealsSelector(state).length,
    appealsByUserId: getAppealsByUserId(state),
    attorneysOfJudge,
    tasksAndAppealsOfAttorney,
    featureToggles
  };
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState,
    setAttorneysOfJudge,
    fetchTasksAndAppealsOfAttorney,
    setSelectionOfTaskOfUser,
    fetchAllAttorneys
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(JudgeAssignTaskListView);

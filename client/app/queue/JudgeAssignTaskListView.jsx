import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import { NavLink } from 'react-router-dom';

import QueueOrganizationDropdown from './components/QueueOrganizationDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import { fullWidth } from './constants';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SmallLoader from '../components/SmallLoader';
import { LOGO_COLORS } from '../constants/AppConstants';
import {
  fetchTasksAndAppealsOfAttorney,
  fetchAmaTasksOfUser
} from './QueueActions';
import { judgeAssignTasksSelector, getTasksByUserId } from './selectors';
import PageRoute from '../components/PageRoute';
import AssignedCasesPage from './AssignedCasesPage';
import UnassignedCasesPage from './UnassignedCasesPage';

const containerStyles = css({
  position: 'relative'
});

class JudgeAssignTaskListView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();
  };

  createLoadPromise = () => {
    for (const attorney of this.props.attorneysOfJudge) {
      this.props.fetchTasksAndAppealsOfAttorney(attorney.id, { role: 'judge' });
      this.props.fetchAmaTasksOfUser(attorney.id, 'attorney');
    }

    return Promise.resolve();
  }

  caseCountOfAttorney = (attorneyId) => {
    const { attorneyAppealsLoadingState, tasksByUserId } = this.props;

    if (attorneyId in attorneyAppealsLoadingState &&
      attorneyAppealsLoadingState[attorneyId].state === 'LOADED') {
      return tasksByUserId[attorneyId] ? tasksByUserId[attorneyId].length : 0;
    }

    return '?';
  }

  render = () => {
    const { userId,
      attorneysOfJudge,
      organizations,
      match
    } = this.props;

    return <AppSegment filledBackground styling={containerStyles}>
      <div>
        <div {...fullWidth} {...css({ marginBottom: '2em' })}>
          <h1>Assign {this.props.unassignedTasksCount} Cases</h1>
          <QueueOrganizationDropdown organizations={organizations} />
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
                  Cases to Assign ({this.props.unassignedTasksCount})
                </NavLink>
              </li>
              {attorneysOfJudge.
                map((attorney) => <li key={attorney.id}>
                  <NavLink to={`/queue/${userId}/assign/${attorney.id}`} activeClassName="usa-current" exact>
                    {attorney.full_name} ({attorney.active_task_count})
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
  attorneyAppealsLoadingState: PropTypes.object.isRequired
};

const mapStateToProps = (state) => {
  const {
    queue: {
      attorneysOfJudge,
      attorneyAppealsLoadingState
    },
    ui: {
      featureToggles
    }
  } = state;

  return {
    unassignedTasksCount: judgeAssignTasksSelector(state).length,
    tasksByUserId: getTasksByUserId(state),
    attorneysOfJudge,
    attorneyAppealsLoadingState,
    featureToggles
  };
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState,
    fetchTasksAndAppealsOfAttorney,
    fetchAmaTasksOfUser
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(JudgeAssignTaskListView);

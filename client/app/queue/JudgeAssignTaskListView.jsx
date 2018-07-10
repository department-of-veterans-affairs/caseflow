import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import { fullWidth } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { NavLink } from 'react-router-dom';
import ApiUtil from '../util/ApiUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SmallLoader from '../components/SmallLoader';
import { LOGO_COLORS } from '../constants/AppConstants';
import {
  setAttorneysOfJudge, fetchTasksAndAppealsOfAttorney, setSelectionOfTaskOfUser, fetchAllAttorneys
} from './QueueActions';
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

  unassignedTasksWithAppeals = () => {
    const { loadedQueueTasks, appeals, tasks } = this.props;
    const taskWithId = {};

    for (const id of Object.keys(loadedQueueTasks)) {
      taskWithId[id] = tasks[id];
    }

    return sortTasks({
      tasks: taskWithId,
      appeals
    }).
      filter((task) => task.attributes.task_type === 'Assign').
      map((task) => ({
        task,
        appeal: this.props.appeals[task.appealId]
      }));
  }

  switchLink = () => <Link to={`/queue/${this.props.userId}/review`}>Switch to Review Cases</Link>

  createLoadPromise = () => {
    return this.props.fetchAllAttorneys().
      then(
        (attorneys) => {
          const attorneysOfJudgeWithCssId = _.groupBy(attorneys, (attorney) => attorney.judge_css_id);
          const attorneysOfJudge = attorneysOfJudgeWithCssId[this.props.userCssId];
          debugger;

          this.props.setAttorneysOfJudge(attorneysOfJudge);
          for (const attorney of attorneysOfJudge) {
            this.props.fetchTasksAndAppealsOfAttorney(attorney.id);
          }
        });
  }

  caseCountOfAttorney = (attorneyId) => {
    const { tasksAndAppealsOfAttorney } = this.props;

    return attorneyId in tasksAndAppealsOfAttorney &&
        tasksAndAppealsOfAttorney[attorneyId].state === 'LOADED' ?
      Object.keys(tasksAndAppealsOfAttorney[attorneyId].data.tasks).length.toString() :
      '?';
  }

  render = () => {
    const { userId, attorneysOfJudge, match } = this.props;

    return <AppSegment filledBackground>
      <div>
        <div {...fullWidth} {...css({ marginBottom: '2em' })}>
          <h1>Assign {this.unassignedTasksWithAppeals().length} Cases</h1>
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
                  Cases to Assign ({this.unassignedTasksWithAppeals().length})
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
                tasksAndAppeals={this.unassignedTasksWithAppeals()}
                userId={this.props.userId.toString()}
                userCssId={this.props.userCssId} />}
          />
          <PageRoute
            path={`${match.url}/:attorneyId`}
            title="Assigned Cases | Caseflow"
            render={({match}) => <AssignedCasesPage userCssId={this.props.userCssId} match={match} />}
          />
        </div>
      </div>
    </AppSegment>;
  };
}

JudgeAssignTaskListView.propTypes = {
  loadedQueueTasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired,
  attorneysOfJudge: PropTypes.array.isRequired,
  tasksAndAppealsOfAttorney: PropTypes.object.isRequired
};

const mapStateToProps = (state) => {
  const {
    queue: {
      attorneysOfJudge,
      tasksAndAppealsOfAttorney,
      tasks,
      loadedQueue: {
        tasks: loadedQueueTasks,
        appeals
      }
    },
    ui: {
      featureToggles
    }
  } = state;

  return {
    attorneysOfJudge,
    tasksAndAppealsOfAttorney,
    tasks,
    loadedQueueTasks,
    appeals,
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

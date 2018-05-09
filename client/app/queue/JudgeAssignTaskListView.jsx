import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { css } from 'glamor';
import StatusMessage from '../components/StatusMessage';
import JudgeAssignTaskTable from './JudgeAssignTaskTable';
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
import { setAttorneysOfJudge, fetchTasksAndAppealsOfAttorney } from './QueueActions';
import { sortTasks } from './utils';
import PageRoute from '../components/PageRoute';

const UnassignedCasesPage = ({ tasksWithAppeals }) => {
  const reviewableCount = tasksWithAppeals.length;
  let tableContent;

  if (reviewableCount === 0) {
    tableContent = <StatusMessage title="Tasks not found">
       Congratulations! You don't have any cases to assign.
    </StatusMessage>;
  } else {
    tableContent = <React.Fragment>
      <h2>Unassigned Cases</h2>
      <JudgeAssignTaskTable tasksAndAppeals={tasksWithAppeals} />
    </React.Fragment>;
  }

  return tableContent;
};

const AssignedCasesPage = connect(
  (state) => _.pick(state.queue, 'tasksAndAppealsOfAttorney', 'attorneysOfJudge'))(
  (props) => {
    const { match, attorneysOfJudge, tasksAndAppealsOfAttorney } = props;
    const { attorneyId } = match.params;

    if (!(attorneyId in tasksAndAppealsOfAttorney) || tasksAndAppealsOfAttorney[attorneyId].state === 'LOADING') {
      return <SmallLoader message="Loading..." spinnerColor={LOGO_COLORS.QUEUE.ACCENT} />;
    }

    if (tasksAndAppealsOfAttorney[attorneyId].state === 'FAILED') {
      const { error } = tasksAndAppealsOfAttorney[attorneyId];

      return <StatusMessage title={error.response.statusText}>Error fetching cases</StatusMessage>;
    }

    const attorneyName = attorneysOfJudge.filter((attorney) => attorney.id.toString() === attorneyId)[0].full_name;
    const { tasks, appeals } = tasksAndAppealsOfAttorney[attorneyId].data;

    return <React.Fragment>
      <h2>{attorneyName}'s Cases</h2>
      <JudgeAssignTaskTable tasksAndAppeals={
        sortTasks({
          tasks,
          appeals
        }).
          map((task) => ({
            task,
            appeal: appeals[task.vacolsId] }))
      } />
    </React.Fragment>;
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

  unassignedTasksWithAppeals = () => {
    return sortTasks(_.pick(this.props, 'tasks', 'appeals')).
      filter((task) => task.attributes.task_type === 'Assign').
      map((task) => ({
        task,
        appeal: this.props.appeals[task.vacolsId] }));
  }

  switchLink = () => <Link to={`/queue/${this.props.userId}/review`}>Switch to Review Cases</Link>

  createLoadPromise = () => {
    const requestOptions = {
      withCredentials: true,
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

  render = () => {
    const { userId, attorneysOfJudge, tasksAndAppealsOfAttorney, match } = this.props;

    return <AppSegment filledBackground>
      <div>
        <div {...fullWidth} {...css({ marginBottom: '2em' })}>
          <h1>Assign {this.unassignedTasksWithAppeals().length} Cases</h1>
          {this.switchLink(this)}
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
                  Unassigned Cases ({this.unassignedTasksWithAppeals().length})
                </NavLink>
              </li>
              {attorneysOfJudge.
                map((attorney) => <li key={attorney.id}>
                  <NavLink to={`/queue/${userId}/assign/${attorney.id}`} activeClassName="usa-current" exact>
                    {attorney.full_name}{
                      attorney.id in tasksAndAppealsOfAttorney &&
                          tasksAndAppealsOfAttorney[attorney.id].state === 'LOADED' ?
                        ` (${Object.keys(tasksAndAppealsOfAttorney[attorney.id].data.tasks).length})` :
                        ''}
                  </NavLink>
                </li>)}
            </ul>
          </LoadingDataDisplay>
        </div>
        <div className="usa-width-three-fourths">
          <PageRoute
            exact
            path={match.url}
            title="Unassigned Cases | Caseflow"
            render={() => <UnassignedCasesPage tasksWithAppeals={this.unassignedTasksWithAppeals()} />}
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
  tasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired,
  attorneysOfJudge: PropTypes.array.isRequired,
  tasksAndAppealsOfAttorney: PropTypes.object.isRequired
};

const mapStateToProps = (state) => ({
  ..._.pick(state.queue, 'attorneysOfJudge', 'tasksAndAppealsOfAttorney'),
  ..._.pick(state.queue.loadedQueue, 'tasks', 'appeals')
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState,
    setAttorneysOfJudge,
    fetchTasksAndAppealsOfAttorney
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(JudgeAssignTaskListView);

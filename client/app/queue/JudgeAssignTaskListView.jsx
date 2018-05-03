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
import ApiUtil from '../util/ApiUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SmallLoader from '../components/SmallLoader';
import { LOGO_COLORS } from '../constants/AppConstants';
import { setAttorneysOfJudge, setTasksAndAppealsOfAttorney } from './QueueActions';
import { sortTasks, renderAppealType } from './utils';
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
}

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
            ApiUtil.get(`/queue/${attorney.id}`, requestOptions).then(
              (respText) => {
                const resp = JSON.parse(respText.text);

                this.props.setTasksAndAppealsOfAttorney(
                  {attorneyId: attorney.id, tasks: resp.tasks.data, appeals: resp.tasks.data});
              },
              (resp) => {
              }
            );
          }
        });
  }

  render = () => {
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
                <a className="usa-current" disabled>Unassigned Cases</a>
              </li>
              {this.props.attorneysOfJudge.
                map((attorney) => <li key={attorney.id}>
                  <Link to={`/queue/${this.props.userId}/assign/${attorney.id}`}>{attorney.full_name}</Link>
                </li>)}
            </ul>
          </LoadingDataDisplay>
        </div>
        <div className="usa-width-three-fourths">
          <PageRoute
            path={this.props.match.url}
            title="Your Queue | Unassigned Cases"
            render={() => <UnassignedCasesPage tasksWithAppeals={this.unassignedTasksWithAppeals()} />}
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
  tasksOfAttorney: PropTypes.object.isRequired,
  appealsOfAttorney: PropTypes.object.isRequired
};

const mapStateToProps = (state) => ({
  ..._.pick(state.queue, 'attorneysOfJudge', 'tasksOfAttorney', 'appealsOfAttorney'),
  ..._.pick(state.queue.loadedQueue, 'tasks', 'appeals')
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState,
    setAttorneysOfJudge,
    setTasksAndAppealsOfAttorney
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(JudgeAssignTaskListView);

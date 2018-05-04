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
import { setAttorneysOfJudge } from './QueueActions';

class JudgeAssignTaskListView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();
  };

  title = (reviewableCount) => <h1>Assign {reviewableCount} Cases</h1>
  switchLink = () => <Link to={`/queue/${this.props.userId}/review`}>Switch to Review Cases</Link>

  createLoadPromise = () => {
    const requestOptions = {
      withCredentials: true,
      timeout: true
    };
    const url = `/users?role=Attorney&judge_css_id=${this.props.userCssId}`;

    return ApiUtil.get(url, requestOptions).
      then(
        (response) => {
          const resp = JSON.parse(response.text);

          this.props.setAttorneysOfJudge(resp.attorneys);
        });
  }

  render = () => {
    const reviewableCount = _.filter(this.props.tasks, (task) => task.attributes.task_type === 'Assign').length;
    let tableContent;

    if (reviewableCount === 0) {
      tableContent = <div>
        {this.title(reviewableCount)}
        {this.switchLink(this)}
        <StatusMessage title="Tasks not found">
           Congratulations! You don't have any cases to assign.
        </StatusMessage>
      </div>;
    } else {
      tableContent = <div>
        <div {...fullWidth} {...css({ marginBottom: '2em' })}>
          {this.title(reviewableCount)}
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
                map((attorney) => <li><Link to={`/queue/${attorney.id}`}>{attorney.full_name}</Link></li>)}
            </ul>
          </LoadingDataDisplay>
        </div>
        <div className="usa-width-three-fourths">
          <h2>Unassigned Cases</h2>
          <JudgeAssignTaskTable />
        </div>
      </div>;
    }

    return <AppSegment filledBackground>
      {tableContent}
    </AppSegment>;
  };
}

JudgeAssignTaskListView.propTypes = {
  tasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired,
  attorneysOfJudge: PropTypes.array.isRequired
};

const mapStateToProps = (state) => ({
  ..._.pick(state.queue, 'attorneysOfJudge'),
  ..._.pick(state.queue.loadedQueue, 'tasks', 'appeals')
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState,
    setAttorneysOfJudge
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(JudgeAssignTaskListView);

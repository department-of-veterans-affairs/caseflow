import React from 'react';
import PropTypes from 'prop-types';

import ApiUtil from '../../util/ApiUtil';
import BaseForm from '../BaseForm';
import Table from '../../components/Table';
import Button from '../../components/Button';
import { formatDate } from '../../util/DateUtil';

export default class CaseWorkerIndex extends BaseForm {
  constructor(props) {
    super(props);

    this.state = {
      loading: false
    };
  }

  establishNextClaim = () => {
    this.setState({
      loading: true
    });

    ApiUtil.patch('/dispatch/establish-claim/assign').then((response) => {
      window.location = `/dispatch/establish-claim/${response.body.next_task_id}`;
    }, () => {
      this.props.handleAlert(
        'error',
        'Error',
        'There was an error assigning a task. Please try again later'
      );

      this.setState({
        loading: false
      });
    });
  };

  render() {
    let {
      availableTasks,
      buttonText,
      userQuota
    } = this.props;

    let workHistoryColumns = [
      {
        header: 'Veteran',
        valueFunction: (task) =>
          `${task.cached_veteran_name} (${task.vbms_id})`
      },
      {
        header: 'Decision Date',
        valueFunction: (task) => formatDate(task.completed_at)
      },
      {
        header: 'Decision Type',
        valueFunction: (task) => task.cached_decision_type
      },
      {
        header: 'Action',
        valueName: 'completion_status_text'
      }
    ];

    // If the user hasn't completed any tasks, their userQuota is null. In order
    // to not accidentally disable the Establish New Claim button, we set it to -1.
    const tasksRemaining = userQuota ? userQuota.tasks_left_count : -1;

    const HeaderMessage = () => {
      if (tasksRemaining && !availableTasks) {
        return <div>
          <h2>All claims in queue completed</h2>
          <p>There are no more claims to pick up. Please come back later.</p>
        </div>;
      } else if (tasksRemaining && availableTasks) {
        return <div>
          <h2>Get Started!</h2>
          <p>There are claims ready to get picked up for today.</p>
        </div>;
      }

      return <span>
          <h2>Way to go!</h2>
          <p> You have completed all the claims assigned to you.</p> 💪💻🇺🇸<br/>
          <h2 className ="cf-msg-screen-deck cf-success-emoji-text"/>
        </span>;
    };

    return <div className="cf-app-segment cf-app-segment--alt">
          <div className="usa-width-one-whole task-start-wrapper">
            <div className="cf-left-side">
              <h1>Your Work Assignments</h1>
              <HeaderMessage/>
              <span className="cf-button-associated-text-right">
                { userQuota &&
                  `${tasksRemaining} claims in your queue, ${userQuota.tasks_completed_count} claims completed`
                }
              </span>
              <Button
                app="dispatch"
                name={buttonText}
                onClick={this.establishNextClaim}
                classNames={['usa-button-primary', 'cf-push-right',
                  'cf-button-aligned-with-textfield-right']}
                disabled={!availableTasks || !tasksRemaining}
                loading={this.state.loading}
              />
            </div>
          </div>
          <h1>Work History</h1>
          <Table
            columns={workHistoryColumns}
            rowObjects={this.props.currentUserHistoricalTasks}
            id="work-history-table"
            summary="History of issues you've worked"
          />
        </div>;
  }
}

CaseWorkerIndex.propTypes = {
  currentUserHistoricalTasks: PropTypes.array
};

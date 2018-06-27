import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import {
  resetErrorMessages,
  showErrorMessage
} from '../queue/uiReducer/uiActions';
import {
  setSelectedAssigneeOfUser,
  initialAssignTasksToUser
} from '../queue/QueueActions';
import SearchableDropdown from '../components/SearchableDropdown';
import Button from '../components/Button';
import _ from 'lodash';

class AssignWidget extends React.PureComponent {
  selectedTasks = () => {
    return _.flatMap(
      this.props.isTaskAssignedToUserSelected[this.props.previousAssigneeId] || [],
      (selected, id) => (selected ? [this.props.tasks[id]] : []));
  }

  handleButtonClick = () => {
    const { previousAssigneeId, selectedAssigneeOfUser } = this.props;

    if (!selectedAssigneeOfUser[previousAssigneeId]) {
      this.props.showErrorMessage(
        { heading: 'No assignee selected',
          text: 'Please select someone to assign the tasks to.' });

      return;
    }

    if (this.selectedTasks().length === 0) {
      this.props.showErrorMessage(
        { heading: 'No tasks selected',
          text: 'Please select a task.' });

      return;
    }

    this.props.onTaskAssignment(
      { tasks: this.selectedTasks(),
        assigneeId: selectedAssigneeOfUser[previousAssigneeId],
        previousAssigneeId }).
      then(() => this.props.resetErrorMessages()).
      catch(() => this.props.showErrorMessage(
        { heading: 'Error assigning tasks',
          text: 'One or more tasks couldn\'t be assigned.' }));
  }

  render = () => {
    const { previousAssigneeId, attorneysOfJudge, selectedAssigneeOfUser, error } = this.props;
    const options = attorneysOfJudge.map((attorney) => ({ label: attorney.full_name,
      value: attorney.id.toString() }));
    const selectedOption = _.find(options, (option) => option.value === selectedAssigneeOfUser[previousAssigneeId]);

    return <React.Fragment>
      {error &&
        <div className="usa-alert usa-alert-error" role="alert">
          <div className="usa-alert-body">
            <h3 className="usa-alert-heading">{error.heading}</h3>
            <p className="usa-alert-text">{error.text}</p>
          </div>
        </div>}
      <div {...css({ display: 'flex',
        alignItems: 'center' })}>
        <p>Assign to:&nbsp;</p>
        <SearchableDropdown
          name="Assignee"
          hideLabel
          searchable
          options={options}
          placeholder="Select a user"
          onChange={(option) => this.props.setSelectedAssigneeOfUser({ userId: previousAssigneeId,
            assigneeId: option.value })}
          value={selectedOption}
          styling={css({ width: '30rem' })} />
        <p>&nbsp;</p>
        <Button
          onClick={this.handleButtonClick}
          name={`Assign ${this.selectedTasks().length} case(s)`}
          loading={false}
          loadingText="Loading" />
      </div>
    </React.Fragment>;
  }
}

export default connect(
  (state) => {
    const { attorneysOfJudge, selectedAssigneeOfUser, isTaskAssignedToUserSelected, tasks } = state.queue;
    const error = state.ui.messages.error;

    return { attorneysOfJudge,
      selectedAssigneeOfUser,
      isTaskAssignedToUserSelected,
      tasks,
      error };
  },
  (dispatch) => bindActionCreators({ setSelectedAssigneeOfUser,
    initialAssignTasksToUser,
    showErrorMessage,
    resetErrorMessages }, dispatch)
)(AssignWidget);

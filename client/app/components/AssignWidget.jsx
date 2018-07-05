// @flow
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import {
  resetErrorMessages,
  showErrorMessage
} from '../queue/uiReducer/uiActions';
import {
  setSelectedAssignee,
  initialAssignTasksToUser
} from '../queue/QueueActions';
import SearchableDropdown from '../components/SearchableDropdown';
import Button from '../components/Button';
import _ from 'lodash';
import type {
  AttorneysOfJudge, IsTaskAssignedToUserSelected, Tasks, UiStateError, State
} from '../queue/types';
import { ASSIGN_WIDGET_OTHER } from '../../COPY.json';

const OTHER = 'OTHER';

class AssignWidget extends React.PureComponent<{|
  // Parameters
  previousAssigneeId: string,
  onTaskAssignment: Function,
  // From state
  attorneysOfJudge: AttorneysOfJudge,
  selectedAssignee: string,
  isTaskAssignedToUserSelected: IsTaskAssignedToUserSelected,
  tasks: Tasks,
  error: ?UiStateError,
  // Action creators
  setSelectedAssignee: Function,
  initialAssignTasksToUser: Function,
  showErrorMessage: (UiStateError) => void,
  resetErrorMessages: Function
|}> {
  selectedTasks = () => {
    return _.flatMap(
      this.props.isTaskAssignedToUserSelected[this.props.previousAssigneeId] || {},
      (selected, id) => (selected ? [this.props.tasks[id]] : []));
  }

  handleButtonClick = () => {
    const { previousAssigneeId, selectedAssignee } = this.props;

    if (!selectedAssignee) {
      this.props.showErrorMessage(
        { title: 'No assignee selected',
          detail: 'Please select someone to assign the tasks to.' });

      return;
    }

    if (this.selectedTasks().length === 0) {
      this.props.showErrorMessage(
        { title: 'No tasks selected',
          detail: 'Please select a task.' });

      return;
    }

    this.props.onTaskAssignment(
      { tasks: this.selectedTasks(),
        assigneeId: selectedAssignee,
        previousAssigneeId }).
      then(() => this.props.resetErrorMessages()).
      catch(() => this.props.showErrorMessage(
        { title: 'Error assigning tasks',
          detail: 'One or more tasks couldn\'t be assigned.' }));
  }

  render = () => {
    const { previousAssigneeId, attorneysOfJudge, selectedAssignee, error } = this.props;
    const options = attorneysOfJudge.map((attorney) => ({ label: attorney.full_name,
      value: attorney.id.toString() })).concat({ label: ASSIGN_WIDGET_OTHER, value: OTHER});
    const selectedOption = _.find(options, (option) => option.value === selectedAssignee);
    const showOtherSearchBox = selectedAssignee === OTHER;

    return <React.Fragment>
      {error &&
        <div className="usa-alert usa-alert-error" role="alert">
          <div className="usa-alert-body">
            <h3 className="usa-alert-heading">{error.title}</h3>
            <p className="usa-alert-text">{error.detail}</p>
          </div>
        </div>}
      <div {...css({
        display: 'flex',
        alignItems: 'center',
        '& > *': { marginRight: '1rem' }})}>
        <p>Assign to:&nbsp;</p>
        <SearchableDropdown
          name="Assignee"
          hideLabel
          searchable
          options={options}
          placeholder="Select a user"
          onChange={(option) => this.props.setSelectedAssignee({ assigneeId: option.value })}
          value={selectedOption}
          styling={css({ width: '30rem' })} />
        <Button
          onClick={this.handleButtonClick}
          name={`Assign ${this.selectedTasks().length} case(s)`}
          loading={false}
          loadingText="Loading" />
      </div>
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State) => {
  const { attorneysOfJudge, isTaskAssignedToUserSelected, tasks } = state.queue;
  const { selectedAssignee, messages: { error } } = state.ui;

  return {
    attorneysOfJudge,
    selectedAssignee,
    isTaskAssignedToUserSelected,
    tasks,
    error
  };
};

export default connect(
  mapStateToProps,
  (dispatch) => bindActionCreators({
    setSelectedAssignee,
    initialAssignTasksToUser,
    showErrorMessage,
    resetErrorMessages
  }, dispatch)
)(AssignWidget);

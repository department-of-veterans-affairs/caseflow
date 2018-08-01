// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import {
  resetErrorMessages,
  showErrorMessage,
  showSuccessMessage,
  resetSuccessMessages,
  setSelectedAssignee,
  setSelectedAssigneeSecondary
} from '../uiReducer/uiActions';
import SearchableDropdown from '../../components/SearchableDropdown';
import Button from '../../components/Button';
import _ from 'lodash';
import pluralize from 'pluralize';
import COPY from '../../../COPY.json';
import { sprintf } from 'sprintf-js';
import { fullWidth } from '../constants';

import type {
  AttorneysOfJudge, State
} from '../types/state';
import type {
  Task, Attorneys
} from '../types/models';

const OTHER = 'OTHER';

type Params = {|
  previousAssigneeId: string,
  onTaskAssignment: Function,
  selectedTasks: Array<Task>
|};

type Props = Params & {|
  // From state
  attorneysOfJudge: AttorneysOfJudge,
  selectedAssignee: string,
  selectedAssigneeSecondary: string,
  attorneys: Attorneys,
  // Action creators
  setSelectedAssignee: typeof setSelectedAssignee,
  setSelectedAssigneeSecondary: typeof setSelectedAssigneeSecondary,
  showErrorMessage: typeof showErrorMessage,
  resetErrorMessages: typeof resetErrorMessages,
  showSuccessMessage: typeof showSuccessMessage,
  resetSuccessMessages: typeof resetSuccessMessages
|};

class AssignWidget extends React.PureComponent<Props> {
  handleButtonClick = () => {
    const { selectedAssignee, selectedAssigneeSecondary, selectedTasks } = this.props;

    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();

    if (!selectedAssignee) {
      this.props.showErrorMessage(
        { title: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_TITLE,
          detail: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_DETAIL });

      return;
    }

    if (selectedTasks.length === 0) {
      this.props.showErrorMessage(
        { title: COPY.ASSIGN_WIDGET_NO_TASK_TITLE,
          detail: COPY.ASSIGN_WIDGET_NO_TASK_DETAIL });

      return;
    }

    if (selectedAssignee !== OTHER) {
      this.assignTasks(selectedTasks, selectedAssignee);

      return;
    }

    if (!selectedAssigneeSecondary) {
      this.props.showErrorMessage(
        { title: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_TITLE,
          detail: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_DETAIL });

      return;
    }

    this.assignTasks(selectedTasks, selectedAssigneeSecondary);
  }

  assignTasks = (selectedTasks: Array<Task>, assigneeId: string) => {
    const { previousAssigneeId } = this.props;

    this.props.onTaskAssignment(
      { tasks: selectedTasks,
        assigneeId,
        previousAssigneeId }).
      then(() => this.props.showSuccessMessage({
        title: sprintf(COPY.ASSIGN_WIDGET_SUCCESS, {
          numCases: selectedTasks.length,
          casePlural: pluralize('case', selectedTasks.length)
        })
      })).
      catch(() => this.props.showErrorMessage(
        { title: COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_TITLE,
          detail: COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_DETAIL }));
  }

  render = () => {
    const {
      attorneysOfJudge,
      selectedAssignee,
      selectedAssigneeSecondary,
      attorneys,
      selectedTasks
    } = this.props;
    const optionFromAttorney = (attorney) => ({ label: attorney.full_name,
      value: attorney.id.toString() });
    const options = attorneysOfJudge.map(optionFromAttorney).concat({ label: COPY.ASSIGN_WIDGET_OTHER,
      value: OTHER });
    const selectedOption = _.find(options, (option) => option.value === selectedAssignee);
    let optionsOther = [];
    let placeholderOther = COPY.ASSIGN_WIDGET_LOADING;
    let selectedOptionOther = null;

    if (attorneys.data) {
      optionsOther = attorneys.data.map(optionFromAttorney);
      placeholderOther = COPY.ASSIGN_WIDGET_DROPDOWN_PLACEHOLDER;
      selectedOptionOther = _.find(optionsOther, (option) => option.value === selectedAssigneeSecondary);
    }

    if (attorneys.error) {
      placeholderOther = COPY.ASSIGN_WIDGET_ERROR_LOADING_ATTORNEYS;
    }

    return <React.Fragment>
      <div {...css({
        display: 'flex',
        alignItems: 'center',
        flexWrap: 'wrap',
        '& > *': { marginRight: '1rem',
          marginTop: '0',
          marginBottom: '16px' } })}>
        <p>{COPY.ASSIGN_WIDGET_DROPDOWN_PRIMARY_LABEL}</p>
        <SearchableDropdown
          name={COPY.ASSIGN_WIDGET_DROPDOWN_NAME_PRIMARY}
          hideLabel
          searchable
          options={options}
          placeholder={COPY.ASSIGN_WIDGET_DROPDOWN_PLACEHOLDER}
          onChange={(option) => this.props.setSelectedAssignee({ assigneeId: option.value })}
          value={selectedOption}
          styling={css({ width: '30rem' })} />
        {selectedAssignee === OTHER &&
          <React.Fragment>
            <div {...fullWidth} {...css({ marginBottom: '0' })} />
            <p>{COPY.ASSIGN_WIDGET_DROPDOWN_SECONDARY_LABEL}</p>
            <SearchableDropdown
              name={COPY.ASSIGN_WIDGET_DROPDOWN_NAME_SECONDARY}
              hideLabel
              searchable
              options={optionsOther}
              placeholder={placeholderOther}
              onChange={(option) => this.props.setSelectedAssigneeSecondary({ assigneeId: option.value })}
              value={selectedOptionOther}
              styling={css({ width: '30rem' })} />
          </React.Fragment>}
        <Button
          onClick={this.handleButtonClick}
          name={sprintf(
            COPY.ASSIGN_WIDGET_BUTTON_TEXT,
            { numCases: selectedTasks.length,
              casePlural: pluralize('case', selectedTasks.length) })}
          loading={false}
          loadingText={COPY.ASSIGN_WIDGET_LOADING} />
      </div>
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State) => {
  const { attorneysOfJudge, attorneys } = state.queue;
  const { selectedAssignee, selectedAssigneeSecondary } = state.ui;

  return {
    attorneysOfJudge,
    selectedAssignee,
    selectedAssigneeSecondary,
    attorneys
  };
};

export default (connect(
  mapStateToProps,
  (dispatch) => bindActionCreators({
    setSelectedAssignee,
    setSelectedAssigneeSecondary,
    showErrorMessage,
    resetErrorMessages,
    showSuccessMessage,
    resetSuccessMessages
  }, dispatch)
)(AssignWidget): React.ComponentType<Params>);

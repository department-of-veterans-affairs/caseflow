import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';

import {
  setSavePending,
  resetSaveState,
  resetErrorMessages,
  showErrorMessage,
  showSuccessMessage,
  resetSuccessMessages,
  setSelectedAssignee,
  setSelectedAssigneeSecondary
} from '../uiReducer/uiActions';
import SearchableDropdown from '../../components/SearchableDropdown';
import Button from '../../components/Button';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import _ from 'lodash';
import pluralize from 'pluralize';
import COPY from '../../../COPY';
import { sprintf } from 'sprintf-js';
import { fullWidth } from '../constants';
import { taskActionData } from '../utils';

import QueueFlowModal from './QueueFlowModal';

const OTHER = 'OTHER';

class AssignWidget extends React.PureComponent {
  validateForm = () => {
    const { selectedAssignee, selectedAssigneeSecondary, selectedTasks } = this.props;

    if (!selectedAssignee) {
      this.props.showErrorMessage(
        { title: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_TITLE,
          detail: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_DETAIL });

      return false;
    }

    if (selectedTasks.length === 0) {
      this.props.showErrorMessage(
        { title: COPY.ASSIGN_WIDGET_NO_TASK_TITLE,
          detail: COPY.ASSIGN_WIDGET_NO_TASK_DETAIL });

      return false;
    }

    if (selectedAssignee === OTHER && !selectedAssigneeSecondary) {
      this.props.showErrorMessage(
        { title: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_TITLE,
          detail: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_DETAIL });

      return false;
    }

    return true;
  }

  submit = () => {
    const { selectedAssignee, selectedAssigneeSecondary, selectedTasks } = this.props;

    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();

    if (this.props.isModal) {
      // QueueFlowModal will call validateForm
    } else if (!this.validateForm()) {
      return;
    }

    if (selectedAssignee === OTHER) {
      return this.assignTasks(selectedTasks, selectedAssigneeSecondary);
    }

    return this.assignTasks(selectedTasks, selectedAssignee);
  }

  assignTasks = (selectedTasks, assigneeId) => {
    const {
      previousAssigneeId,
      userId
    } = this.props;

    this.props.setSavePending();

    return this.props.onTaskAssignment(
      { tasks: selectedTasks,
        assigneeId,
        previousAssigneeId }).
      then(() => {
        this.props.resetSaveState();

        return this.props.showSuccessMessage({
          title: sprintf(COPY.ASSIGN_WIDGET_SUCCESS, {
            verb: 'Assigned',
            numCases: selectedTasks.length,
            casePlural: pluralize('case', selectedTasks.length)
          })
        });
      }, () => {
        this.props.resetSaveState();

        const errorDetail = this.props.isModal && userId ?
          <React.Fragment>
            <Link to={`/queue/${userId}/assign`}>{COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_DETAIL_MODAL_LINK}</Link>
            {COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_DETAIL_MODAL}
          </React.Fragment> : COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_DETAIL;

        return this.props.showErrorMessage({
          title: COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_TITLE,
          detail: errorDetail });
      });
  }

  render = () => {
    const {
      attorneysOfJudge,
      selectedAssignee,
      selectedAssigneeSecondary,
      attorneys,
      selectedTasks,
      savePending
    } = this.props;
    const optionFromAttorney = (attorney) => ({ label: attorney.full_name,
      value: attorney.id.toString() });
    const options = attorneysOfJudge.map(optionFromAttorney).concat([{ label: COPY.ASSIGN_WIDGET_OTHER,
      value: OTHER }]);
    const selectedOption = _.find(options, (option) => option.value === selectedAssignee);
    let optionsOther = [];
    let placeholderOther = COPY.ASSIGN_WIDGET_LOADING;
    let selectedOptionOther = null;

    if (attorneys.error) {
      placeholderOther = COPY.ASSIGN_WIDGET_ERROR_LOADING_ATTORNEYS;
    }

    if (attorneys.data) {
      optionsOther = attorneys.data.map(optionFromAttorney);
    } else if (this.props.isModal) {
      optionsOther = taskActionData({
        ...this.props,
        task: selectedTasks[0]
      })?.options;
    }

    if (optionsOther?.length) {
      placeholderOther = COPY.ASSIGN_WIDGET_DROPDOWN_PLACEHOLDER;
      selectedOptionOther = _.find(optionsOther, (option) => option.value === selectedAssigneeSecondary);
    }

    const Widget = <React.Fragment>
      <p>{COPY.ASSIGN_WIDGET_DROPDOWN_PRIMARY_LABEL}</p>
      <SearchableDropdown
        name={COPY.ASSIGN_WIDGET_DROPDOWN_NAME_PRIMARY}
        hideLabel
        searchable
        options={options}
        placeholder={COPY.ASSIGN_WIDGET_DROPDOWN_PLACEHOLDER}
        onChange={(option) => option && this.props.setSelectedAssignee({ assigneeId: option.value })}
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
            onChange={(option) => option && this.props.setSelectedAssigneeSecondary({ assigneeId: option.value })}
            value={selectedOptionOther}
            styling={css({ width: '30rem' })} />
        </React.Fragment>}
      {!this.props.isModal && <Button
        onClick={this.submit}
        name={sprintf(
          COPY.ASSIGN_WIDGET_BUTTON_TEXT,
          { numCases: selectedTasks.length,
            casePlural: pluralize('case', selectedTasks.length) })}
        loading={savePending}
        loadingText={COPY.ASSIGN_WIDGET_LOADING} /> }
    </React.Fragment>;

    return this.props.isModal ? <QueueFlowModal title={COPY.ASSIGN_WIDGET_MODAL_TITLE}
      submit={this.submit} validateForm={this.validateForm}>
      {Widget}
    </QueueFlowModal> : Widget;
  }
}

AssignWidget.propTypes = {
  previousAssigneeId: PropTypes.string,
  userId: PropTypes.number,
  setSavePending: PropTypes.func,
  onTaskAssignment: PropTypes.func,
  resetSaveState: PropTypes.func,
  showSuccessMessage: PropTypes.func,
  isModal: PropTypes.bool,
  showErrorMessage: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  attorneysOfJudge: PropTypes.array,
  selectedAssignee: PropTypes.string,
  selectedAssigneeSecondary: PropTypes.string,
  savePending: PropTypes.bool,
  attorneys: PropTypes.shape({
    data: PropTypes.array,
    error: PropTypes.object
  }),
  setSelectedAssignee: PropTypes.func,
  setSelectedAssigneeSecondary: PropTypes.func,
  selectedTasks: PropTypes.array
};

const mapStateToProps = (state) => {
  const { attorneysOfJudge, attorneys } = state.queue;
  const { selectedAssignee, selectedAssigneeSecondary } = state.ui;
  const { savePending } = state.ui.saveState;

  return {
    attorneysOfJudge,
    selectedAssignee,
    selectedAssigneeSecondary,
    attorneys,
    savePending
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setSavePending,
  resetSaveState,
  setSelectedAssignee,
  setSelectedAssigneeSecondary,
  showErrorMessage,
  resetErrorMessages,
  showSuccessMessage,
  resetSuccessMessages
}, dispatch);

export default (connect(
  mapStateToProps,
  mapDispatchToProps
)(AssignWidget));

export const AssignWidgetModal = (connect(mapStateToProps, mapDispatchToProps)(AssignWidget));

import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
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
  setSelectedAssigneeSecondary,
  resetAssignees
} from '../uiReducer/uiActions';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';
import Button from '../../components/Button';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import _ from 'lodash';
import pluralize from 'pluralize';
import COPY from '../../../COPY';
import { sprintf } from 'sprintf-js';
import { fullWidth } from '../constants';
import { ACTIONS } from '../uiReducer/uiConstants';
import { taskActionData } from '../utils';

import QueueFlowModal from './QueueFlowModal';

const OTHER = 'OTHER';

/**
 * Widget used to assign an AttorneyTask to a user. This can be used as an addition to a page or as a modal by passing
 * `isModal` to the component. The component displays attorneys on the judge's team first with an option to select any
 * attorney in caseflow by selecting "Other". The full list of attorneys is preloaded into state for judges in
 * QueueLoadingScreen.
 */
class AssignToAttorneyWidget extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      instructions: (this.props.isModal ? this.props.selectedTasks[0].instructions : null) || ''
    };
  }

  componentDidMount = () => this.props.resetSuccessMessages();

  validAssignee = () => {
    const { selectedAssignee } = this.props;

    if (!selectedAssignee || (selectedAssignee === OTHER && !this.props.selectedAssigneeSecondary)) {
      if (!this.props.isModal) {
        this.props.showErrorMessage(
          { title: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_TITLE,
            detail: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_DETAIL });
      }

      return false;
    }

    return true;

  }

  validTasks = () => {
    if (this.props.selectedTasks.length === 0) {
      if (!this.props.isModal) {
        this.props.showErrorMessage(
          { title: COPY.ASSIGN_WIDGET_NO_TASK_TITLE,
            detail: COPY.ASSIGN_WIDGET_NO_TASK_DETAIL });
      }

      return false;
    }

    return true;
  }

  validInstructions = () => {
    if (this.props.isModal && this.state.instructions.length === 0) {
      return false;
    }

    return true;
  }

  validateForm = () => this.validAssignee() && this.validTasks() && this.validInstructions();

  onCancel = () => {
    this.props.resetAssignees();
    this.props.history.goBack();
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
      return this.assignTasks(selectedTasks, this.getAssignee(selectedAssigneeSecondary));
    }

    return this.assignTasks(selectedTasks, this.getAssignee(selectedAssignee));
  }

  getAssignee = (id) => {
    const { attorneysOfJudge, attorneys, selectedTasks } = this.props;
    let assignee = (attorneysOfJudge.concat(attorneys.data)).find((attorney) => attorney?.id?.toString() === id);

    if (!assignee) {
      // Sometimes attorneys are pulled from task action data. If we can't find the selected attorney in state, check
      // the tasks.
      const option = taskActionData({ ...this.props, task: selectedTasks[0] })?.options.find((opt) => opt.value === id);

      assignee = { id: option.value, full_name: option.label };
    }

    return assignee;
  };

  assignTasks = (selectedTasks, assignee) => {
    const {
      previousAssigneeId,
      userId
    } = this.props;

    const { instructions } = this.state;

    this.props.setSavePending();

    return this.props.onTaskAssignment(
      { tasks: selectedTasks,
        assigneeId: assignee.id,
        previousAssigneeId,
        instructions }).
      then(() => {
        const isReassign = selectedTasks[0].type === 'AttorneyTask';

        this.props.resetAssignees();

        return this.props.showSuccessMessage({
          title: sprintf(COPY.ASSIGN_WIDGET_SUCCESS, {
            verb: isReassign ? 'Reassigned' : 'Assigned',
            numCases: selectedTasks.length,
            casePlural: pluralize('tasks', selectedTasks.length),
            // eslint-disable-next-line camelcase
            assignee: assignee.full_name
          })
        });
      }, (error) => {
        this.props.saveFailure();

        let errorDetail;

        try {
          errorDetail = error.response.body.errors[0].detail;
        } catch (ex) {
          errorDetail = this.props.isModal && userId ?
            <React.Fragment>
              <Link to={`/queue/${userId}/assign`}>{COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_DETAIL_MODAL_LINK}</Link>
              {COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_DETAIL_MODAL}
            </React.Fragment> : COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_DETAIL;
        }

        return this.props.showErrorMessage({
          title: COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_TITLE,
          detail: errorDetail });
      }).
      finally(() => {
        if (!this.props.isModal) {
          this.props.resetSaveState();
        }
      });
  }

  render = () => {
    const {
      attorneysOfJudge,
      selectedAssignee,
      selectedAssigneeSecondary,
      attorneys,
      selectedTasks,
      savePending,
      highlightFormItems,
      isModal
    } = this.props;
    const { instructions } = this.state;
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
    } else if (isModal) {
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
      <SearchableDropdown
        name={COPY.ASSIGN_WIDGET_DROPDOWN_NAME_PRIMARY}
        hideLabel
        searchable
        errorMessage={isModal && highlightFormItems && !selectedOption ? 'Choose one' : null}
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
            errorMessage={isModal && highlightFormItems && !selectedOptionOther ? 'Choose one' : null}
            options={optionsOther}
            placeholder={placeholderOther}
            onChange={(option) => option && this.props.setSelectedAssigneeSecondary({ assigneeId: option.value })}
            value={selectedOptionOther}
            styling={css({ width: '30rem' })} />
        </React.Fragment>}
      {isModal && <React.Fragment>
        <br />
        <TextareaField
          name={COPY.ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL}
          errorMessage={highlightFormItems && instructions.length === 0 ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
          id="taskInstructions"
          onChange={(value) => this.setState({ instructions: value })}
          value={this.state.instructions} />
      </React.Fragment> }
      {!isModal && <Button
        onClick={this.submit}
        name={sprintf(
          COPY.ASSIGN_WIDGET_BUTTON_TEXT,
          { numCases: selectedTasks.length,
            casePlural: pluralize('case', selectedTasks.length) })}
        loading={savePending}
        loadingText={COPY.ASSIGN_WIDGET_LOADING} /> }
    </React.Fragment>;

    return isModal ? <QueueFlowModal title={COPY.ASSIGN_TASK_TITLE}
      submit={this.submit} validateForm={this.validateForm} onCancel={this.onCancel}>
      {Widget}
    </QueueFlowModal> : Widget;
  }
}

AssignToAttorneyWidget.propTypes = {
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
  selectedTasks: PropTypes.array,
  highlightFormItems: PropTypes.bool,
  history: PropTypes.object,
  resetAssignees: PropTypes.func,
  saveFailure: PropTypes.func
};

const mapStateToProps = (state) => {
  const { attorneysOfJudge, attorneys } = state.queue;
  const { selectedAssignee, selectedAssigneeSecondary, highlightFormItems } = state.ui;
  const { savePending } = state.ui.saveState;

  return {
    attorneysOfJudge,
    selectedAssignee,
    selectedAssigneeSecondary,
    attorneys,
    savePending,
    highlightFormItems
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
  resetSuccessMessages,
  resetAssignees,
  saveFailure: () => dispatch({ type: ACTIONS.SAVE_FAILURE })
}, dispatch);

export default (connect(
  mapStateToProps,
  mapDispatchToProps
)(AssignToAttorneyWidget));

export const AssignToAttorneyWidgetModal =
  withRouter(connect(mapStateToProps, mapDispatchToProps)(AssignToAttorneyWidget));

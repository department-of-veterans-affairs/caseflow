import React, { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { useHistory } from 'react-router-dom';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import pluralize from 'pluralize';
import { sprintf } from 'sprintf-js';

import {
  setSavePending,
  resetSaveState,
  resetErrorMessages,
  showErrorMessage,
  showSuccessMessage,
  resetSuccessMessages,
  setSelectedAssignee,
  setSelectedAssigneeSecondary,
  resetAssignees,
  fetchUserInfo
} from '../uiReducer/uiActions';
import SearchableDropdown from 'app/components/SearchableDropdown';
import TextareaField from 'app/components/TextareaField';
import Button from 'app/components/Button';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import COPY from 'app/../COPY';
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
export class AssignToAttorneyWidget extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      instructions: (this.props.isModal ? this.props.selectedTasks[0].instructions : null) || '',
      selectedOptionOther: null,
      selectedOption: null
    };
  }

  componentDidMount = () => this.props.resetSuccessMessages?.();

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

  submit = () => {
    const { selectedAssignee, selectedAssigneeSecondary, selectedTasks } = this.props;

    this.props.resetSuccessMessages?.();
    this.props.resetErrorMessages?.();

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

  getAssignee = (userId) => {
    const { attorneysOfJudge, attorneys, currentUser, selectedTasks } = this.props;

    // Assignee could be the current user
    const judgeOpt = { id: currentUser.id, full_name: currentUser.fullName };
    const assigneeOpts = [...attorneysOfJudge, judgeOpt, ...(attorneys?.data || [])];

    let assignee = assigneeOpts.find((user) => user?.id?.toString() === userId.toString());

    if (!assignee) {
      // Sometimes attorneys are pulled from task action data. If we can't find the selected attorney in state, check
      // the tasks.
      const option = taskActionData({
        ...this.props,
        task: selectedTasks[0],
      })?.options.find((opt) => opt.value === userId);

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
        const isSpecialtyCaseTeamAssignTask = selectedTasks[0]?.assignedTo?.type === 'SpecialtyCaseTeam';

        let titleString = '';

        if (isSpecialtyCaseTeamAssignTask) {
          titleString = sprintf(COPY.SPECIALTY_CASE_TEAM_ASSIGN_WIDGET_SUCCESS, {
            numCases: selectedTasks.length,
            casePlural: pluralize('cases', selectedTasks.length),
            // eslint-disable-next-line camelcase
            assignee: assignee.full_name
          });
        } else {
          titleString = sprintf(COPY.ASSIGN_WIDGET_SUCCESS, {
            verb: isReassign ? 'Reassigned' : 'Assigned',
            numCases: selectedTasks.length,
            casePlural: pluralize('tasks', selectedTasks.length),
            // eslint-disable-next-line camelcase
            assignee: assignee.full_name
          });
        }

        this.props.resetAssignees();
        this.setState({ selectedOptionOther: null, selectedOption: null });

        return this.props.showSuccessMessage({
          title: titleString
        });
      }, (error) => {
        this.props.saveFailure();

        let errorDetail;

        errorDetail = error?.response?.body?.errors[0]?.detail;

        // eslint-disable-next-line no-undefined
        if (errorDetail === null || errorDetail === undefined) {
          if (this.props.isModal && userId) {
            errorDetail =
            <React.Fragment>
              <Link to={`/queue/${userId}/assign`}>{COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_DETAIL_MODAL_LINK}</Link>
              {COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_DETAIL_MODAL}
            </React.Fragment>;
          } else {
            errorDetail = COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_DETAIL;
          }
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
      attorneys,
      attorneysOfJudge,
      currentUser,
      selectedAssignee,
      selectedTasks,
      savePending,
      highlightFormItems,
      isModal,
      onCancel,
      hidePrimaryAssignDropdown,
      secondaryAssignDropdownLabel,
      pathAfterSubmit
    } = this.props;
    const { instructions, selectedOption, selectedOptionOther } = this.state;
    const optionFromAttorney = (attorney) => ({ label: attorney.full_name,
      value: attorney.id.toString() });
    const otherOpt = { label: COPY.ASSIGN_WIDGET_OTHER, value: OTHER };
    const judgeOpt = currentUser ? { label: currentUser.fullName, value: currentUser.id } : null;
    const options = [...attorneysOfJudge.map(optionFromAttorney), ...(judgeOpt ? [judgeOpt] : []), otherOpt];

    let optionsOther = [];
    let placeholderOther = COPY.ASSIGN_WIDGET_LOADING;

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
      placeholderOther = hidePrimaryAssignDropdown ?
        COPY.SCT_ASSIGN_WIDGET_DROPDOWN_PLACEHOLDER : COPY.ASSIGN_WIDGET_DROPDOWN_PLACEHOLDER;
    }

    const otherDropdownWidth = hidePrimaryAssignDropdown ? '40rem' : '30rem';
    const isButtonDisabled = hidePrimaryAssignDropdown && (selectedTasks.length === 0 || !selectedOptionOther);
    const isModalButtonDisabled = hidePrimaryAssignDropdown && (instructions.length <= 0);

    const Widget = <React.Fragment>
      {!hidePrimaryAssignDropdown && <SearchableDropdown
        name={COPY.ASSIGN_WIDGET_DROPDOWN_NAME_PRIMARY}
        hideLabel
        searchable
        errorMessage={isModal && highlightFormItems && !selectedOption ? 'Choose one' : null}
        options={options}
        placeholder={COPY.ASSIGN_WIDGET_DROPDOWN_PLACEHOLDER}
        onChange={(option) => option && this.props.setSelectedAssignee({ assigneeId: option.value }) &&
         this.setState({ selectedOption: option.value })}
        value={selectedOption}
        styling={css({ width: '30rem' })} />
      }
      {selectedAssignee === OTHER &&
        <React.Fragment>
          <div {...fullWidth} {...css({ marginBottom: '0' })} />
          {!secondaryAssignDropdownLabel && <p>{COPY.ASSIGN_WIDGET_DROPDOWN_SECONDARY_LABEL}</p>}
          <SearchableDropdown
            name={COPY.ASSIGN_WIDGET_DROPDOWN_NAME_SECONDARY}
            hideLabel={!secondaryAssignDropdownLabel}
            label={secondaryAssignDropdownLabel}
            searchable
            errorMessage={isModal && highlightFormItems && !selectedOptionOther ? 'Choose one' : null}
            options={optionsOther}
            placeholder={placeholderOther}
            onChange={(option) => option && this.props.setSelectedAssigneeSecondary({ assigneeId: option.value }) &&
             this.setState({ selectedOptionOther: option.value })}
            value={selectedOptionOther}
            styling={css({ width: otherDropdownWidth })} />
        </React.Fragment>}
      {isModal && <React.Fragment>
        <br />
        <TextareaField
          name={COPY.PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}
          errorMessage={highlightFormItems && instructions.length === 0 ? COPY.INSTRUCTIONS_ERROR_FIELD_REQUIRED : null}
          id="taskInstructions"
          onChange={(value) => this.setState({ instructions: value })}
          value={this.state.instructions} />
      </React.Fragment> }
      {!isModal && <Button
        onClick={this.submit}
        disabled={isButtonDisabled}
        name={sprintf(
          COPY.ASSIGN_WIDGET_BUTTON_TEXT,
          { numCases: selectedTasks.length,
            casePlural: pluralize('case', selectedTasks.length) })}
        loading={savePending}
        loadingText={COPY.ASSIGN_WIDGET_LOADING}
        styling={css({ margin: '1.5rem 0', ...(hidePrimaryAssignDropdown && { position: 'relative', top: '15px' }) })}
      />
      }
      { hidePrimaryAssignDropdown && <div styling={css({ marginBottom: '40px' })} />}
    </React.Fragment>;

    return isModal ? <QueueFlowModal
      title={COPY.ASSIGN_TASK_TITLE}
      submit={this.submit}
      validateForm={this.validateForm}
      onCancel={onCancel}
      submitDisabled={isModalButtonDisabled}
      button={COPY.ASSIGN_TASK_BUTTON}
      pathAfterSubmit={pathAfterSubmit}
    >
      {Widget}
    </QueueFlowModal> : Widget;
  }
}

AssignToAttorneyWidget.propTypes = {
  previousAssigneeId: PropTypes.number,
  userId: PropTypes.number,
  currentUser: PropTypes.shape({
    id: PropTypes.number,
    fullName: PropTypes.string,
  }),
  setSavePending: PropTypes.func,
  onTaskAssignment: PropTypes.func,
  resetSaveState: PropTypes.func,
  showSuccessMessage: PropTypes.func,
  isModal: PropTypes.bool,
  hidePrimaryAssignDropdown: PropTypes.bool,
  secondaryAssignDropdownLabel: PropTypes.string,
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
  saveFailure: PropTypes.func,
  onCancel: PropTypes.func,
  pathAfterSubmit: PropTypes.string
};

const AssignToAttorneyWidgetContainer = (props) => {
  const dispatch = useDispatch();
  const { attorneysOfJudge, attorneys } = useSelector((state) => state.queue);
  const {
    selectedAssignee,
    selectedAssigneeSecondary,
    highlightFormItems,
    loadedUserId: userId,
  } = useSelector((state) => state.ui);
  const { savePending } = useSelector((state) => state.ui.saveState);
  const currentUser = useSelector((state) => state.ui.userInfo);

  useEffect(() => {
    dispatch(fetchUserInfo(userId));
  }, []);

  return (
    <AssignToAttorneyWidget
      attorneys={attorneys}
      attorneysOfJudge={attorneysOfJudge}
      currentUser={currentUser}
      selectedAssignee={selectedAssignee}
      selectedAssigneeSecondary={selectedAssigneeSecondary}
      highlightFormItems={highlightFormItems}
      savePending={savePending}
      setSavePending={(val) => dispatch(setSavePending(val))}
      resetSaveState={(val) => dispatch(resetSaveState(val))}
      setSelectedAssignee={(val) => dispatch(setSelectedAssignee(val))}
      setSelectedAssigneeSecondary={(val) => dispatch(setSelectedAssigneeSecondary(val))}
      showErrorMessage={(val) => dispatch(showErrorMessage(val))}
      resetErrorMessages={(val) => dispatch(resetErrorMessages(val))}
      showSuccessMessage={(val) => dispatch(showSuccessMessage(val))}
      resetSuccessMessages={(val) => dispatch(resetSuccessMessages(val))}
      resetAssignees={() => dispatch(resetAssignees())}
      saveFailure={() => dispatch({ type: ACTIONS.SAVE_FAILURE })}
      {...props}
    />
  );
};

export default AssignToAttorneyWidgetContainer;

export const AssignToAttorneyWidgetModal = (props) => {
  const { goBack } = useHistory();
  const dispatch = useDispatch();

  const handleCancel = () => {
    dispatch(resetAssignees());
    goBack();
  };

  return (
    <AssignToAttorneyWidgetContainer
      onCancel={handleCancel}
      {...props}
    />
  );
};

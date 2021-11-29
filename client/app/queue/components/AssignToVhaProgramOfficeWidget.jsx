import React, { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
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
  resetAssignees,
  fetchUserInfo
} from '../uiReducer/uiActions';
import SearchableDropdown from 'app/components/SearchableDropdown';
import Button from 'app/components/Button';
import COPY from 'app/../COPY';
import { ACTIONS } from '../uiReducer/uiConstants';
import { taskActionData } from '../utils';

/**
 * Widget used to assign an AssessDocumentationTask to an org.
 * The component displays VhaProgramOffices preloaded into state in QueueLoadingScreen.
 */
export class AssignToVhaProgramOfficeWidget extends React.PureComponent {
  componentDidMount = () => this.props.resetSuccessMessages?.();

  validAssignee = () => {
    const { selectedAssignee } = this.props;

    if (!selectedAssignee) {
      this.props.showErrorMessage({
        title: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_TITLE,
        detail: COPY.CAMO_ASSIGN_WIDGET_NO_ASSIGNEE_DETAIL
      });

      return false;
    }

    return true;

  }

  validTasks = () => {
    if (this.props.selectedTasks.length === 0) {
      this.props.showErrorMessage({
        title: COPY.ASSIGN_WIDGET_NO_TASK_TITLE,
        detail: COPY.ASSIGN_WIDGET_NO_TASK_DETAIL
      });

      return false;
    }

    return true;
  }

  validInstructions = () => {
    // can add instructions validation here in the future if adding a modal
    return true;
  }

  validateForm = () => this.validAssignee() && this.validTasks() && this.validInstructions();

  submit = () => {
    const { selectedAssignee, selectedTasks } = this.props;

    this.props.resetSuccessMessages?.();
    this.props.resetErrorMessages?.();

    if (!this.validateForm()) {
      return;
    }

    return this.assignTasks(selectedTasks, this.getAssignee(selectedAssignee));
  }

  getAssignee = (orgId) => {
    const { vhaProgramOffices, selectedTasks } = this.props;

    const assigneeOpts = [...(vhaProgramOffices?.data || [])];

    let assignee = assigneeOpts.find((org) => org?.id?.toString() === orgId.toString());

    if (!assignee) {
      // Sometimes assignee is pulled from task action data.
      // If we can't find the selected assignee in state, check the tasks.
      const option = taskActionData({
        ...this.props,
        task: selectedTasks[0],
      })?.options.find((opt) => opt.value === orgId);

      assignee = { id: option.value, name: option.label };
    }

    return assignee;
  };

  assignTasks = (selectedTasks, assignee) => {
    const { previousAssigneeId } = this.props;

    this.props.setSavePending();

    return this.props.onTaskAssignment(
      { tasks: selectedTasks,
        assigneeId: assignee.id,
        previousAssigneeId }).
      then(() => {
        const isReassign = selectedTasks[0].type === 'AssessDocumentationTask';

        this.props.resetAssignees();

        return this.props.showSuccessMessage({
          title: sprintf(COPY.ASSIGN_WIDGET_SUCCESS, {
            verb: isReassign ? 'Reassigned' : 'Assigned',
            numCases: selectedTasks.length,
            casePlural: pluralize('tasks', selectedTasks.length),
            // eslint-disable-next-line camelcase
            assignee: assignee.attributes.name
          })
        });
      }, (error) => {
        this.props.saveFailure();

        return this.props.showErrorMessage({
          title: COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_TITLE,
          detail: error.response.body.errors[0].detail });
      }).
      finally(() => {
        this.props.resetSaveState();
      });
  }

  render = () => {
    const {
      vhaProgramOffices,
      selectedAssignee,
      selectedTasks,
      savePending
    } = this.props;
    const optionFromProgramOffice = (programOffice) => ({
      label: programOffice.attributes.name,
      value: programOffice.attributes.id
    });
    const options = [...vhaProgramOffices.data.map(optionFromProgramOffice)];
    const selectedOption = options.find((option) => option.value === selectedAssignee);

    const Widget = <React.Fragment>
      <SearchableDropdown
        name={COPY.ASSIGN_WIDGET_DROPDOWN_NAME_PRIMARY}
        hideLabel
        searchable
        errorMessage={null}
        options={options}
        placeholder={COPY.VHA_ASSIGN_WIDGET_DROPDOWN_PLACEHOLDER}
        onChange={(option) => option && this.props.setSelectedAssignee({ assigneeId: option.value })}
        value={selectedOption}
        styling={css({ width: '30rem' })} />
      <Button
        onClick={this.submit}
        name={sprintf(
          COPY.VHA_ASSIGN_WIDGET_BUTTON_TEXT,
          { numCases: selectedTasks.length,
            casePlural: pluralize('case', selectedTasks.length) })}
        loading={savePending}
        loadingText={COPY.ASSIGN_WIDGET_LOADING} />
    </React.Fragment>;

    return Widget;
  }
}

AssignToVhaProgramOfficeWidget.propTypes = {
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
  showErrorMessage: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  selectedAssignee: PropTypes.number,
  savePending: PropTypes.bool,
  vhaProgramOffices: PropTypes.shape({
    data: PropTypes.array,
    error: PropTypes.object
  }),
  setSelectedAssignee: PropTypes.func,
  selectedTasks: PropTypes.array,
  highlightFormItems: PropTypes.bool,
  history: PropTypes.object,
  resetAssignees: PropTypes.func,
  saveFailure: PropTypes.func,
  onCancel: PropTypes.func,
};

const AssignToVhaProgramOfficeWidgetContainer = (props) => {
  const dispatch = useDispatch();
  const { vhaProgramOffices } = useSelector((state) => state.queue);
  const {
    selectedAssignee,
    highlightFormItems,
    loadedUserId: userId,
  } = useSelector((state) => state.ui);
  const { savePending } = useSelector((state) => state.ui.saveState);
  const currentUser = useSelector((state) => state.ui.userInfo);

  useEffect(() => {
    dispatch(fetchUserInfo(userId));
  }, []);

  return (
    <AssignToVhaProgramOfficeWidget
      vhaProgramOffices={vhaProgramOffices}
      currentUser={currentUser}
      selectedAssignee={selectedAssignee}
      highlightFormItems={highlightFormItems}
      savePending={savePending}
      setSavePending={(val) => dispatch(setSavePending(val))}
      resetSaveState={(val) => dispatch(resetSaveState(val))}
      setSelectedAssignee={(val) => dispatch(setSelectedAssignee(val))}
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

export default AssignToVhaProgramOfficeWidgetContainer;


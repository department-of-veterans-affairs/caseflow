import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { requestPatch } from '../uiReducer/uiActions';
import { INTAKE_FORM_TASK_TYPES, marginTop } from '../constants';
import QueueFlowModal from '../components/QueueFlowModal';
import TextareaField from 'app/components/TextareaField';
import SearchableDropdown from 'app/components/SearchableDropdown';
import Alert from 'app/components/Alert';
import COPY from '../../../COPY';
import {
  changeTaskTypeNotRelatedToAppeal,
  setTaskNotRelatedToAppealBanner
} from 'app/queue/correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';

const CorrespondenceChangeTaskTypeModal = (props) => {
  const { error } = props;
  const [typeOption, setTypeOption] = useState(null);
  const [instructions, setInstructions] = useState('');

  const validateForm = () => Boolean(typeOption) && Boolean(instructions);

  const submit = () => {
    const payload = {
      data: {
        task: {
          type: typeOption.value.klass,
          instructions
        }
      }
    };

    const typeNames = {
      oldType: props.task.label,
      newType: typeOption.label
    };

    const updatedTasks = props.correspondenceInfo.tasksUnrelatedToAppeal.map((filteredTask) => {
      if (parseInt(filteredTask.uniqueId, 10) === parseInt(props.task_id, 10)) {
        filteredTask.label = typeOption.label;
        filteredTask.instructions.push(instructions);
      }

      return filteredTask;
    });

    const tempCor = props.correspondenceInfo;

    tempCor.tasksUnrelatedToAppeal = updatedTasks;

    return props.changeTaskTypeNotRelatedToAppeal(props.task_id, payload, typeNames, tempCor);
  };

  const actionForm = () => (
    <>
      <div>
        <div {...marginTop(4)}>
          <SearchableDropdown
            name={COPY.CHANGE_TASK_TYPE_ACTION_LABEL}
            placeholder="Select an action type..."
            options={INTAKE_FORM_TASK_TYPES.unrelatedToAppeal}
            onChange={(option) => option && setTypeOption(option)}
            value={typeOption?.value.klass}
          />
        </div>
        <div {...marginTop(4)}>
          <TextareaField
            name={COPY.CHANGE_TASK_TYPE_INSTRUCTIONS_LABEL}
            onChange={setInstructions}
            value={instructions}
          />
        </div>
      </div>
    </>
  );

  return (
    <QueueFlowModal
      validateForm={validateForm}
      submit={submit}
      title={COPY.CHANGE_TASK_TYPE_SUBHEAD}
      button={COPY.CHANGE_TASK_TYPE_SUBHEAD}
      pathAfterSubmit={`/queue/correspondence/${props.correspondence_uuid}`}
      submitButtonClassNames={['usa-button']}
      submitDisabled={!validateForm()}
    >
      {error && (
        <Alert title={error.title} type="error">
          {error.detail}
        </Alert>
      )}
      {actionForm()}
    </QueueFlowModal>
  );
};

CorrespondenceChangeTaskTypeModal.propTypes = {
  correspondence_uuid: PropTypes.string,
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  correspondenceInfo: PropTypes.object,
  requestPatch: PropTypes.func,
  changeTaskTypeNotRelatedToAppeal: PropTypes.func,
  task: PropTypes.shape({
    appeal: PropTypes.shape({
      hasCompletedSctAssignTask: PropTypes.bool
    }),
    assignedTo: PropTypes.shape({
      type: PropTypes.string
    }),
    taskId: PropTypes.string,
    type: PropTypes.string,
    label: PropTypes.string,
    onHoldDuration: PropTypes.number
  }),
  task_id: PropTypes.string,
};

const mapStateToProps = (state, ownProps) => ({
  error: state.ui.messages.error,
  task: state.correspondenceDetails.
    correspondenceInfo.tasksUnrelatedToAppeal.find((tsk) => tsk.uniqueId.toString() === ownProps.task_id),
  taskNotRelatedToAppealBanner: state.correspondenceDetails.bannerAlert,
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  setTaskNotRelatedToAppealBanner,
  changeTaskTypeNotRelatedToAppeal
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(CorrespondenceChangeTaskTypeModal));

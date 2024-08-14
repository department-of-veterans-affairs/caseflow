import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';
import { requestPatch } from '../uiReducer/uiActions';
import { taskById } from '../selectors';
import { marginTop } from '../constants';
import { taskActionData } from '../utils';
import QueueFlowModal from '../components/QueueFlowModal';
import TextareaField from "app/components/TextareaField";
import SearchableDropdown from "app/components/SearchableDropdown";
import Alert from "app/components/Alert";
import COPY from '../../../COPY';

const CorrespondenceChangeTaskTypeModal = (props) => {
  const { error, task } = props;
  const taskData = taskActionData(props);
  const [typeOption, setTypeOption] = useState(null);
  const [instructions, setInstructions] = useState('');

  const validateForm = () => Boolean(typeOption) && Boolean(instructions);

  const buildPayload = () => ({
    data: {
      task: {
        type: typeOption.value,
        instructions
      }
    }
  });

  const submit = () => {
    const payload = buildPayload();

    const successMsg = {
      title: sprintf(COPY.CHANGE_TASK_TYPE_CONFIRMATION_TITLE, task.label, typeOption.label),
      detail: COPY.CHANGE_TASK_TYPE_CONFIRMATION_DETAIL
    };

    return requestPatch(`/queue/correspondence/tasks/${task.taskId}/change_task_type`, payload, successMsg).
      then((response) => {
        console.log(response);
      }).
      catch(() => {
        // handle the error from the frontend
      });
  };

  const actionForm = () => (
    <>
      <div>
        <div {...marginTop(4)}>
          <SearchableDropdown
            name={COPY.CHANGE_TASK_TYPE_ACTION_LABEL}
            placeholder="Select an action type..."
            options={taskActionData({ task }).options}
            onChange={(option) => option && setTypeOption(option)}
            value={typeOption?.value}
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
  requestPatch: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string,
    label: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => ({
  error: state.ui.messages.error,
  task: taskById(state, { taskId: ownProps.task_id })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(CorrespondenceChangeTaskTypeModal));

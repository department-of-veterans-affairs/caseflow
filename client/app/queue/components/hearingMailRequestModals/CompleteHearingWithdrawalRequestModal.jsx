import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { taskById, appealWithDetailSelector } from '../../selectors';
import { requestPatch, showErrorMessage } from '../../uiReducer/uiActions';
import { onReceiveAmaTasks } from '../../QueueActions';
import QueueFlowModal from '../QueueFlowModal';
import TextareaField from '../../../components/TextareaField';
import COPY from '../../../../COPY';
import TASK_STATUSES from '../../../../constants/TASK_STATUSES';

const CompleteHearingWithdrawalRequestModal = (props) => {
  const { appealId, appeal, taskId } = props;
  const [instructions, setInstructions] = useState('');
  const [isPosting, setIsPosting] = useState(false);

  const validateForm = () => {
    return instructions !== '';
  };

  const getSuccessMsg = () => {
    return {
      title: `You have successfully withdrawn ${appeal.veteranFullName}'s hearing request`,
      detail: COPY.WITHDRAW_HEARING.AMA.MODAL_BODY
    };
  };

  const submit = () => {
    if (isPosting) {
      return;
    }

    const payload = {
      data: {
        task: {
          instructions,
          status: TASK_STATUSES.completed
        }
      }
    };

    setIsPosting(true);

    return props.
      requestPatch(`/tasks/${taskId}`, payload, getSuccessMsg()).
      then(
        (resp) => {
          setIsPosting(false);
          props.onReceiveAmaTasks(resp.body.tasks.data);
        },
        () => {
          setIsPosting(false)
          props.showErrorMessage({
            title: 'Unable to withdraw hearing.',
            detail: 'Please retry submitting again and contact support if errors persist.',
          });
        }
      );
  };

  return (
    <QueueFlowModal
      title="Mark as complete and withdraw hearing"
      button="Mark as complete & withdraw hearing"
      submitDisabled={!validateForm()}
      validateForm={validateForm}
      submit={submit}
      pathAfterSubmit={`/queue/appeals/${appealId}`}
    >
      <div>By marking this task as complete, you will withdraw the hearing</div>
      <br />
      <div>{COPY.WITHDRAW_HEARING.AMA.MODAL_BODY}</div>
      <br />
      <TextareaField
        label={`${COPY.PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}:`}
        name="instructionsField"
        id="completePostponementInstructions"
        onChange={setInstructions}
        value={instructions}
      />
    </QueueFlowModal>
  );
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps)
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      requestPatch,
      onReceiveAmaTasks,
      showErrorMessage
    },
    dispatch
  );

CompleteHearingWithdrawalRequestModal.propTypes = {
  register: PropTypes.func,
  appealId: PropTypes.string.isRequired,
  taskId: PropTypes.string.isRequired,
  appeal: PropTypes.shape({
    externalId: PropTypes.string,
    veteranFullName: PropTypes.string
  }),
  task: PropTypes.shape({
    taskId: PropTypes.string,
  }),
  requestPatch: PropTypes.func,
  onReceiveAmaTasks: PropTypes.func,
  showErrorMessage: PropTypes.func,
};

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CompleteHearingWithdrawalRequestModal)
);

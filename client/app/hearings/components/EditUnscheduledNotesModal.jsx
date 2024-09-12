import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { sprintf } from 'sprintf-js';

import COPY from '../../../COPY';
import { onReceiveAmaTasks } from '../../queue/QueueActions';
import { showErrorMessage, showSuccessMessage } from '../../queue/uiReducer/uiActions';

import ApiUtil from '../../util/ApiUtil';
import Modal from '../../components/Modal';
import Button from '../../components/Button';
import { UnscheduledNotes } from './UnscheduledNotes';

export const EditUnscheduledNotesModal = ({
  task,
  appeal,
  onCancel,
  ...props
}) => {
  const [loading, setLoading] = useState(false);
  const [unscheduledNotes, setUnscheduledNotes] = useState(task?.unscheduledHearingNotes?.notes);

  const disable = loading || unscheduledNotes === task?.unscheduledHearingNotes?.notes;

  const submit = async () => {
    try {
      const data = {
        task: {
          business_payloads: {
            values: {
              notes: unscheduledNotes
            }
          }
        }
      };

      setLoading(true);
      // Add the google analytics event
      window.analyticsEvent('Hearings', 'Add/edit notes', 'Case Details');

      await ApiUtil.patch(`/tasks/${task.taskId}`, { data }).then((resp) => {
        props.onReceiveAmaTasks(resp.body.tasks.data);
        props.showSuccessMessage({
          title: sprintf(COPY.SAVE_UNSCHEDULED_NOTES_SUCCESS_MESSAGE, appeal?.veteranFullName),
          detail: null
        });
      });
    } catch (err) {
      const error = {
        title: COPY.SAVE_UNSCHEDULED_NOTES_ERROR_TITLE,
        detail: COPY.SAVE_UNSCHEDULED_NOTES_ERROR_DETAIL
      };

      props.showErrorMessage(error);
    } finally {
      setLoading(false);
      // close the modal
      onCancel();
      // Focus the top of the page to display alert
      window.scrollTo(0, 0);
    }
  };

  return (
    <Modal
      title="Edit Notes"
      closeHandler={onCancel}
      confirmButton={<Button disabled={disable} onClick={submit}>Save</Button>}
      cancelButton={<Button linkStyling disabled={loading} onClick={onCancel}>Cancel</Button>}
    >
      <UnscheduledNotes
        onChange={(notes) => setUnscheduledNotes(notes)}
        unscheduledNotes={unscheduledNotes}
        updatedAt={task?.unscheduledHearingNotes?.updatedAt}
        updatedByCssId={task?.unscheduledHearingNotes?.updatedByCssId}
        uniqueId={task?.taskId}
      />
    </Modal>
  );
};

EditUnscheduledNotesModal.propTypes = {
  task: PropTypes.object,
  appeal: PropTypes.object,
  onCancel: PropTypes.func,
  onReceiveAmaTasks: PropTypes.func,
  showErrorMessage: PropTypes.func,
  showSuccessMessage: PropTypes.func
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      onReceiveAmaTasks,
      showErrorMessage,
      showSuccessMessage
    },
    dispatch
  );

export default connect(null, mapDispatchToProps)(EditUnscheduledNotesModal);

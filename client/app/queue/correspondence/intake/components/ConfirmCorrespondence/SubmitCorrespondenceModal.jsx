import React, { useState } from 'react';
import { useHistory } from 'react-router-dom';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import { useSelector } from 'react-redux';
import ApiUtil from 'app/util/ApiUtil';

import {
  CORRESPONDENCE_INTAKE_FORM_SUBMIT_MODAL_TITLE,
  CORRESPONDENCE_INTAKE_FORM_SUBMIT_MODAL_BODY,
} from 'app/../COPY';

export const SubmitCorrespondenceModal = ({ setSubmitCorrespondenceModalVisible }) => {

  const history = useHistory();
  const correspondence = useSelector((state) => state.intakeCorrespondence.currentCorrespondence);
  const relatedCorrespondences = useSelector((state) => state.intakeCorrespondence.relatedCorrespondences);
  const tasksRelatedToAppeal = useSelector((state) => state.intakeCorrespondence.newAppealRelatedTasks);
  const [loading, setLoading] = useState(false);

  const onSubmit = async() => {
    const relatedUuids = relatedCorrespondences.map((corr) => corr.uuid);
    const serializedTasksRelatedToAppeal = tasksRelatedToAppeal.map((task) => ({
      appeal_id: task.appealId,
      task: task.type.task,
      assigned_to: task.type.assigned_to,
      content: task.content
    })
    );
    const submitData = {
      related_correspondence_uuids: relatedUuids,
      tasks_related_to_appeal: serializedTasksRelatedToAppeal
    };

    // console.log(submitData);

    setLoading(true);
    // Where data goes to be submitted before redirecting back to correspondence queue
    await ApiUtil.post(`/queue/correspondence/${correspondence.uuid}`, { data: submitData });
    setLoading(false);
    history.push('/queue/correspondence');
    // return onSubmit();
  };

  const onCancel = () => {
    setSubmitCorrespondenceModalVisible(false);
  };

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel,
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Confirm',
      loading,
      onClick: onSubmit
    },
  ];

  /* eslint-disable camelcase */
  return (
    <Modal
      title={CORRESPONDENCE_INTAKE_FORM_SUBMIT_MODAL_TITLE}
      buttons={buttons}
      closeHandler={onCancel}
      id="submit-correspondence-intake-modal"
    >
      {CORRESPONDENCE_INTAKE_FORM_SUBMIT_MODAL_BODY}
    </Modal>
  );
  /* eslint-enable camelcase */
};

SubmitCorrespondenceModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  loading: PropTypes.bool,
  setSubmitCorrespondenceModalVisible: PropTypes.func,
};

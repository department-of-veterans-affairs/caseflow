import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import { useSelector } from 'react-redux';
import ApiUtil from 'app/util/ApiUtil';
import {
  CORRESPONDENCE_INTAKE_FORM_SUBMIT_MODAL_TITLE,
  CORRESPONDENCE_INTAKE_FORM_SUBMIT_MODAL_BODY,
} from 'app/../COPY';

export const SubmitCorrespondenceModal = ({ setSubmitCorrespondenceModalVisible, setErrorBannerVisible }) => {

  const correspondence = useSelector((state) => state.intakeCorrespondence.currentCorrespondence);
  const relatedCorrespondences = useSelector((state) => state.intakeCorrespondence.relatedCorrespondences);
  const waivedEvidenceTasks = useSelector((state) => state.intakeCorrespondence.waivedEvidenceTasks);
  const relatedAppealIds = useSelector((state) => state.intakeCorrespondence.taskRelatedAppealIds);
  const tasksRelatedToAppeal = useSelector((state) => state.intakeCorrespondence.newAppealRelatedTasks);
  const tasksNotRelatedToAppeal = useSelector((state) => state.intakeCorrespondence.unrelatedTasks);
  const mailTasks = useSelector((state) => state.intakeCorrespondence.mailTasks);
  const [loading, setLoading] = useState(false);

  const onCancel = () => {
    setSubmitCorrespondenceModalVisible(false);
  };

  const handleRouting = (status) => {
    if (status === 201) {
      window.location.href = '/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc';
    } else {
      setErrorBannerVisible(true);
      onCancel();
    }
  };

  const onSubmit = async() => {
    const relatedUuids = relatedCorrespondences.map((corr) => corr.uuid);
    const serializedWaivedEvidenceTasks = waivedEvidenceTasks.map((task) => (
      { task_id: task.id, waive_reason: task.waiveReason }
    ));

    const serializedTasksRelatedToAppeal = tasksRelatedToAppeal.map((task) => ({
      appeal_id: task.appealId,
      klass: task.type.klass,
      assigned_to: task.type.assigned_to,
      content: task.content
    }));

    const serializedTasksNotRelatedToAppeal = tasksNotRelatedToAppeal.map((task) => ({
      klass: task.type.klass,
      assigned_to: task.type.assigned_to,
      content: task.content
    }));

    const submitData = {
      related_correspondence_uuids: relatedUuids,
      tasks_related_to_appeal: serializedTasksRelatedToAppeal,
      waived_evidence_submission_window_tasks: serializedWaivedEvidenceTasks,
      related_appeal_ids: relatedAppealIds,
      tasks_not_related_to_appeal: serializedTasksNotRelatedToAppeal,
      mail_tasks: mailTasks
    };

    setLoading(true);
    // Where data goes to be submitted before redirecting back to correspondence queue
    let status;

    await ApiUtil.post(`/queue/correspondence/${correspondence.uuid}`, { data: submitData }).
      then((response) => {
        status = response.status;
      }).
      // eslint-disable-next-line no-console
      catch((error) => console.log(error.message));

    setLoading(false);
    handleRouting(status);
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
  setErrorBannerVisible: PropTypes.func,
};

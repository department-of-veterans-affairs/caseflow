import React from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';

import { showSuccessMessage, showErrorMessage } from 'app/queue/uiReducer/uiActions';
import { SubstituteAppellantReview } from './SubstituteAppellantReview';
import { calculateEvidenceSubmissionEndDate } from '../tasks/utils';

import { cancel, stepBack, completeSubstituteAppellant } from '../substituteAppellant.slice';
import { getAllTasksForAppeal, appealWithDetailSelector } from 'app/queue/selectors';

import COPY from 'app/../COPY';

export const SubstituteAppellantReviewContainer = () => {
  const { appealId } = useParams();
  const dispatch = useDispatch();
  const history = useHistory();

  const { formData: existingValues } = useSelector(
    (state) => state.substituteAppellant
  );

  const allTasks = useSelector((state) =>
    getAllTasksForAppeal(state, { appealId })
  );

  const findSelectedTasks = (appealTasks, selectedTaskIds) => {
    if (selectedTaskIds === null) {
      return [];
    }
    return appealTasks.filter((task) => selectedTaskIds.indexOf(task.taskId) !== -1);
  };
  const selectedTasks = findSelectedTasks(allTasks, existingValues.taskIds);

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const evidenceSubmissionEndDate = calculateEvidenceSubmissionEndDate({substitutionDate: existingValues.substitutionDate, veteranDateOfDeath: appeal.veteranDateOfDeath, selectedTasks });

  const handleBack = () => {
    dispatch(stepBack());
    history.goBack();
  };
  const handleCancel = () => {
    // Reset Redux store
    dispatch(cancel());

    // Redirect to Case Details page
    history.push(`/queue/appeals/${appealId}`);
  };

  const handleSubmit = async () => {
    // Here we'll dispatch completeSubstituteAppellant action to submit data from Redux to the API
    const payload = {
      source_appeal_id: appealId,
      substitution_date: existingValues.substitutionDate,
      claimant_type: existingValues.claimantType,
      substitute_participant_id: existingValues.participantId,
      evidence_submission_date: evidenceSubmissionEndDate,
      // To-do: populate with appropriate user input
      poa_participant_id: '123456789'
    };

    try {
      const res = await dispatch(completeSubstituteAppellant(payload));

      // Redirect to Case Details page... but maybe for new appeal...?
      dispatch(
        showSuccessMessage({
          title: COPY.SUBSTITUTE_APPELLANT_SUCCESS_TITLE,
          detail: COPY.SUBSTITUTE_APPELLANT_SUCCESS_DETAIL,
        })
      );
      history.push(`/queue/appeals/${res.payload.targetAppeal.uuid}`);
    } catch (error) {
      dispatch(
        showErrorMessage({
          title: 'Error when substituting appellant',
          detail: JSON.parse(error.message).errors[0].detail,
        })
      );
    }
  };

  return (
    <SubstituteAppellantReview
      selectedTasks={selectedTasks}
      existingValues={existingValues}
      evidenceSubmissionEndDate={evidenceSubmissionEndDate}
      appeal={appeal}
      onBack={handleBack}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
    />
  );
};

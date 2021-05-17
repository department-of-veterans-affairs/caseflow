import React, { useMemo } from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';

import { showSuccessMessage, showErrorMessage } from 'app/queue/uiReducer/uiActions';
import { SubstituteAppellantReview } from './SubstituteAppellantReview';
import { calculateEvidenceSubmissionEndDate } from '../tasks/utils';

import { cancel, stepBack, completeSubstituteAppellant } from '../substituteAppellant.slice';
import { getAllTasksForAppeal, appealWithDetailSelector } from 'app/queue/selectors';

import COPY from 'app/../COPY';
import { format } from 'date-fns';

export const SubstituteAppellantReviewContainer = () => {
  const { appealId } = useParams();
  const dispatch = useDispatch();
  const history = useHistory();

  const { formData: existingValues, poa } = useSelector(
    (state) => state.substituteAppellant
  );

  const allTasks = useSelector((state) =>
    getAllTasksForAppeal(state, { appealId })
  );

  const findSelectedTasks = (appealTasks, selectedTaskIds) => {
    if (selectedTaskIds === null) {
      return [];
    }

    return appealTasks.filter((task) => selectedTaskIds.includes(parseInt(task.taskId, 10)));
  };
  const selectedTasks = findSelectedTasks(allTasks, existingValues.taskIds);

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const { relationships } = useSelector((state) => state.substituteAppellant);
  const relationship = useMemo(() => {
    return relationships.find((rel) => String(rel.value) === String(existingValues.participantId));
  }, [relationships, existingValues?.participantId]);

  const evidenceSubmissionEndDate = calculateEvidenceSubmissionEndDate(
    { substitutionDate: existingValues.substitutionDate,
      veteranDateOfDeath: appeal.veteranDateOfDeath,
      selectedTasks });

  const formatSubmissionEndDateToBackend = (endDate) => {
    return evidenceSubmissionEndDate ? format(endDate, 'yyyy-MM-dd') : null;
  };

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

  const buildTaskCreationParameters = () => {
    const taskParams = {};

    const evidenceSubmissionTask = selectedTasks.find(
      (task) => task.type === 'EvidenceSubmissionWindowTask'
    );

    if (evidenceSubmissionTask) {
      taskParams[evidenceSubmissionTask.uniqueId] = {
        hold_end_date: formatSubmissionEndDateToBackend(evidenceSubmissionEndDate)
      };
    }

    return taskParams;
  };

  const handleSubmit = async () => {
    // Here we'll dispatch completeSubstituteAppellant action to submit data from Redux to the API
    const payload = {
      source_appeal_id: appealId,
      substitution_date: existingValues.substitutionDate,
      claimant_type: existingValues.claimantType,
      substitute_participant_id: existingValues.participantId,
      poa_participant_id: poa.poa_participant_id,
      selected_task_ids: existingValues.taskIds,
      task_params: buildTaskCreationParameters()
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
      console.error("Error during substitute appellant appeal creation", error);
      dispatch(
        showErrorMessage({
          title: 'Error when substituting appellant',
          detail: JSON.parse(error.message).errors[0].detail
          // To-do: show error banner on this page to allow user to adjust or copy their input?
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
      relationship={relationship}
      onBack={handleBack}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
    />
  );
};

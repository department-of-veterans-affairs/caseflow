import React, { useMemo } from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';

import { showSuccessMessage, showErrorMessage } from 'app/queue/uiReducer/uiActions';
import { SubstituteAppellantReview } from './SubstituteAppellantReview';
import { calculateEvidenceSubmissionEndDate } from '../tasks/utils';

import { cancel, reset, stepBack, completeSubstituteAppellant } from '../substituteAppellant.slice';
import { getAllTasksForAppeal, appealWithDetailSelector } from 'app/queue/selectors';
import { fetchAppealDetails } from 'app/queue/QueueActions';

import COPY from 'app/../COPY';

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

  const activeTasks = allTasks.filter((task) => {
    return (task.status === 'in_progress' || task.status === 'assigned');
  });

  window.console.log(`active tasks: ${JSON.stringify(activeTasks)}`);

  // get only the active tasks - all tasks that are assigned tasks or in progress

  // Get ids to cancel from unselected active tasks
  const findCancelTaskIds = (activeTaskIds, openTaskIds) => {
    return activeTaskIds.filter((id) => !openTaskIds.includes(id.toString()));
  };
  const cancelTaskIds = findCancelTaskIds(activeTasks, existingValues.openTaskIds);

  const findSelectedTasks = (appealTasks, selectedTaskIds) => {
    if (selectedTaskIds === null) {
      return [];
    }

    return appealTasks.filter((task) => selectedTaskIds.includes(parseInt(task.taskId, 10)));
  };
  const selectedTasks = findSelectedTasks(allTasks, existingValues.closedTaskIds);

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const { relationships } = useSelector((state) => state.substituteAppellant);
  const relationship = useMemo(() => {
    return relationships?.find((rel) => String(rel.value) === String(existingValues.participantId)) ?? null;
  }, [relationships, existingValues?.participantId]);

  const evidenceSubmissionEndDate = calculateEvidenceSubmissionEndDate(
    { substitutionDate: existingValues.substitutionDate,
      veteranDateOfDeath: appeal.veteranDateOfDeath,
      selectedTasks });

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
        hold_end_date: evidenceSubmissionEndDate
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
      poa_participant_id: poa ? poa.poa_participant_id : null,
      // these are task ids to reopen
      selected_task_ids: existingValues.closedTaskIds,
      // these are task ids to cancel
      cancelled_task_ids: cancelTaskIds.length ? cancelTaskIds : null,
      task_params: buildTaskCreationParameters()
    };

    try {
      const res = await dispatch(completeSubstituteAppellant(payload));
      const { targetAppeal } = res.payload;

      // Redirect to Case Details page... but maybe for new appeal...?
      dispatch(
        showSuccessMessage({
          title: COPY.SUBSTITUTE_APPELLANT_SUCCESS_TITLE,
          detail: COPY.SUBSTITUTE_APPELLANT_SUCCESS_DETAIL,
        })
      );

      await dispatch(fetchAppealDetails(targetAppeal.uuid));

      // Route to new appeal stream
      history.push(`/queue/appeals/${res.payload.targetAppeal.uuid}`);

      // Reset Redux store after route transition begins to avoid rendering errors
      dispatch(reset());
    } catch (error) {
      console.error('Error during substitute appellant appeal creation', error);
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

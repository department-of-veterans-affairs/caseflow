/* eslint-disable max-len */
import React, { useMemo } from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';

import { showSuccessMessage, showErrorMessage } from 'app/queue/uiReducer/uiActions';
import { SubstituteAppellantReview } from './SubstituteAppellantReview';
import { calculateEvidenceSubmissionEndDate, openTasksToHide } from '../editCavcRemandTasks/utils';

import { cancel, reset, stepBack, completeSubstituteAppellant } from '../editCavcRemandSubstitution.slice';
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

  // get all active tasks that can be cancelled by user
  const activeTasksToShow = allTasks.filter((task) => {
    return (!openTasksToHide.includes(task.type) && task.status !== 'completed');
  });

  // get array of active Task Ids
  const activeIds = activeTasksToShow.map((task) => {
    return task.taskId;
  });

  // get selected tasks to find unselected tasks by taking the delta between active and unselected.
  const selectedIds = activeIds.filter((id) => existingValues.openTaskIds.includes(parseInt(id, 10)));

  // also need parentIds for selected tasks.
  const parentIds = activeTasksToShow.filter((task) => selectedIds.includes(task.taskId)).map((task) => task.parentId.toString());
  const allSelectedTaskIds = selectedIds.concat(parentIds);

  const findTasksToCancel = (activeTasksIds, openTaskIds) => {
    if (activeTasksIds === null) {
      return [];
    }
    const difference = activeTasksIds.filter((id) => !openTaskIds.includes(id));
    const cancelTaskObjects = activeTasksToShow.filter((task) => difference.includes(task.taskId));

    // check to see if parent and child are the same type. If they aren't, remove parent task.
    for (let i = 0; i < difference.length - 1; i++) {
      if (parseInt(cancelTaskObjects[i].taskId, 10) === cancelTaskObjects[i + 1].parentId) {
        if (cancelTaskObjects[i].type !== cancelTaskObjects[i + 1].type) {
          difference.splice(i, 1);
        }
      }
    }

    return difference;
  };

  const cancelTasks = findTasksToCancel(activeIds, allSelectedTaskIds);

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
      // these are the task ids to be cancelled
      cancelled_task_ids: cancelTasks,
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

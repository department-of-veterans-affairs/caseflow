import React, { useMemo, useState } from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';
import { parseISO } from 'date-fns';

import {
  appealWithDetailSelector,
  getAllTasksForAppeal,
} from 'app/queue/selectors';
import { EditCavcRemandTasksForm } from './editCavcRemandTasksForm';

import {
  cancel,
  stepBack,
  stepForward,
  updateData,
} from '../editCavcRemand.slice';
import {
  cancelledOrCompletedTasksDataForUi,
  openTaskDataForUi
} from './utils';

export const EditCavcRemandTasksView = () => {
  const { appealId } = useParams();
  const dispatch = useDispatch();
  const history = useHistory();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );
  const { formData: existingValues } = useSelector(
    (state) => state.cavcRemand
  );

  const allTasks = useSelector((state) =>
    getAllTasksForAppeal(state, { appealId })
  );
  const activeTasks = useMemo(() => {
    return openTaskDataForUi({ taskData: allTasks });
  }, [allTasks]);

  const cancelledOrCompletedTasks = useMemo(() => {
    return cancelledOrCompletedTasksDataForUi({ taskData: allTasks });
  }, [allTasks]);

  const openSendCavcRemandProcessedLetterTask = activeTasks.find(
    (task) => task.type === 'SendCavcRemandProcessedLetterTask');
  const closedSendCavcRemandProcessedLetterTask = cancelledOrCompletedTasks.find(
    (task) => task.type === 'SendCavcRemandProcessedLetterTask');
  const cancelTaskIds = activeTasks.filter((task) => task.disabled && task.type !== 'MdrTask').map(
    (disTask) => disTask.id);

  const getReActivateTaksIds = () => {
    if (closedSendCavcRemandProcessedLetterTask) {
      return [closedSendCavcRemandProcessedLetterTask.id];
    } else if (openSendCavcRemandProcessedLetterTask) {
      return [openSendCavcRemandProcessedLetterTask.id];
    }

    return [];
  };

  const reActivateTaskIds = getReActivateTaksIds();
  const [selectedCancelTaskIds, setSelectedCancelTaskIds] = useState(existingValues?.cancelTaskIds || []);
  const [selectedReActivateTaskIds, setSelectedReActivateTaskIds] = useState(reActivateTaskIds);

  // These values will be used in the "key details" section
  const nodDate = useMemo(() => parseISO(appeal.nodDate), [appeal.nodDate]);
  const dateOfDeath = useMemo(() => {
    const dod = appeal.veteranDateOfDeath;

    return dod ? parseISO(dod) : null;
  }, [appeal.veteranInfo]);

  const substitutionDate = useMemo(() => {
    const subDate = existingValues.substitutionDate;

    return subDate ? parseISO(subDate) : null;
  }, [existingValues.substitutionDate]);

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
    // Here we'll dispatch updateData action to update Redux store with our form data
    dispatch(
      updateData({
        formData: {
          ...existingValues,
          reActivateTaskIds: selectedReActivateTaskIds.map((taskId) => Number(taskId)),
          cancelTaskIds: selectedCancelTaskIds.map((taskId) => Number(taskId)),
        }
      })
    );

    // Advance progressbar
    dispatch(stepForward());
    // Move to next page
    history.push(`/queue/appeals/${appealId}/edit_cavc_remand/review`);
  };

  return (
    <EditCavcRemandTasksForm
      appealId={appealId}
      existingValues={{ ...existingValues, reActivateTaskIds, cancelTaskIds }}
      nodDate={nodDate}
      dateOfDeath={dateOfDeath}
      substitutionDate={substitutionDate}
      cancelledOrCompletedTasks={cancelledOrCompletedTasks}
      activeTasks={activeTasks}
      onBack={handleBack}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
      setSelectedCancelTaskIds={setSelectedCancelTaskIds}
      setSelectedReActivateTaskIds={setSelectedReActivateTaskIds}
    />
  );
};

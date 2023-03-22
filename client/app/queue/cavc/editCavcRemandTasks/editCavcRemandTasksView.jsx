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

  const [selectedCancelTaskIds, setSelectedCancelTaskIds] = useState(existingValues?.cancelTaskIds || []);
  const [selectedReActivateTaskIds, setSelectedReActivateTaskIds] = useState(existingValues?.reActivateTaskIds || []);

  const allTasks = useSelector((state) =>
    getAllTasksForAppeal(state, { appealId })
  );
  const activeTasks = useMemo(() => {
    return openTaskDataForUi({ taskData: allTasks });
  }, [allTasks]);

  const openSendCavcRemandProcessedLetterTask = activeTasks.find((task) => task.type === 'SendCavcRemandProcessedLetterTask');
  const cancelTaskIds = activeTasks.filter((task) => task.disabled).map((disTask) => disTask.id);

  const cancelledOrCompletedTasks = useMemo(() => {
    return cancelledOrCompletedTasksDataForUi({ taskData: allTasks });
  }, [allTasks]);

  const getReActivateTaksIds = (() => {
    if (cancelledOrCompletedSendCavcRemandProcessedLetterTask) {
      return [cancelledOrCompletedSendCavcRemandProcessedLetterTask.id]
    } else if (openSendCavcRemandProcessedLetterTask) {
      return [openSendCavcRemandProcessedLetterTask.id]
    } else {
      return []
    }
  })

  const cancelledOrCompletedSendCavcRemandProcessedLetterTask = cancelledOrCompletedTasks.find((task) => task.type === 'SendCavcRemandProcessedLetterTask');
  const reActivateTaskIds = getReActivateTaksIds();

  // These values will be used in the "key details" section
  const nodDate = useMemo(() => parseISO(appeal.nodDate), [appeal.nodDate]);
  const dateOfDeath = useMemo(() => {
    const dod = appeal.veteranDateOfDeath;

    return dod ? parseISO(dod) : null;
  }, [appeal.veteranInfo]);

  const substitutionDate = useMemo(
    () => parseISO(existingValues.substitutionDate),
    [existingValues.substitutionDate]
  );

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
  const handleSubmit = async (_formData) => {
    // Here we'll dispatch updateData action to update Redux store with our form data
    console.log("2222222222", selectedReActivateTaskIds);
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
      existingValues={{...existingValues, reActivateTaskIds: reActivateTaskIds, cancelTaskIds: cancelTaskIds}}
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

import React, { useMemo } from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';
import { parseISO } from 'date-fns';

import {
  appealWithDetailSelector,
  getAllTasksForAppeal,
} from 'app/queue/selectors';
import { SubstituteAppellantTasksForm } from './SubstituteAppellantTasksForm';

import {
  stepForward,
  cancel,
  stepBack,
  updateData,
} from '../substituteAppellant.slice';
import { formatTaskData } from './utils';

export const SubstituteAppellantTasksView = () => {
  const { appealId } = useParams();
  const dispatch = useDispatch();
  const history = useHistory();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );
  const allTasks = useSelector((state) =>
    getAllTasksForAppeal(state, { appealId })
  );

  const filteredTasks = useMemo(() => {
    return formatTaskData(allTasks);
  }, [allTasks]);

  const { formData: existingValues } = useSelector(
    (state) => state.substituteAppellant
  );

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
  const handleSubmit = async (formData) => {
    // Here we'll dispatch updateData action to update Redux store with our form data
    dispatch(updateData({ formData }));

    // Advance progressbar
    dispatch(stepForward());

    // Move to next page
    history.push(`/queue/appeals/${appealId}/substitute_appellant/review`);
  };

  return (
    <SubstituteAppellantTasksForm
      appealId={appealId}
      existingValues={existingValues}
      nodDate={nodDate}
      dateOfDeath={dateOfDeath}
      substitutionDate={substitutionDate}
      tasks={filteredTasks}
      onBack={handleBack}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
    />
  );
};

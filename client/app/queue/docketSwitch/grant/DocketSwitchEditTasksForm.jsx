import React, { useMemo, useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  useForm,
  Controller,
  useFieldArray,
  FormProvider,
} from 'react-hook-form';
import { noop } from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { CheckoutButtons } from './CheckoutButtons';
import {
  DOCKET_SWITCH_GRANTED_ADD_TASK_LABEL,
  DOCKET_SWITCH_GRANTED_ADD_TASK_INSTRUCTIONS,
  DOCKET_SWITCH_GRANTED_ADD_TASK_TEXT,
  DOCKET_SWITCH_GRANTED_ADD_TASK_BUTTON,
} from 'app/../COPY';
import { sprintf } from 'sprintf-js';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import { css } from 'glamor';
import ReactMarkdown from 'react-markdown';
import CheckboxGroup from 'app/components/CheckboxGroup';
import Button from 'app/components/Button';
import StringUtil from 'app/util/StringUtil';
import DocketSwitchRemoveTaskConfirmationModal from './DocketSwitchRemoveTaskModal';
import { AddAdminTaskForm } from 'app/queue/colocatedTasks/AddAdminTaskForm/AddAdminTaskForm';
import tasksByDocketType from 'constants/DOCKET_SWITCH_TASKS_BY_DOCKET_TYPE';

const sectionStyle = css({ marginBottom: '24px' });

const schema = yup.object().shape({
  taskIds: yup.array(yup.string()),
  newTasks: yup.array(
    yup.object().shape({
      type: yup.string().required(),
      instructions: yup.string().required(),
    })
  ),
});

export const DocketSwitchEditTasksForm = ({
  defaultValues,
  docketFrom,
  docketTo,
  onBack,
  onCancel,
  onSubmit,
  taskListing = [],
}) => {
  const methods = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
    defaultValues: {
      taskIds: defaultValues?.taskIds ?? taskListing.map((task) => task.id),
      newTasks: defaultValues?.newTasks ?? []
    },
  });
  const { handleSubmit, control, formState, setValue } = methods;
  const { fields, append, remove } = useFieldArray({
    control,
    name: 'newTasks',
  });

  const [tasks, setTasks] = useState({});
  const [mandatoryTasks, setMandatoryTasks] = useState({});
  const [activeTaskId, setActiveTaskId] = useState(null);

  const taskOptions = useMemo(() => {
    return taskListing.map((task) => ({
      label: task.label,
      id: task.taskId.toString(),
    }));
  }, [taskListing]);

  // populate all of our checkboxes on initial render
  useEffect(() => {
    const newValues = {};

    if (defaultValues?.taskIds) {
      defaultValues?.taskIds.forEach((taskId) => (newValues[taskId] = true));
    } else {
      taskListing.forEach((item) => (newValues[item.taskId] = true));
    }

    setTasks(newValues);

    setValue(
      'taskIds',
      defaultValues?.taskIds ?? taskListing.map((task) => task.taskId)
    );
  }, [taskOptions, defaultValues]);

  // Used for display of mandatory tasks
  const mandatoryTaskOptions = useMemo(() => {
    return tasksByDocketType[docketTo].map((item) => ({
      id: item.name,
      label: item.label,
      disabled: true,
    }));
  }, [docketTo]);

  // Preselect all "mandatory" task options
  useEffect(() => {
    const newValues = {};

    mandatoryTaskOptions.forEach((item) => (newValues[item.id] = true));
    setMandatoryTasks(newValues);
  }, [mandatoryTaskOptions]);

  // Used for display in confirmation modal
  const activeTaskLabel = useMemo(() => {
    return activeTaskId ?
      taskListing.find(
        (task) => String(task.taskId) === String(activeTaskId)
      )?.['label'] :
      null;
  }, [activeTaskId]);

  // Updates a variety of things when an optional task is (de)selected
  const updateTaskSelections = (targetTaskId = null) => {
    const updatedTaskId = activeTaskId || targetTaskId;
    const newSelections = {
      ...tasks,
      [updatedTaskId]: !tasks[updatedTaskId],
    };

    // Update visual display
    setTasks(newSelections);
    // Clear value for modal
    setActiveTaskId(null);
    // Update form values
    setValue(
      'taskIds',
      Object.keys(newSelections).filter((key) => newSelections[key])
    );
  };

  // Event handler for change of optional tasks
  const handleTaskChange = (evt) => {
    const targetTaskId = evt.target.id.toString();

    setActiveTaskId(targetTaskId);

    if (!tasks[targetTaskId] === true) {
      updateTaskSelections(targetTaskId);
    }
  };

  // Handler for "cancel" in modal
  const handleCancel = () => {
    setActiveTaskId(null);
  };

  const title = sprintf(
    DOCKET_SWITCH_GRANTED_ADD_TASK_INSTRUCTIONS,
    StringUtil.snakeCaseToCapitalized(docketFrom),
    StringUtil.snakeCaseToCapitalized(docketTo)
  );

  return (
    <FormProvider {...methods}>
      <form
        className="docket-switch-granted-add"
        onSubmit={handleSubmit(onSubmit)}
        aria-label="Grant Docket Switch Add Task"
      >
        <AppSegment filledBackground>
          <h1>{DOCKET_SWITCH_GRANTED_ADD_TASK_LABEL}</h1>
          <div {...sectionStyle}>
            <ReactMarkdown source={title} />
          </div>
          <div>
            <ReactMarkdown
              source={sprintf(
                DOCKET_SWITCH_GRANTED_ADD_TASK_TEXT,
                StringUtil.snakeCaseToCapitalized(docketTo)
              )}
            />
          </div>

          <Controller
            name="taskIds"
            control={control}
            render={({ name }) => {
              return (
                <CheckboxGroup
                  name={name}
                  label="Please unselect any tasks you would like to remove:"
                  strongLabel
                  options={taskOptions}
                  onChange={(event) => handleTaskChange(event)}
                  styling={css({ marginBottom: '0' })}
                  values={tasks}
                />
              );
            }}
          />
          {!taskOptions?.length && (
            <div style={{ marginTop: '1.6rem' }}>
              <em>There are currently no open tasks on this appeal.</em>
            </div>
          )}

          <CheckboxGroup
            name="mandatory"
            label="Task(s) that will automatically be created:"
            strongLabel
            options={mandatoryTaskOptions}
            onChange={noop}
            styling={css({ marginBottom: '0' })}
            values={mandatoryTasks}
          />

          {activeTaskId && (
            <DocketSwitchRemoveTaskConfirmationModal
              onCancel={handleCancel}
              taskLabel={activeTaskLabel}
              onConfirm={updateTaskSelections}
            />
          )}

          <React.Fragment>
            <h3 {...css({ marginBottom: '0' })}>
              <br />
              <strong>Would you like to add any additional tasks?</strong>
              <br />
            </h3>
            <div>
              {fields.map((item, idx) => (
                <AddAdminTaskForm
                  key={item.id}
                  item={item}
                  baseName={`newTasks[${idx}]`}
                  onRemove={() => remove(idx)}
                />
              ))}
            </div>
            <Button
              willNeverBeLoading
              dangerStyling
              styling={css({ marginTop: '1rem' })}
              name={DOCKET_SWITCH_GRANTED_ADD_TASK_BUTTON}
              onClick={() => append({ type: null, instructions: '' })}
            />
          </React.Fragment>
        </AppSegment>
        <div className="controls cf-app-segment">
          <CheckoutButtons
            disabled={!formState.isValid}
            onCancel={onCancel}
            onBack={onBack}
            onSubmit={handleSubmit(onSubmit)}
          />
        </div>
      </form>
    </FormProvider>
  );
};
DocketSwitchEditTasksForm.propTypes = {
  docketFrom: PropTypes.string,
  docketTo: PropTypes.string,
  onBack: PropTypes.func,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  taskListing: PropTypes.array,
  defaultValues: PropTypes.shape({
    taskIds: PropTypes.arrayOf(
      PropTypes.oneOfType([PropTypes.string, PropTypes.number])
    ),
    newTasks: PropTypes.arrayOf(
      PropTypes.shape({
        type: PropTypes.string,
        instructions: PropTypes.string,
      })
    ),
  }),
};

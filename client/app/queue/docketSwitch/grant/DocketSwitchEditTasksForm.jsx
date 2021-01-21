import React, { useMemo, useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  useForm,
  Controller,
  useFieldArray,
  FormProvider,
} from 'react-hook-form';
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
import Button from '../../../components/Button';
import StringUtil from '../../../util/StringUtil';
import DocketSwitchRemoveTaskConfirmationModal from './DocketSwitchRemoveTaskModal';
import { DocketSwitchAddAdminTaskForm } from './DocketSwitchAddAdminTaskForm';

const schema = yup.object().shape({
  taskIds: yup.array(yup.string()),
});

export const DocketSwitchEditTasksForm = ({
  onSubmit,
  onCancel,
  docketFrom,
  docketTo,
  taskListing = [],
  onBack,
}) => {
  const methods = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
    defaultValues: {
      taskIds: taskListing.map((task) => task.id),
    },
  });
  const { handleSubmit, control, formState, setValue } = methods;
  const { fields, append, remove } = useFieldArray({
    control,
    name: 'newTasks',
  });

  const [tasks, setTasks] = useState({});
  const [activeTaskId, setActiveTaskId] = useState(null);

  const sectionStyle = css({ marginBottom: '24px' });

  const taskOptions = useMemo(() => {
    return (
      taskListing &&
      taskListing.map((task) => ({
        label: task.label,
        id: task.taskId.toString(),
      }))
    );
  }, [taskListing]);

  const selectAllTasks = () => {
    const newValues = {};

    taskListing.forEach((item) => (newValues[item.taskId] = true));
    setTasks(newValues);

    setValue('taskIds', taskListing.map((task) => task.taskId));
  };

  const activeTaskLabel = useMemo(() => {
    return activeTaskId ?
      taskListing.find(
        (task) => String(task.taskId) === String(activeTaskId)
      )?.['label'] :
      null;
  }, [activeTaskId]);

  // populate all of our checkboxes on initial render
  useEffect(() => selectAllTasks(), []);

  const updateTaskSelections = (targetTaskId = null) => {
    const updatedTaskId = activeTaskId || targetTaskId;
    const newSelections = {
      ...tasks,
      [updatedTaskId]: !tasks[updatedTaskId],
    };

    setTasks(newSelections);
    setActiveTaskId(null);
    setValue(
      'taskIds',
      Object.keys(newSelections).filter((key) => newSelections[key])
    );
  };

  const handleTaskChange = (evt) => {
    const targetTaskId = evt.target.id.toString();

    setActiveTaskId(targetTaskId);

    if (!tasks[targetTaskId] === true) {
      updateTaskSelections(targetTaskId);
    }
  };

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
            <ReactMarkdown source={DOCKET_SWITCH_GRANTED_ADD_TASK_TEXT} />
          </div>
          <Controller
            name="taskIds"
            control={control}
            render={({ name, onChange: onCheckChange }) => {
              return (
                <CheckboxGroup
                  name={name}
                  label="Please unselect any tasks you would like to remove:"
                  strongLabel
                  options={taskOptions}
                  onChange={(event) => onCheckChange(handleTaskChange(event))}
                  styling={css({ marginBottom: '0' })}
                  values={tasks}
                />
              );
            }}
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
                <DocketSwitchAddAdminTaskForm
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
              onClick={() =>
                append({ type: { value: null, label: '' }, instructions: '' })
              }
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
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  docketFrom: PropTypes.string,
  docketTo: PropTypes.string,
  taskListing: PropTypes.array,
  onBack: PropTypes.func,
};

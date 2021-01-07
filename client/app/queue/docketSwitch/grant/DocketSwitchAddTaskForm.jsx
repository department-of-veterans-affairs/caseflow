import React, { useMemo, useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { useForm, Controller } from 'react-hook-form';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { CheckoutButtons } from './CheckoutButtons';
import {
  DOCKET_SWITCH_GRANTED_ADD_TASK_LABEL,
  DOCKET_SWITCH_GRANTED_ADD_TASK_INSTRUCTIONS,
  DOCKET_SWITCH_GRANTED_ADD_TASK_TEXT,
  DOCKET_SWITCH_GRANTED_ADD_TASK_BUTTON,
  DOCKET_SWITCH_GRANTED_MODAL_TITLE,
  DOCKET_SWITCH_GRANTED_MODAL_INSTRUCTION
} from 'app/../COPY';
import { sprintf } from 'sprintf-js';
import { yupResolver } from '@hookform/resolvers';
import * as yup from 'yup';
import { css } from 'glamor';
import ReactMarkdown from 'react-markdown';
import CheckboxGroup from 'app/components/CheckboxGroup';
import Button from '../../../components/Button';
import _ from 'lodash';
import Modal from '../../../components/Modal';

const schema = yup.object().shape({
  taskList: yup.array(yup.string()).required()
});

export const DocketSwitchAddTaskForm = ({
  onSubmit,
  onCancel,
  docketName,
  taskListing,
  closeModal
}) => {
  const { register, handleSubmit, control, formState, watch } = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
  });

  const [tasks, setTasks] = useState({});
  const sectionStyle = css({ marginBottom: '24px' });

  const taskOptions = useMemo(() => {
    return taskListing && taskListing.map((task) =>
      ({ label: task.label,
        id: task.taskId.toString() }));
  }, [taskListing]);

  const selectedIssues = useMemo(() => {
    return Object.entries(tasks).filter((item) => item[1]).
      flatMap((item) => item[0]);
  }, [tasks]);

  const selectAllIssues = () => {
    const checked = selectedIssues.length === 0;
    const newValues = {};

    taskOptions.forEach((item) => newValues[item.label] = checked);
    setTasks(newValues);
  };

  // populate all of our checkboxes on initial render
  useEffect(() => selectAllIssues(), []);

  const handleChange = (evt) => setTasks({ ...tasks, [evt.target.name]: evt.target.checked });

  // const onIssueChange = (evt) => {
  //   setTasks({ ...tasks, [evt.target.name]: evt.target.checked });
  // };

  const watchTasks = watch('taskList', false);

  console.log('watch', watchTasks);

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: closeModal
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Confirm',
      onClick: () => onSubmit(tasks)
    }
  ];

  return (
    <form
      className="docket-switch-granted-add"
      onSubmit={handleSubmit(onSubmit)}
      aria-label="Grant Docket Switch Add Task"
    >
      <AppSegment filledBackground>
        <h1>{DOCKET_SWITCH_GRANTED_ADD_TASK_LABEL}</h1>
        <div {...sectionStyle}>
          <ReactMarkdown
            source={sprintf(DOCKET_SWITCH_GRANTED_ADD_TASK_INSTRUCTIONS, _.startCase(_.toLower(docketName)))}
          />
        </div>
        <div><ReactMarkdown source={DOCKET_SWITCH_GRANTED_ADD_TASK_TEXT} /></div>

        <CheckboxGroup
          name="taskList"
          label="Please unselect any tasks you would like to remove:"
          strongLabel
          options={taskOptions}
          onChange={handleChange}
          styling={css({ marginBottom: '0' })}
          values={tasks}
          inputRef={register}
        />

        { handleChange && (
          <Modal
            title={DOCKET_SWITCH_GRANTED_MODAL_TITLE}
            onCancel={onCancel}
            onSubmit={onSubmit}
            closeHandler={onCancel}
            buttons={buttons}>
            <div>
              <ReactMarkdown source={DOCKET_SWITCH_GRANTED_MODAL_INSTRUCTION} />
            </div>
          </Modal>
        )
        }

        <React.Fragment>
          <h3 {...css({ marginBottom: '0' })}>
            <br />
            <strong>Would you like to add any additional tasks?
            </strong><br /></h3>
          <Button
            willNeverBeLoading
            dangerStyling
            styling={css({ marginTop: '1rem' })}
            name={DOCKET_SWITCH_GRANTED_ADD_TASK_BUTTON}
          />
        </React.Fragment>
      </AppSegment>
      <div className="controls cf-app-segment">
        <CheckoutButtons
          disabled={!formState.isValid}
          onCancel={onCancel}
          onSubmit={handleSubmit(onSubmit)}
        />
      </div>
    </form>
  );
};
DocketSwitchAddTaskForm.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  docketName: PropTypes.string,
  closeModal: PropTypes.func,
  taskListing: PropTypes.array
};

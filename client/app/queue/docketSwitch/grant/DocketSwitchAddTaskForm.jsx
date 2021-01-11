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
  onBack
}) => {
  const { register, handleSubmit, control, formState } = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
  });

  const [tasks, setTasks] = useState({});
  const [docketTypes, setDocketType] = useState({});
  console.log("taskLabel", tasks);

  const [showModal, setShowModal] = useState(false);

  const sectionStyle = css({ marginBottom: '24px' });

  const taskOptions = useMemo(() => {
    return taskListing && taskListing.map((task) =>
      ({ label: task.label,
        id: task.taskId.toString() }));
  }, [taskListing]);

  const selectedIssues = _.omitBy(tasks, false);

  const selectAllIssues = () => {
    const checked = selectedIssues.length === 0;
    const newValues = {};

    taskListing.forEach((item) => newValues[item.label] === checked);
    setTasks(newValues);
  };

  // const isOther = _.map(taskListing, 'label');

  // populate all of our checkboxes on initial render
  useEffect(() => selectAllIssues(), []);

  const handleChange = (evt) => {
    // const taskLabel = _.find(taskListing, { id: evt.target.name.toString() });
    // setTasks({ ...tasks, [taskLabel]: evt.target.checked });

    setTasks({ ...taskListing, [evt.target.name.toString()] : evt.target.checked });
    setShowModal(!showModal);
  };

  const handleCloseModal = (evt) => {
    setTasks({ ...taskListing, [evt.target.name]: !evt.target.checked });
    setShowModal(!showModal);
  };

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: (event) => handleCloseModal(event)
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
        <Controller
          name="issueIds"
          control={control}
          defaultValue={[]}
          render={({ onChange: onCheckChange }) => {
            return (
              <CheckboxGroup
                name="taskList"
                label="Please unselect any tasks you would like to remove:"
                strongLabel
                options={taskOptions}
                onChange={(event) => onCheckChange(handleChange(event))}
                styling={css({ marginBottom: '0' })}
                values={tasks}
                inputRef={register}
              />
            );
          }}
        />

        { showModal && (
          <Modal
            title={DOCKET_SWITCH_GRANTED_MODAL_TITLE}
            onSubmit={onSubmit}
            closeHandler={(event) => handleCloseModal(event)}
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
          onBack={onBack}
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
  taskListing: PropTypes.array,
  onBack: PropTypes.func
};

import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import Checkbox from '../../../../../components/Checkbox';
import AddAppealRelatedTaskView from './AddAppealRelatedTaskView';
import AddUnrelatedTaskView from './AddUnrelatedTaskView';
import { saveMailTaskState } from '../../../correspondenceReducer/correspondenceActions';
import { INTAKE_FORM_TASK_TYPES } from '../../../../constants';

const mailTasksLeft = [
  'Change of address',
  'Evidence or argument',
  'Returned or undeliverable mail'
];

const mailTasksRight = [
  'Sent to ROJ',
  'VACOLS updated',
  'Associated with Claims Folder'
];

const relatedTaskTypes = INTAKE_FORM_TASK_TYPES.relatedToAppeal;
const unrelatedTaskTypes = INTAKE_FORM_TASK_TYPES.unrelatedToAppeal;

export const AddTasksAppealsView = (props) => {
  const mailTasks = useSelector((state) => state.intakeCorrespondence.mailTasks);
  const [relatedTasksCanContinue, setRelatedTasksCanContinue] = useState(true);
  const [unrelatedTasksCanContinue, setUnrelatedTasksCanContinue] = useState(true);

  const dispatch = useDispatch();

  const filterUnavailableTaskTypeOptions = (tasks, options) => {
    let otherMotionCount = 0;

    const filteredTaskNames = tasks.map((task) => {
      if (task.type === 'Other motion') {
        otherMotionCount += 1;
      }

      return task.type;
    });

    return options.filter((option) => {
      // Up to 2 other motion tasks can be created in the workflow
      // so only filter 'other motion' if there are 2 other motion tasks already created
      if (option.value === 'Other motion' && otherMotionCount < 2) {
        return true;
      }

      return !filteredTaskNames.includes(option.value);
    });
  };

  useEffect(() => {
    props.onContinueStatusChange(relatedTasksCanContinue && unrelatedTasksCanContinue);
  }, [relatedTasksCanContinue, unrelatedTasksCanContinue]);

  return (
    <div className="gray-border" style={{ marginBottom: '2rem', padding: '3rem 4rem' }}>
      <h1 style={{ marginBottom: '10px' }}>Review Tasks & Appeals</h1>
      <p>Review any previously completed tasks by the mail team and add new tasks for
      either the mail package or for linked appeals, if any.</p>
      <div>
        <h2 style={{ margin: '25px auto 15px auto' }}>Mail Tasks</h2>
        <div className="gray-border" style={{ padding: '0rem 2rem' }}>
          <p style={{ marginBottom: '0.5rem' }}>Select any tasks completed by the Mail team for this correspondence.</p>
          <div id="mail-tasks-left" style={{ display: 'inline-block', marginRight: '14rem' }}>
            {mailTasksLeft.map((name, index) => {
              return (
                <Checkbox
                  key={index}
                  name={name}
                  label={name}
                  defaultValue={mailTasks[name] || false}
                  onChange={(isChecked) => dispatch(saveMailTaskState(name, isChecked))}
                />
              );
            })}
          </div>
          <div id="mail-tasks-right" style={{ display: 'inline-block' }}>
            {mailTasksRight.map((name, index) => {
              return (
                <Checkbox
                  key={index}
                  name={name}
                  label={name}
                  defaultValue={mailTasks[name] || false}
                  onChange={(isChecked) => dispatch(saveMailTaskState(name, isChecked))}
                />
              );
            })}
          </div>
        </div>

        <div id="task-not-related-to-an-appeal">
          <h2 style={{ margin: '3rem auto 1rem auto' }}>Tasks not related to an Appeal</h2>
          <p style={{ marginTop: '0rem', marginBottom: '2rem' }}>
            Add new tasks related to this correspondence or to an appeal not yet created in Caseflow.
          </p>
          <div>
            <AddUnrelatedTaskView
              setUnrelatedTasksCanContinue={setUnrelatedTasksCanContinue}
              filterUnavailableTaskTypeOptions={filterUnavailableTaskTypeOptions}
              allTaskTypeOptions={unrelatedTaskTypes}
              autoTexts={props.autoTexts}
            />
          </div>
        </div>

        <div style={{ marginTop: '3.8rem' }}>
          <h2 style={{ margin: '3rem auto 1rem auto' }}>Tasks related to an existing Appeal</h2>
          <p style={{ marginBottom: '0rem' }}>Is this correspondence related to an existing appeal?</p>
          <AddAppealRelatedTaskView
            correspondenceUuid={props.correspondenceUuid}
            setRelatedTasksCanContinue={setRelatedTasksCanContinue}
            filterUnavailableTaskTypeOptions={filterUnavailableTaskTypeOptions}
            allTaskTypeOptions={relatedTaskTypes}
            autoTexts={props.autoTexts}
          />
        </div>
      </div>
    </div>
  );
};

AddTasksAppealsView.propTypes = {
  correspondenceUuid: PropTypes.string.isRequired,
  onContinueStatusChange: PropTypes.func.isRequired,
  autoTexts: PropTypes.arrayOf(PropTypes.string).isRequired
};

export default AddTasksAppealsView;

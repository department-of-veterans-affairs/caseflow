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
];

const mailTasksRight = [
  'Associated with Claims Folder',
  'VACOLS updated',
];

const relatedTaskTypes = INTAKE_FORM_TASK_TYPES.relatedToAppeal;
const unrelatedTaskTypes = INTAKE_FORM_TASK_TYPES.unrelatedToAppeal;

export const AddTasksAppealsView = (props) => {
  const [mailTasks, setMailTasks] = useState(useSelector((state) => state.intakeCorrespondence.mailTasks));
  const [relatedTasksCanContinue, setRelatedTasksCanContinue] = useState(true);
  const [unrelatedTasksCanContinue, setUnrelatedTasksCanContinue] = useState(true);

  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(saveMailTaskState(mailTasks));
  }, [mailTasks]);

  const mailTaskCheckboxOnChange = (name, isChecked) => {
    if (isChecked) {
      if (!mailTasks.includes(name)) {
        setMailTasks([...mailTasks, name]);
      }
    } else {
      const selectedMailTasks = mailTasks.filter((taskName) => taskName !== name);

      setMailTasks(selectedMailTasks);
    }
  };

  const filterUnavailableTaskTypeOptions = (tasks, options) => {
    let otherMotionCount = 0;

    const filteredTaskNames = tasks.map((task) => {
      if (task.label.toLowerCase() === 'other motion') {
        otherMotionCount += 1;
      }

      return task.label;
    });

    return options.filter((option) => {
      // Up to 2 other motion tasks can be created in the workflow
      // so only filter 'other motion' if there are 2 other motion tasks already created
      if (option.label.toLowerCase() === 'other motion' && otherMotionCount < 2) {
        return true;
      }

      return !filteredTaskNames.includes(option.label);
    });
  };

  useEffect(() => {
    props.onContinueStatusChange(relatedTasksCanContinue && unrelatedTasksCanContinue);
  }, [relatedTasksCanContinue, unrelatedTasksCanContinue]);

  return (
    <div className="gray-border" >
      <div className="review-tasks-and-appeal-box">
        <h1 className="review-tasks-and-appeals-title">Review Tasks & Appeals</h1>
        <p>Review any previously completed tasks by the Inbound Ops team and add new tasks for
      either the mail package or for linked appeals, if any.</p>
        <div>
          <h2 className="mail-tasks-title">Mail Tasks</h2>
          <div className="gray-border">
            <div className="area-above-select-completed-tasks">
              <p className="select-completed-mail-tasks-for-correspondence">
              Select any tasks completed by the Mail team for this correspondence.
              </p>
              <div className="mail-tasks-option-left-styling" id="mail-tasks-left">
                {mailTasksLeft.map((name, index) => {
                  return (
                    <Checkbox
                      key={index}
                      name={name}
                      label={name}
                      defaultValue={mailTasks.includes(name)}
                      onChange={(checked) => mailTaskCheckboxOnChange(name, checked)}
                    />
                  );
                })}
              </div>
              <div className="mail-tasks-option-right-styling" id="mail-tasks-right">
                {mailTasksRight.map((name, index) => {
                  return (
                    <Checkbox
                      key={index}
                      name={name}
                      label={name}
                      defaultValue={mailTasks.includes(name)}
                      onChange={(checked) => mailTaskCheckboxOnChange(name, checked)}
                    />
                  );
                })}
              </div>
            </div>
          </div>
        </div>

        <div id="task-related-to-an-appeal">
          <h2 className="tasks-related-to-an-appeal-title">Tasks related to an existing Appeal</h2>
          <p className="is-correspondence-related-to-existing-appeals">
          Is this correspondence related to an existing appeal?
          </p>
          <AddAppealRelatedTaskView
            correspondence={props.correspondence}
            setRelatedTasksCanContinue={setRelatedTasksCanContinue}
            filterUnavailableTaskTypeOptions={filterUnavailableTaskTypeOptions}
            allTaskTypeOptions={relatedTaskTypes}
            autoTexts={props.autoTexts}
          />
        </div>

        <hr />

        <div id="task-not-related-to-an-appeal">
          <h2 className="tasks-not-related-to-an-appeal-title">Tasks not related to an Appeal</h2>
          <p className="add-new-tasks-related-to-correspondence">
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
      </div>
    </div>
  );
};

AddTasksAppealsView.propTypes = {
  correspondence: PropTypes.object.isRequired,
  onContinueStatusChange: PropTypes.func.isRequired,
  autoTexts: PropTypes.arrayOf(PropTypes.string).isRequired,
};

export default AddTasksAppealsView;

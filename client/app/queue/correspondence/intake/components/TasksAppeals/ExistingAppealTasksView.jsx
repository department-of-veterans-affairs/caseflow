import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import AddTaskView from './AddTaskView';
import AddEvidenceSubmissionTaskView from './AddEvidenceSubmissionTaskView';
import Button from '../../../../../components/Button';
import CaseDetailsLink from '../../../../CaseDetailsLink';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const MAX_NUM_TASKS = 4;

export const ExistingAppealTasksView = (props) => {
  const [availableTaskTypeOptions, setavailableTaskTypeOptions] = useState([]);

  const getTasksForAppeal = () => {
    const filtered = props.newTasks.filter((el) => el.appealId === props.appeal.id);

    return filtered.sort((t1, t2) => {
      if (t1.id < t2.id) {
        return -1;
      }
      if (t1.id > t2.id) {
        return 1;
      }

      return 0;
    });
  };

  const getWaivedTaskForAppeal = () => {
    const taskId = props.appeal.evidenceSubmissionTask.id;

    let task = props.waivedTasks.find((el) => el.id === taskId);

    if (typeof task === 'undefined') {
      task = { id: taskId, isWaived: false, waiveReason: '' };
    }

    return task;
  };

  const addTask = () => {
    const newTask = { id: props.nextTaskId, appealId: props.appeal.id, type: '', label: '', content: '' };

    props.setNewTasks([...props.newTasks, newTask]);
  };

  const removeTask = (id) => {
    const newTasks = props.newTasks.filter((task) => task.id !== id);

    props.setNewTasks(newTasks);
  };

  const taskUpdatedCallback = (updatedTask) => {
    const filtered = props.newTasks.filter((task) => task.id !== updatedTask.id);

    props.setNewTasks([...filtered, updatedTask]);
  };

  const waivedTaskUpdatedCallback = (updatedTask) => {
    const filtered = props.waivedTasks.filter((task) => task.id !== updatedTask.id);

    if (updatedTask.isWaived) {
      props.setWaivedTasks([...filtered, updatedTask]);
    } else {
      props.setWaivedTasks(filtered);
    }
  };

  useEffect(() => {
    setavailableTaskTypeOptions(props.filterUnavailableTaskTypeOptions(getTasksForAppeal(), props.allTaskTypeOptions));
  }, [props.newTasks]);

  return (
    <div>
      <div className="tasks-appeal-title">
        <strong>Tasks: Appeal </strong>
        <CaseDetailsLink appeal={props.appeal}
          getLinkText={() => {
            return `#${props.appeal.docketNumber}`;
          }}
          linkOpensInNewTab
        />
      </div>

      <div className="evidence-window-submission-task">
        {props.appeal.hasEvidenceSubmissionTask &&
          <AddEvidenceSubmissionTaskView
            key={props.appeal.evidenceSubmissionTask.id}
            task={getWaivedTaskForAppeal()}
            taskUpdatedCallback={waivedTaskUpdatedCallback}
          />
        }
        {getTasksForAppeal().map((task) => {
          return (
            <AddTaskView
              key={task.id}
              task={task}
              removeTask={removeTask}
              taskUpdatedCallback={taskUpdatedCallback}
              displayRemoveCheck
              allTaskTypeOptions={props.allTaskTypeOptions}
              availableTaskTypeOptions={availableTaskTypeOptions}
              autoTexts={props.autoTexts}
            />
          );
        })}
      </div>

      <div className="area-around-add-tasks-button">
        <div className="width-of-add-tasks-button">
          <Button
            type="button"
            onClick={addTask}
            disabled={getTasksForAppeal().length === MAX_NUM_TASKS}
            name="addTasks"
            classNames={['cf-left-side', 'add-existing-appeal-button']}>
          + Add tasks
          </Button>
        </div>

        <div className="cursor-style-for-unlink-appeal-button" >
          <Link
            name={`unlink-${props.appeal.id}`}
            onClick={() => props.unlinkAppeal(props.appeal.id, false)}
          >
            <p className="fa fa-unlink"></p>&nbsp;Unlink appeal
          </Link>
        </div>
      </div>
    </div>
  );
};

ExistingAppealTasksView.propTypes = {
  appeal: PropTypes.object.isRequired,
  newTasks: PropTypes.array.isRequired,
  setNewTasks: PropTypes.func.isRequired,
  waivedTasks: PropTypes.array.isRequired,
  setWaivedTasks: PropTypes.func.isRequired,
  nextTaskId: PropTypes.number.isRequired,
  unlinkAppeal: PropTypes.func.isRequired,
  allTaskTypeOptions: PropTypes.array.isRequired,
  filterUnavailableTaskTypeOptions: PropTypes.func.isRequired,
  autoTexts: PropTypes.arrayOf(PropTypes.string).isRequired
};

export default ExistingAppealTasksView;

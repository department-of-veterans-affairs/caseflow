import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import Button from '../../../../../components/Button';
import AddTaskView from './AddTaskView';
import { setUnrelatedTasks } from '../../../correspondenceReducer/correspondenceActions';
import PropTypes from 'prop-types';

const MAX_NUM_TASKS = 4;

export const AddUnrelatedTaskView = (props) => {
  const [newTasks, setNewTasks] = useState(useSelector((state) => state.intakeCorrespondence.unrelatedTasks));
  const [nextTaskId, setNextTaskId] = useState(newTasks.length);
  const [addTasksVisible, setAddTasksVisible] = useState(false);
  const [availableTaskTypeOptions, setavailableTaskTypeOptions] = useState([]);

  const dispatch = useDispatch();

  useEffect(() => {
    setNextTaskId((prevId) => prevId + 1);
    dispatch(setUnrelatedTasks(newTasks));
  }, [newTasks]);

  const clickAddTask = () => {
    const newTask = { id: nextTaskId, type: '', label: '', content: '' };

    setNewTasks([...newTasks, newTask]);
  };

  const removeTask = (id) => {
    const filtered = newTasks.filter((task) => task.id !== id);

    setNewTasks(filtered);
  };

  const taskUpdatedCallback = (updatedTask) => {
    const filtered = newTasks.filter((task) => task.id !== updatedTask.id);

    setNewTasks([...filtered, updatedTask]);
  };

  useEffect(() => {
    if (newTasks.length) {
      setAddTasksVisible(true);
    } else {
      setAddTasksVisible(false);
    }
  }, [newTasks]);

  useEffect(() => {
    let canContinue = true;

    newTasks.forEach((task) => {
      canContinue = canContinue && ((task.content !== '') && (task.type !== ''));
    });

    props.setUnrelatedTasksCanContinue(canContinue);
  }, [newTasks]);

  useEffect(() => {
    if (!addTasksVisible) {
      props.setUnrelatedTasksCanContinue(true);
    }
  }, [addTasksVisible]);

  useEffect(() => {
    setavailableTaskTypeOptions(props.filterUnavailableTaskTypeOptions(newTasks, props.allTaskTypeOptions));
  }, [newTasks]);

  const getTasks = () => {
    return newTasks.toSorted((t1, t2) => {
      if (t1.id < t2.id) {
        return -1;
      }
      if (t1.id > t2.id) {
        return 1;
      }

      return 0;
    });
  };

  return (
    <div>
      {!addTasksVisible && <Button
        type="button"
        onClick={clickAddTask}
        name="addTaskOpen"
        classNames={['cf-left-side']}>
          + Add tasks
      </Button>}
      {addTasksVisible && <div
        className="gray-border">
        <div className="area-above-add-tasks-button-not-related">
          <div className="area-under-add-tasks-button-not-related-to-appeal">
            <div className="new-tasks-not-related-to-an-appeal-title">
              <b className="new-tasks-title-not-related-to-appeal">New Tasks</b>
            </div>
            <div className="area-under-new-tasks-title" />
            <div className="area-above-add-task-view">
              {getTasks().map((task) => (
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
              ))}
            </div>
            <div className="add-tasks-button-for-unrelated-appeals">
              <Button
                type="button"
                onClick={clickAddTask}
                disabled={newTasks.length === MAX_NUM_TASKS}
                name="addTasks"
                classNames={['cf-left-side']}>
                + Add tasks
              </Button>
            </div>
          </div>
        </div>
      </div>}
    </div>
  );
};

AddUnrelatedTaskView.propTypes = {
  setUnrelatedTasksCanContinue: PropTypes.func.isRequired,
  filterUnavailableTaskTypeOptions: PropTypes.func.isRequired,
  allTaskTypeOptions: PropTypes.array.isRequired,
  autoTexts: PropTypes.arrayOf(PropTypes.string).isRequired
};

export default AddUnrelatedTaskView;

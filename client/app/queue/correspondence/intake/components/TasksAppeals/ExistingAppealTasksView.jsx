import React from 'react';
import PropTypes from 'prop-types';
import AddTaskView from './AddTaskView';
import Button from '../../../../../components/Button';

export const ExistingAppealTasksView = (props) => {
  const addExistingAppealTask = () => {
    const newTask = { id: props.nextTaskId, appealId: props.appeal.id, type: '', content: '' };

    props.setNewTasks([...props.newTasks, newTask]);
  };

  const taskUpdatedCallback = (updatedTask) => {
    const filtered = props.newTasks.filter((task) => task.id !== updatedTask.id);

    props.setNewTasks([...filtered, updatedTask]);
  };

  const existingAppealTasksCanContinue = () => {
    return true;
  };

  const removeTask = () => {
    return true;
  };

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

  return (
    <div>
      <strong>Tasks: Appeal #{props.appeal.docketNumber}</strong>
      <div style={{display: 'flex', flexWrap: 'wrap'}}>
        {getTasksForAppeal().map((task) => {
          return (
            <AddTaskView
              key={task.id}
              task={task}
              removeTask={removeTask}
              taskUpdatedCallback={taskUpdatedCallback}
              setTaskTypeCanContinue={existingAppealTasksCanContinue}
            />
          );
        })}
      </div>

      <div style={{ padding: '2.5rem 2.5rem' }} >
        <Button
          type="button"
          onClick={addExistingAppealTask}
          disabled={false}
          name="addasks"
          classNames={['cf-left-side']}>
          + Add tasks
        </Button>
      </div>
    </div>
  );
};

ExistingAppealTasksView.propTypes = {
  appeal: PropTypes.object.isRequired,
  newTasks: PropTypes.array.isRequired,
  setNewTasks: PropTypes.func.isRequired,
  nextTaskId: PropTypes.number.isRequired
};

export default ExistingAppealTasksView;

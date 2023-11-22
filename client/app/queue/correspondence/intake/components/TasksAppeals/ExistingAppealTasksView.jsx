import React, { useState, useCallback } from 'react';
import PropTypes from 'prop-types';
import { useSelector, useDispatch } from 'react-redux';
import AddTaskView from './AddTaskView';
import Button from '../../../../../components/Button';
import {
  addNewAppealRelatedTask,
  setNewAppealRelatedTasks
} from '../../../correspondenceReducer/correspondenceActions';

export const ExistingAppealTasksView = (props) => {
  const newAppealRelatedTasks = useSelector((state) => state.intakeCorrespondence.newAppealRelatedTasks);
  const [nextTaskId, setNextTaskId] = useState(1);

  const dispatch = useDispatch();

  const addExistingAppealTask = () => {
    dispatch(addNewAppealRelatedTask(nextTaskId, props.appeal.id, '', ''));

    setNextTaskId(nextTaskId + 1);
  };

  const existingAppealTasksCanContinue = useCallback(() => {
  }, []);

  const taskUpdatedCallback = useCallback((updatedTask) => {
    const filtered = newAppealRelatedTasks.filter((task) => task.id !== updatedTask.id);

    dispatch(setNewAppealRelatedTasks([...filtered, updatedTask]));
  }, []);

  const removeTask = useCallback(() => {
  }, []);

  return (
    <div>
      <strong>Tasks: Appeal #{props.appeal.docketNumber}</strong>
      <div style={{display: 'flex', flexWrap: 'wrap'}}>
        {newAppealRelatedTasks.filter((task) => task.appealId === props.appeal.id).map((task) => {
          return (
            <AddTaskView
              key={task}
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
  appeal: PropTypes.object.isRequired
};

export default ExistingAppealTasksView;

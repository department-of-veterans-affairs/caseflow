import React, { useCallback, useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import Button from '../../../../../components/Button';
import TaskNotRelatedToAppeal from './TaskNotRelatedToAppeal';
import { setUnrelatedTasks } from '../../../correspondenceReducer/correspondenceActions';
import PropTypes from 'prop-types';

const MAX_NUM_TASKS = 2;

export const AddUnrelatedTaskView = (props) => {
  const unrelatedTasks = useSelector((state) => state.intakeCorrespondence.unrelatedTasks);
  const [nextTaskId, setNextTaskId] = useState(1);
  const [addTasksVisible, setAddTasksVisible] = useState(false);

  const dispatch = useDispatch();

  const clickAddTask = () => {
    const newTask = { id: nextTaskId, type: '', content: '' };

    setNextTaskId(nextTaskId + 1);

    dispatch(setUnrelatedTasks([...unrelatedTasks, newTask]));
  };

  const removeTask = useCallback((id) => {
    const filtered = unrelatedTasks.filter((task) => task.id !== id);

    dispatch(setUnrelatedTasks(filtered));
  }, [unrelatedTasks]);

  const taskUpdatedCallback = useCallback((updatedTask) => {
    const filtered = unrelatedTasks.filter((task) => task.id !== updatedTask.id);

    dispatch(setUnrelatedTasks([...filtered, updatedTask]));
  }, [unrelatedTasks]);

  useEffect(() => {
    if (unrelatedTasks.length) {
      setAddTasksVisible(true);
    } else {
      setAddTasksVisible(false);
      props.setUnrelatedTasksCanContinue(true);
    }
  }, [unrelatedTasks]);

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
        className="gray-border"
        style={{ padding: '0rem 0rem', display: 'flex', flexWrap: 'wrap', flexDirection: 'column' }}
      >
        <div style={{ width: '100%', height: 'auto', backgroundColor: 'white', paddingBottom: '3rem' }}>
          <div style={{ backgroundColor: '#f1f1f1', width: '100%', height: '50px', paddingTop: '1.5rem' }}>
            <b style={{
              verticalAlign: 'center',
              paddingLeft: '2.5rem',
              paddingTop: '1.5rem',
              border: '0',
              paddingBottom: '1.5rem',
              paddingRigfht: '5.5rem'
            }}>New Tasks</b>
          </div>
          <div style={{ width: '100%', height: '3rem' }} />
          <div style={{ display: 'flex', flexWrap: 'wrap' }}>
            {unrelatedTasks.length && unrelatedTasks.map((currentTask, i) => (
              <TaskNotRelatedToAppeal
                key={i}
                removeTask={removeTask}
                taskId={currentTask.id}
                taskUpdatedCallback={taskUpdatedCallback}
                setUnrelatedTasksCanContinue={props.setUnrelatedTasksCanContinue}
              />
            ))}
          </div>
          <div style={{ padding: '2.5rem 2.5rem' }} >
            <Button
              type="button"
              onClick={clickAddTask}
              disabled={unrelatedTasks.length === MAX_NUM_TASKS}
              name="addTasks"
              classNames={['cf-left-side']}>
                + Add tasks
            </Button>
          </div>
        </div>
      </div>}
    </div>
  );
};

AddUnrelatedTaskView.propTypes = {
  setUnrelatedTasksCanContinue: PropTypes.func.isRequired
};

export default AddUnrelatedTaskView;

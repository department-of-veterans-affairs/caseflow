import React, { useEffect, useState } from 'react';
import { useDispatch } from 'react-redux';
import Button from '../../../../../components/Button';
import AddTaskView from './AddTaskView';
import { setUnrelatedTasks } from '../../../correspondenceReducer/correspondenceActions';
import PropTypes from 'prop-types';

const MAX_NUM_TASKS = 2;

export const AddUnrelatedTaskView = (props) => {
  const [newTasks, setNewTasks] = useState([]);
  const [nextTaskId, setNextTaskId] = useState(1);
  const [addTasksVisible, setAddTasksVisible] = useState(false);

  const dispatch = useDispatch();

  useEffect(() => {
    setNextTaskId((prevId) => prevId + 1);
    dispatch(setUnrelatedTasks(newTasks));
  }, [newTasks]);

  const clickAddTask = () => {
    const newTask = { id: nextTaskId, type: '', content: '' };

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

    newTasks.forEach(task => {
      canContinue = canContinue && ((task.content !== '') && (task.type !== ''));
    });

    props.setUnrelatedTasksCanContinue(canContinue);
  }, [newTasks]);

  useEffect(() => {
    if (!addTasksVisible) {
      props.setUnrelatedTasksCanContinue(true);
    }
  }, [addTasksVisible]);

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
            {getTasks().map((task) => (
              <AddTaskView
                key={task.id}
                task={task}
                removeTask={removeTask}
                taskUpdatedCallback={taskUpdatedCallback}
                setTaskTypeCanContinue={props.setUnrelatedTasksCanContinue}
              />
            ))}
          </div>
          <div style={{ padding: '2.5rem 2.5rem' }} >
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
      </div>}
    </div>
  );
};

AddUnrelatedTaskView.propTypes = {
  setUnrelatedTasksCanContinue: PropTypes.func.isRequired
};

export default AddUnrelatedTaskView;

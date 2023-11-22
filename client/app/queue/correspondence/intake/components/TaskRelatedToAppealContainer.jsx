import React, { useState } from 'react';
import TaskRelatedToAppeal from './TaskRelatedToAppeal';
import Button from '../../../../components/Button';
import { useSelector, useDispatch } from 'react-redux';
import { addNewAppealRelatedTask, REMOVE_NEW_APPEAL_RELATED_TASK } from '../../correspondenceReducer/correspondenceActions';

const TaskRelatedToAppealContainer = (props) => {
  const taskRelatedAppeals = useSelector((state) => state.intakeCorrespondence.newAppealRelatedTasks);
  const [tasks, setTasks] = useState([{}]);

  const dispatch = useDispatch();

  const removeTask = (obj) => {
    // get the index so we know where to splice
    const indexToRemove = tasks.indexOf(obj);
    // remove that object
    const newTasks = tasks.splice(indexToRemove, 1);

    setTasks([...newTasks]);
  };

  const handleAdd = () => {
    console.log('Running handle add');
    // id, appealId, type, content)
    dispatch(addNewAppealRelatedTask(0, props.appealId, 0, 0));
  };

  return (
    <>
      <div style={{ display: 'flex' }}>
        {taskRelatedAppeals.filter((task) => task.appealId === props.appealId).map((task) =>
        <TaskRelatedToAppeal
        key={task}
          task={task}
          deleteVisible={taskRelatedAppeals.filter((task) => task.appealId === props.appealId).length > 1}
          deleteHandler={removeTask}
          taskRelatedAppeals={taskRelatedAppeals}
          />)}
      </div>
      <div style={{ padding: '2.5rem 2.5rem' }} >
        <Button
          type="button"
          onClick={handleAdd}
          disabled={false}
          name="addasks"
          classNames={['cf-left-side']}>
          + Add tasks
        </Button>
      </div></>);

};

export default TaskRelatedToAppealContainer;

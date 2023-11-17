/*
import React, { useEffect, useState, useCallback } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import Button from '../../../../../components/Button';
import TaskNotRelatedToAppeal from './TaskNotRelatedToAppeal';

export const AddUnrelatedTaskView = (props) => {
  const unrelatedTasks = useSelector((state) => state.intakeCorrespondence.unrelatedTasks);
  const [instructionText, setInstructionText] = useState('');

  const clickAddTask = () => {
    const currentTask = [...unrelatedTasks];
    const randNum = Math.floor(Math.random() * 1000000);

    currentTask.push({ Object: randNum, Task: '', Text: '', SelectedTaskType: -1, SelectedTaskName: '' });
  };

  return (
    <div
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
          { unrelatedTasks && unrelatedTasks.map((currentTask, i) => (
            <TaskNotRelatedToAppeal
              key={currentTask.Object}
              removeTask={() => removeTaskAtIndex(i)}
              handleChangeTaskType={(selectedOption, newText) =>
                handleChangeTaskTypeandText(selectedOption, newText, i)}
              taskType={currentTask.SelectedTaskType}
              taskText={currentTask.Text}
            />
          ))}
        </div>
        <div style={{ padding: '2.5rem 2.5rem' }} >
          <Button
            type="button"
            onClick={clickAddTask}
            disabled={unrelatedTasks.length === 2}
            name="addTasks"
            classNames={['cf-left-side']}>
              + Add tasks
          </Button>
        </div>
      </div>
    </div>
  );
};

AddUnrelatedTaskView.propTypes = {
  addTasksVisible: PropTypes.bool,
  setAddTasksVisible: PropTypes.func,
  disableContinue: PropTypes.func,
  unrelatedTasks: PropTypes.arrayOf(Object),
  setUnrelatedTasks: PropTypes.func,
  correspondenceUuid: PropTypes.string.isRequired,
  onContinueStatusChange: PropTypes.func.isRequired
};

export default AddUnrelatedTaskView;
*/

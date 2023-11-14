import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Checkbox from '../../../../../components/Checkbox';
import Button from '../../../../../components/Button';
import TaskNotRelatedToAppeal from '../TaskNotRelatedToAppeal';

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

export const AddTasksAppealsView = (props) => {
  const [, ] = useState([]);

  const clickAddTask = () => {
    props.setAddTasksVisible(true);
    const currentTask = [...props.unrelatedTasks];
    const randNum = Math.floor(Math.random() * 1000000);

    currentTask.push({ Object: randNum, Task: '', Text: '', SelectedTaskType: -1 });
    props.setUnrelatedTasks(currentTask);
    props.disableContinue(false);
  };

  const removeTaskAtIndex = (index) => {
    const currentTask = [...props.unrelatedTasks];
    const newTask = currentTask.filter((item, i) => index !== i);

    props.setUnrelatedTasks(newTask);
    if (currentTask.length >= 2) {
      props.disableContinue(true);
    }
    if (newTask.length === 0 || newTask.isNull) {
      props.setAddTasksVisible(false);
      props.disableContinue(true);
    }
  };

  const [, setInstructionText] = useState('');

  const checkContinueStatus = (newType, newText, index) => {
    const currentTask = [...props.unrelatedTasks];

    currentTask[index].Task = newType;
    currentTask[index].Text = newText.trimStart();

    let continueEnabled = true;

    currentTask.forEach((selectedTask) => {
      if (selectedTask.SelectedTaskType !== -1 && selectedTask.Text !== '') {
        // the condition is met
        continueEnabled = true;

      } else {
        continueEnabled = false;
        // This will exit the current iteration, not the entire function
      }
    });

    props.disableContinue(continueEnabled);
  };

  const handleChangeTaskTypeandText = (newType, newText, index) => {
    const currentTask = [...props.unrelatedTasks];

    currentTask[index].SelectedTaskType = newType;
    props.setUnrelatedTasks(currentTask);
    setInstructionText(newText);
    checkContinueStatus(newType, newText, index);
  };

  return (
    <div className="gray-border" style={{ marginBottom: '2rem', padding: '3rem 4rem' }}>
      <h1 style={{ marginBottom: '10px' }}>Review Tasks & Appeals</h1>
      <p>Review any previously completed tasks by the mail team and add new tasks for
      either the mail package or for linked appeals, if any.</p>
      <div>
        <h2 style={{ margin: '25px auto 15px auto' }}>Mail Tasks</h2>
        <div className="gray-border" style={{ padding: '0rem 2rem' }}>
          <p style={{ marginBottom: '0.5rem' }}>Select any tasks completed by the Mail team for this correspondence.</p>
          <div style={{ display: 'inline-block', marginRight: '14rem' }}>
            {mailTasksLeft.map((name, index) => {
              return (
                <Checkbox
                  key={index}
                  name={name}
                  label={name}
                />
              );
            })}
          </div>
          <div style={{ display: 'inline-block' }}>
            {mailTasksRight.map((name, index) => {
              return (
                <Checkbox
                  key={index}
                  name={name}
                  label={name}
                />
              );
            })}
          </div>
        </div>

        <h2 style={{ margin: '3rem auto 1rem auto' }}>Tasks not related to an Appeal</h2>
        <p style={{ marginTop: '0rem', marginBottom: '2rem' }}>
          Add new tasks related to this correspondence or to an appeal not yet created in Caseflow.
        </p>
        <div />

        {/* This button will activate the New Tasks section */}
        {!props.addTasksVisible && <Button
          type="button"
          onClick={clickAddTask}
          disabled={props.unrelatedTasks.length === 2}
          name="addTaskOpen"
          classNames={['cf-left-side']}>
            + Add tasks
        </Button>}

        {/* This is the New Tasks section. Tasks will show next to each other in line. */}
        {props.addTasksVisible &&
        <div className="gray-border"
          style={{ padding: '0rem 0rem', display: 'flex', flexWrap: 'wrap', flexDirection: 'column' }}>
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
              { props.unrelatedTasks && props.unrelatedTasks.map((currentTask, i) => (
                <TaskNotRelatedToAppeal
                  key={currentTask.Object}
                  removeTask={() => removeTaskAtIndex(i)}
                  handleChangeTaskType={(newType, newText) => handleChangeTaskTypeandText(newType, newText, i)}
                  taskType={currentTask.SelectedTaskType}
                  taskText={currentTask.Text}
                />
              ))}

            </div>
            <div style={{ padding: '2.5rem 2.5rem' }} >
              <Button
                type="button"
                onClick={clickAddTask}
                disabled={props.unrelatedTasks.length === 2}
                name="addTasks"
                classNames={['cf-left-side']}>
                  + Add tasks
              </Button>
            </div>
          </div>
        </div>}
      </div>
    </div>
  );
};

AddTasksAppealsView.propTypes = {
  addTasksVisible: PropTypes.bool,
  setAddTasksVisible: PropTypes.func,
  disableContinue: PropTypes.func,
  unrelatedTasks: PropTypes.arrayOf(Object),
  setUnrelatedTasks: PropTypes.func
};

export default AddTasksAppealsView;

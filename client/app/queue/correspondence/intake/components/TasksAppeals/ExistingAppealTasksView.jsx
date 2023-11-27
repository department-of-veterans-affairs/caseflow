import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import AddTaskView from './AddTaskView';
import Button from '../../../../../components/Button';
import CaseDetailsLink from '../../../../CaseDetailsLink';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

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

  const canRemove = () => {
    console.log("im running")
    if (props.newTasks.filter((task) => task.appealId === props.appeal.id).length > 1) {
      return true;
    }

    return false;

  };

  useEffect(() => {
    let canContinue = true;

    props.newTasks.forEach((task) => {
      canContinue = canContinue && ((task.content !== '') && (task.type !== ''));
    });

    props.setRelatedTasksCanContinue(canContinue);
  }, [props.newTasks]);

  const removeTask = (id) => {
    const newTasks = props.newTasks.filter((task) => task.id !== id);

    props.setNewTasks(newTasks);
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

  const unlinkTask = (appealId) => {
    const newTasks = props.newTasks.filter((task) => task.appealId !== appealId);

    props.setNewTasks(newTasks);
    props.unlinkAppeal(appealId, false);
  };

  useEffect(() => {
    if (props.newTasks.filter((task) => task.appealId === props.appeal.id).length === 0) {
      addExistingAppealTask();
    }
  }, [props.appeal, props.newTasks]);

  return (
    <div>
      <div style={{ marginLeft: '2%', marginBottom: '2%' }}>
        <strong>Tasks: Appeal </strong>
        <CaseDetailsLink appeal={props.appeal}
          getLinkText={() => {
            return `#${props.appeal.docketNumber}`;
          }}
          linkOpensInNewTab
        />
      </div>

      <div style={{ display: 'flex', flexWrap: 'wrap' }}>
        {getTasksForAppeal().map((task) => {
          return (
            <AddTaskView
              key={task.id}
              task={task}
              removeTask={removeTask}
              taskUpdatedCallback={taskUpdatedCallback}
              setTaskTypeCanContinue={existingAppealTasksCanContinue}
              displayRemoveCheck={canRemove}
              setRelatedTasksCanContinue={props.setRelatedTasksCanContinue}
            />
          );
        })}
      </div>

      <div style={{ padding: '2.5rem 2.5rem', display: 'flex', justifyContent: 'space-between' }} >
        <div style={{ width: '80%' }}>
          <Button
            type="button"
            onClick={addExistingAppealTask}
            disabled={false}
            name="addasks"
            classNames={['cf-left-side']}>
          + Add tasks
          </Button>
        </div>

        <Link
          name="asdf"
          target="target"
          onClick={() => unlinkTask(props.appeal.id)}
        >
          <p className="fa fa-unlink">Unlink appeal</p>
        </Link>
      </div>
    </div>
  );
};

ExistingAppealTasksView.propTypes = {
  appeal: PropTypes.object.isRequired,
  newTasks: PropTypes.array.isRequired,
  setNewTasks: PropTypes.func.isRequired,
  nextTaskId: PropTypes.number.isRequired,
  setRelatedTasksCanContinue: PropTypes.func.isRequired,
  unlinkAppeal: PropTypes.func.isRequired

};

export default ExistingAppealTasksView;

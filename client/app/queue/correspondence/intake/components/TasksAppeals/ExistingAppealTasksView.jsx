import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import AddTaskView from './AddTaskView';
import Button from '../../../../../components/Button';
import CaseDetailsLink from '../../../../CaseDetailsLink';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const MAX_NUM_TASKS = 4;

export const ExistingAppealTasksView = (props) => {
  const [displayRemoveCheck, setDisplayRemoveCheck] = useState(false);
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

  const addTask = () => {
    const newTask = { id: props.nextTaskId, appealId: props.appeal.id, type: '', content: '' };

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

  useEffect(() => {
    if (getTasksForAppeal().length > 1) {
      setDisplayRemoveCheck(true);
    } else {
      setDisplayRemoveCheck(false);
    }
  }, [props.newTasks]);

  useEffect(() => {
    setavailableTaskTypeOptions(props.filterUnavailableTaskTypeOptions(getTasksForAppeal()));
  }, [props.newTasks]);

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
              displayRemoveCheck={displayRemoveCheck}
              setRelatedTasksCanContinue={props.setRelatedTasksCanContinue}
              allTaskTypeOptions={props.allTaskTypeOptions}
              availableTaskTypeOptions={availableTaskTypeOptions}
            />
          );
        })}
      </div>

      <div style={{ padding: '2.5rem 2.5rem', display: 'flex', justifyContent: 'space-between' }}>
        <div style={{ width: '80%' }}>
          <Button
            type="button"
            onClick={addTask}
            disabled={props.newTasks.length === MAX_NUM_TASKS}
            name="addasks"
            className={['cf-left-side']}>
          + Add tasks
          </Button>
        </div>

        <div style={{ cursor: 'pointer' }}>
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
  nextTaskId: PropTypes.number.isRequired,
  setRelatedTasksCanContinue: PropTypes.func.isRequired,
  unlinkAppeal: PropTypes.func.isRequired,
  allTaskTypeOptions: PropTypes.array.isRequired,
  filterUnavailableTaskTypeOptions: PropTypes.func.isRequired
};

export default ExistingAppealTasksView;

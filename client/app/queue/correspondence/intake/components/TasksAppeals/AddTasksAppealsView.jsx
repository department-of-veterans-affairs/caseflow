import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import Checkbox from '../../../../../components/Checkbox';
import AddAppealRelatedTaskView from './AddAppealRelatedTaskView';
import AddUnrelatedTaskView from './AddUnrelatedTaskView';
import { saveMailTaskState } from '../../../correspondenceReducer/correspondenceActions';

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
  const mailTasks = useSelector((state) => state.intakeCorrespondence.mailTasks);
  const [relatedTasksCanContinue, setRelatedTasksCanContinue] = useState(true);
  const [unrelatedTasksCanContinue, setUnrelatedTasksCanContinue] = useState(true);

  const dispatch = useDispatch();

  useEffect(() => {
    props.onContinueStatusChange(relatedTasksCanContinue && unrelatedTasksCanContinue);
  }, [relatedTasksCanContinue, unrelatedTasksCanContinue]);

  return (
    <div className="gray-border" style={{ marginBottom: '2rem', padding: '3rem 4rem' }}>
      <h1 style={{ marginBottom: '10px' }}>Review Tasks & Appeals</h1>
      <p>Review any previously completed tasks by the mail team and add new tasks for
      either the mail package or for linked appeals, if any.</p>
      <div>
        <h2 style={{ margin: '25px auto 15px auto' }}>Mail Tasks</h2>
        <div className="gray-border" style={{ padding: '0rem 2rem' }}>
          <p style={{ marginBottom: '0.5rem' }}>Select any tasks completed by the Mail team for this correspondence.</p>
          <div id="mail-tasks-left" style={{ display: 'inline-block', marginRight: '14rem' }}>
            {mailTasksLeft.map((name, index) => {
              return (
                <Checkbox
                  key={index}
                  name={name}
                  label={name}
                  defaultValue={mailTasks[name] || false}
                  onChange={(isChecked) => dispatch(saveMailTaskState(name, isChecked))}
                />
              );
            })}
          </div>
          <div id="mail-tasks-right" style={{ display: 'inline-block' }}>
            {mailTasksRight.map((name, index) => {
              return (
                <Checkbox
                  key={index}
                  name={name}
                  label={name}
                  defaultValue={mailTasks[name] || false}
                  onChange={(isChecked) => dispatch(saveMailTaskState(name, isChecked))}
                />
              );
            })}
          </div>
        </div>

        <div>
          <h2 style={{ margin: '3rem auto 1rem auto' }}>Tasks not related to an Appeal</h2>
          <p style={{ marginTop: '0rem', marginBottom: '2rem' }}>
            Add new tasks related to this correspondence or to an appeal not yet created in Caseflow.
          </p>
          <div>
            <AddUnrelatedTaskView setUnrelatedTasksCanContinue={setUnrelatedTasksCanContinue} />
          </div>
        </div>

        <div style={{ marginTop: '5rem' }}>
          <h2>Tasks related to an existing Appeal</h2>
          <p>Is this correspondence related to an existing appeal?</p>
          <AddAppealRelatedTaskView
            correspondenceUuid={props.correspondenceUuid}
            setRelatedTasksCanContinue={setRelatedTasksCanContinue}
          />
        </div>
      </div>
    </div>
  );
};

AddTasksAppealsView.propTypes = {
  correspondenceUuid: PropTypes.string.isRequired,
  onContinueStatusChange: PropTypes.func.isRequired
};

export default AddTasksAppealsView;

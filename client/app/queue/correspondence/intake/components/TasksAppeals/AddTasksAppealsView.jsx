import React, { useEffect, useState } from 'react';
import { useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import Checkbox from '../../../../../components/Checkbox';
import RadioField from '../../../../../components/RadioField';
import AddAppealRelatedTaskView from './AddAppealRelatedTaskView';

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

const existingAppealAnswer = [
  { displayText: 'Yes',
    value: '1' },
  { displayText: 'No',
    value: '2' }
];

export const AddTasksAppealsView = (props) => {
  const taskRelatedAppeals = useSelector((state) => state.intakeCorrespondence.relatedTaskAppeals);
  const [relatedToExistingAppeal, setRelatedToExistingAppeal] = useState(false);
  const [existingAppealRadio, setExistingAppealRadio] = useState('2');

  const selectYes = () => {
    if (existingAppealRadio === '2') {
      setExistingAppealRadio('1');
      setRelatedToExistingAppeal(true);
    }
  };

  const selectNo = () => {
    if (existingAppealRadio === '1') {
      setExistingAppealRadio('2');
      setRelatedToExistingAppeal(false);
    }
  };

  useEffect(() => {
    // If user has selected appeals, enable continue
    if (relatedToExistingAppeal) {
      props.onContinueStatusChange(taskRelatedAppeals.length);
    } else {
      props.onContinueStatusChange(true);
    }
  }, [relatedToExistingAppeal, taskRelatedAppeals]);

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
        <div>
          <p>Placeholder</p>
        </div>

        <h2>Tasks related to an existing Appeal</h2>
        <p>Is this correspondence related to an existing appeal?</p>
        <RadioField
          name=""
          value= {existingAppealRadio}
          options={existingAppealAnswer}
          onChange={existingAppealRadio === '2' ? selectYes : selectNo}
        />
        {existingAppealRadio === '1' &&
          <AddAppealRelatedTaskView
            correspondenceUuid={props.correspondenceUuid}
          />
        }
      </div>
    </div>
  );
};

AddTasksAppealsView.propTypes = {
  correspondenceUuid: PropTypes.string.isRequired,
  onContinueStatusChange: PropTypes.func.isRequired
};

export default AddTasksAppealsView;

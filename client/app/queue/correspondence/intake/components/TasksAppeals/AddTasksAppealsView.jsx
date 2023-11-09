import React, { useState, useEffect } from 'react';
import Checkbox from '../../../../../components/Checkbox';
import RadioField from '../../../../../components/RadioField';
import { current } from '@reduxjs/toolkit';
import CaseListTable from '../../../../CaseListTable';
import ApiUtil from '../../../../../util/ApiUtil';

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

  const [appeals, setAppeals] = useState([])
  const [relatedToExistingAppeal, setRelatedToExistingAppeal] = useState(false)
  const [existingAppealRadio, setExistingAppealRadio] = useState('2')

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
    if (relatedToExistingAppeal === false) {
      return;
    }

    ApiUtil.get(`/queue/correspondence/${props.correspondenceUuid}/veteran`).then((response) => {
      const veteranFileNumber = response.body.file_number;

      ApiUtil.get('/appeals', { headers: { 'case-search': veteranFileNumber } }).
        then((response) => {
          debugger;
          setAppeals(response.body.appeals)
        });
      }
    );
  }, [relatedToExistingAppeal]);

  const selections = existingAppealAnswer.map(({displayText, value}) => ({

    displayText,
    current: (value === existingAppealRadio)
  }),
  );


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
        <br></br>
        <h2>Tasks related to an existing Appeal</h2>
        <p>Is this correspondence related to an existing appeal?</p>
          <RadioField
          name=""
          value= {existingAppealRadio}
          options={existingAppealAnswer}
          onChange={existingAppealRadio === '2' ? selectYes : selectNo }/>

          {existingAppealRadio === '1' && <div className="gray-border" style={{ marginBottom: '2rem', padding: '3rem 4rem' }}>

                          <CaseListTable appeals={appeals}/>
            </div>}

      </div>
    </div>
  );
};

export default AddTasksAppealsView;

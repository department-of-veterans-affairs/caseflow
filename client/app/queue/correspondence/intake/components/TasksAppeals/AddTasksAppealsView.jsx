import React, { useState, useEffect } from 'react';
import Checkbox from '../../../../../components/Checkbox';
import RadioField from '../../../../../components/RadioField';
import PropTypes from 'prop-types';
import CaseListTable from '../../../../CaseListTable';
import ApiUtil from '../../../../../util/ApiUtil';
import { prepareAppealForStore } from '../../../../utils';
import LoadingContainer from '../../../../../components/LoadingContainer';
import { LOGO_COLORS } from '../../../../../constants/AppConstants';

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
  const [appeals, setAppeals] = useState([]);
  const [loading, setLoading] = useState(false);
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
    // Only fetch if user indicates appeals data is needed
    if (relatedToExistingAppeal === false) {
      return;
    }

    // Don't refetch (use cache)
    if (appeals.length) {
      return;
    }

    // Visually indicate that we are fetching data
    setLoading(true);

    ApiUtil.get(`/queue/correspondence/${props.correspondenceUuid}/veteran`).
      then((vetResponse) => {
        const veteranFileNumber = vetResponse.body.file_number;

        ApiUtil.get('/appeals', { headers: { 'case-search': veteranFileNumber } }).
          then((appealResponse) => {
            const appealsForStore = prepareAppealForStore(appealResponse.body.appeals);

            const appealArr = [];

            for (const appealGuid in appealsForStore.appeals) {
              if (Object.hasOwn(appealsForStore.appeals, appealGuid)) {
                appealArr.push(appealsForStore.appeals[appealGuid]);
              }
            }

            setAppeals(appealArr);
            setLoading(false);
          });
      }
      );
  }, [relatedToExistingAppeal]);

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
          onChange={existingAppealRadio === '2' ? selectYes : selectNo}
        />
        {existingAppealRadio === '1' && loading &&
          <LoadingContainer color={LOGO_COLORS.QUEUE.ACCENT}>
            <div className="loading-div">
            </div>
          </LoadingContainer>
        }
        {existingAppealRadio === '1' && !loading &&
          <div className="gray-border" style={{ marginBottom: '2rem', padding: '3rem 4rem' }}>
            <CaseListTable appeals={appeals} showCheckboxes />
          </div>
        }
      </div>
    </div>
  );
};

AddTasksAppealsView.propTypes = {
  correspondenceUuid: PropTypes.string.isRequired
};

export default AddTasksAppealsView;

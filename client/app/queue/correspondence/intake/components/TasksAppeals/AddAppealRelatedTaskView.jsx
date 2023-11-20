import React, { useEffect, useState, useCallback } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import CaseListTable from '../../../../CaseListTable';
import ApiUtil from '../../../../../util/ApiUtil';
import { prepareAppealForStore } from '../../../../utils';
import LoadingContainer from '../../../../../components/LoadingContainer';
import { LOGO_COLORS } from '../../../../../constants/AppConstants';
import {
  saveAppealCheckboxState,
  setFetchedAppeals,
  clearAppealCheckboxState
} from '../../../correspondenceReducer/correspondenceActions';
import RadioField from '../../../../../components/RadioField';

const RELATED_NO = '0';
const RELATED_YES = '1';

const existingAppealAnswer = [
  { displayText: 'Yes',
    value: RELATED_YES },
  { displayText: 'No',
    value: RELATED_NO }
];

export const AddAppealRelatedTaskView = (props) => {
  const selectedAppeals = useSelector((state) => state.intakeCorrespondence.selectedAppeals);
  const appeals = useSelector((state) => state.intakeCorrespondence.fetchedAppeals);
  const [existingAppealRadio, setExistingAppealRadio] = useState(selectedAppeals.length > 0 ? RELATED_YES : RELATED_NO);
  const [loading, setLoading] = useState(false);

  const dispatch = useDispatch();

  const selectYes = () => {
    if (existingAppealRadio === RELATED_NO) {
      setExistingAppealRadio(RELATED_YES);
    }
  };

  const selectNo = () => {
    if (existingAppealRadio === RELATED_YES) {
      setExistingAppealRadio(RELATED_NO);
      dispatch(clearAppealCheckboxState());
    }
  };

  const checkboxOnChange = useCallback((id, isChecked) => {
    if (isChecked) {
      if (!selectedAppeals.includes(id)) {
        dispatch(saveAppealCheckboxState([...selectedAppeals, id]));
      }

    } else {
      const selected = selectedAppeals.filter((checkboxId) => checkboxId !== id);

      dispatch(saveAppealCheckboxState(selected));
    }
  }, [selectedAppeals]);

  useEffect(() => {
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

            for (const appealUuid in appealsForStore.appeals) {
              if (Object.prototype.hasOwnProperty.call(appealsForStore.appeals, appealUuid)) {
                appealArr.push(appealsForStore.appeals[appealUuid]);
              }
            }

            dispatch(setFetchedAppeals(appealArr));
            setLoading(false);
          });
      }
      );
  }, []);

  useEffect(() => {
    // If user has selected appeals, enable continue
    if (existingAppealRadio === RELATED_YES) {
      props.setRelatedTasksCanContinue(selectedAppeals.length);
    } else {
      props.setRelatedTasksCanContinue(true);
    }
  }, [existingAppealRadio, selectedAppeals]);

  return (
    <div>
      <RadioField
        name=""
        value= {existingAppealRadio}
        options={existingAppealAnswer}
        onChange={existingAppealRadio === RELATED_NO ? selectYes : selectNo}
      />
      {existingAppealRadio === RELATED_YES && loading &&
        <LoadingContainer color={LOGO_COLORS.QUEUE.ACCENT}>
          <div className="loading-div">
          </div>
        </LoadingContainer>
      }
      {existingAppealRadio === RELATED_YES && !loading &&
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
              }}>Existing Appeals</b>
            </div>
            <ul style={{ paddingLeft: '4.2rem' }}>
              Please select prior appeal(s) to link to this correspondence
            </ul>
            <ul>
              <div style={{ padding: '1rem' }}>
                <CaseListTable
                  appeals={appeals}
                  showCheckboxes
                  paginate
                  linkOpensInNewTab
                  checkboxOnChange={checkboxOnChange}
                />
              </div>
            </ul>
          </div>
        </div>
      }
    </div>
  );
};

AddAppealRelatedTaskView.propTypes = {
  correspondenceUuid: PropTypes.string.isRequired,
  setRelatedTasksCanContinue: PropTypes.func.isRequired
};

export default AddAppealRelatedTaskView;

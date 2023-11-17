import React, { useEffect, useState, useCallback } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import CaseListTable from '../../../../CaseListTable';
import ApiUtil from '../../../../../util/ApiUtil';
import { prepareAppealForStore } from '../../../../utils';
import LoadingContainer from '../../../../../components/LoadingContainer';
import { LOGO_COLORS } from '../../../../../constants/AppConstants';
import { setRelatedTaskAppeals } from '../../../correspondenceReducer/correspondenceActions';

export const AddAppealRelatedTaskView = (props) => {
  const [appeals, setAppeals] = useState([]);
  const taskRelatedAppeals = useSelector((state) => state.intakeCorrespondence.relatedTaskAppeals);
  const [loading, setLoading] = useState(false);

  const dispatch = useDispatch();

  const checkboxOnChange = useCallback((id, isChecked) => {
    if (isChecked) {
      dispatch(setRelatedTaskAppeals([...taskRelatedAppeals, id]));
    } else {
      const selected = taskRelatedAppeals.filter((checkboxId) => checkboxId !== id);

      dispatch(setRelatedTaskAppeals(selected));
    }
  }, [taskRelatedAppeals]);

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

            for (const appealGuid in appealsForStore.appeals) {
              if (Object.prototype.hasOwnProperty.call(appealsForStore.appeals, appealGuid)) {
                appealArr.push(appealsForStore.appeals[appealGuid]);
              }
            }

            setAppeals(appealArr);
            setLoading(false);
          });
      }
      );
  }, []);

  return (
    <div>
      {loading &&
        <LoadingContainer color={LOGO_COLORS.QUEUE.ACCENT}>
          <div className="loading-div">
          </div>
        </LoadingContainer>
      }
      {!loading &&
        <div className="gray-border" style={{ marginBottom: '2rem', padding: '3rem 4rem' }}>
          <CaseListTable
            appeals={appeals}
            showCheckboxes
            checkboxOnChange={checkboxOnChange}
          />
        </div>
      }
    </div>
  );
};

AddAppealRelatedTaskView.propTypes = {
  correspondenceUuid: PropTypes.string.isRequired
};

export default AddAppealRelatedTaskView;

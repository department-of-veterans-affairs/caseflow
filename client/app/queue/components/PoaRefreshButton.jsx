import React from 'react';
import PropTypes from 'prop-types';
// import { editAppeal, poaSyncDateUpdates } from '../QueueActions';
import { useDispatch } from 'react-redux';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import { css } from 'glamor';
import { setPOARefreshAlertState } from '../uiReducer/uiActions';

export const PoaRefreshButton = ({ appealId }) => {
  const dispatch = useDispatch();
  const updatePOA = () => {
    ApiUtil.patch(`/appeals/${appealId}/update_power_of_attorney`).then((data) => {
      // const alert = { 
      //                 type:data.body.status,
      //                 message:data.body.message 
      //               }
      dispatch(setPOARefreshAlertState(data.body.status, data.body.message));
      //display the alert?!
    });
  };

  return (
    <div>
        <Button
            type="button"
            name="Refresh Poa"
            classNames={['cf-push-right']}
            onClick={() => updatePOA()}
          >
            Refresh POA
        </Button>
    </div>
  );
};

PoaRefreshButton.propTypes = {
  powerOfAttorney: PropTypes.shape({
    poa_last_synced_at: PropTypes.string
  })

};

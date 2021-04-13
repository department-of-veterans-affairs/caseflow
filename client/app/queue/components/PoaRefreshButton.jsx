import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import { setPoaRefreshAlert } from '../uiReducer/uiActions';

export const PoaRefreshButton = ({ appealId }) => {
  const dispatch = useDispatch();
  const updatePOA = () => {
    ApiUtil.patch(`/appeals/${appealId}/update_power_of_attorney`).then((data) => {
      dispatch(setPoaRefreshAlert(data.body.status, data.body.message));
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

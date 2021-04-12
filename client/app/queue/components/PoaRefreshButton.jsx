import React from 'react';
import PropTypes from 'prop-types';
// import { editAppeal, poaSyncDateUpdates } from '../QueueActions';
// import { useDispatch, useSelector } from 'react-redux';
// import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import { css } from 'glamor';

export const PoaRefreshButton = ({ appealId }) => {
	console.log(appealId)
  const updatePOA = () => {
    fetch(`/appeals/${appealId}/update_power_of_attorney`)
      .then(res => res.json())
      .then(
        (result) => {
          alert = {
            type: result.status,
            message: result.message
          }
        }
      )
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

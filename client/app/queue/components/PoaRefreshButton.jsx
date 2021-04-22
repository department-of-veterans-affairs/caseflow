import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import SmallLoader from '../../components/SmallLoader';
import { setPoaRefreshAlert } from '../uiReducer/uiActions';

export const PoaRefreshButton = ({ appealId, poaId }) => {
  const dispatch = useDispatch();
  const [buttonText, setButtonText] = useState('Refresh POA');
  const viewPoaRefreshButton = useSelector((state) => state.ui.featureToggles.poa_refresh);

  const updatePOA = () => {
    setButtonText(<SmallLoader message="Refresh POA" spinnerColor="#417505" />);
    ApiUtil.post(`/appeals/${appealId}/update_power_of_attorney/${poaId}`).then((data) => {
      dispatch(setPoaRefreshAlert(data.body.status, data.body.message));
      setButtonText('Refresh POA');
    });
  };

  return <React.Fragment>
    {viewPoaRefreshButton && (<div>
      <Button
        type="button"
        name="Refresh Poa"
        classNames={['usa-button-secondary', 'cf-push-right']}
        onClick={() => updatePOA()}
      >
        {buttonText}
      </Button>
    </div>
    )}
  </React.Fragment>;
};

PoaRefreshButton.propTypes = {
  powerOfAttorney: PropTypes.shape({
    poa_last_synced_at: PropTypes.string,
  }),
  appealId: PropTypes.number,
  poaId: PropTypes.number
};

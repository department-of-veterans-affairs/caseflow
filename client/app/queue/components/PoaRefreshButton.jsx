import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import SmallLoader from '../../components/SmallLoader';
import { setPoaRefreshAlert } from '../uiReducer/uiActions';
import { css } from 'glamor';

export const spacingStyling = css({
  marginTop: '8px'
});

export const PoaRefreshButton = ({ appealId }) => {
  const dispatch = useDispatch();
  const [buttonText, setButtonText] = useState('Refresh POA');
  const viewPoaRefreshButton = useSelector((state) => state.ui.featureToggles.poa_button_refresh);

  const updatePOA = () => {
    setButtonText(<SmallLoader message="Refresh POA" spinnerColor="#417505" />);
    ApiUtil.patch(`/appeals/${appealId}/update_power_of_attorney`).then((data) => {
      dispatch(setPoaRefreshAlert(data.body.alert_type, data.body.message, data.body.power_of_attorney));
      setButtonText('Refresh POA');
    });
  };

  return <React.Fragment>
    {viewPoaRefreshButton && (<div {...spacingStyling}>
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
  appealId: PropTypes.string
};

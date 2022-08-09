import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import SmallLoader from '../../components/SmallLoader';
import { setSplitAppealAlert } from '../uiReducer/uiActions';
import { css } from 'glamor';

export const spacingStyling = css({
  marginTop: '8px'
});

export const SplitAppealButton = ({ appealId }) => {
  const dispatch = useDispatch();
  const [buttonText, setButtonText] = useState('Split Appeal');
  const viewSplitAppealButton = useSelector((state) => state.ui.featureToggles.split_appeal_workflow);

  const split = () => {
    setButtonText(<SmallLoader message="Split Appeal" spinnerColor="#417505" />);
    ApiUtil.post(`/appeals/${appealId}/split`).then((data) => {
      dispatch(setSplitAppealAlert(data.body.alert_type, data.body.message, data.body.split_appeal));
      setButtonText('Split Appeal');
    });
  };

  return <React.Fragment>
    {viewSplitAppealButton && (<div {...spacingStyling}>
      <Button
        type="button"
        name="Split Appeal"
        classNames={['usa-button-secondary', 'cf-push-right']}
        onClick={() => split()}
      >
        {buttonText}
      </Button>
    </div>
    )}
  </React.Fragment>;
};

SplitAppealButton.propTypes = {
  appealId: PropTypes.string
};

import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import SmallLoader from '../../components/SmallLoader';
import { css } from 'glamor';


export const spacingStyling = css({
  marginTop: '8px'
});

export const ConfirmAppealSplitButton = ({ appealId }) => {
  const dispatch = useDispatch();
  const [buttonText, setButtonText] = useState('Confirm Split');
  const viewConfirmAppealSplitButton = useSelector((state) => state.ui.featureToggles.split_appeal_workflow);

  const confirmSplit = () => {
    setButtonText(<SmallLoader message="Confirm Split" spinnerColor="#417505" />);
    <ApiUtil> className="post"('/appeals/${appealId}/split_appeal/split')</ApiUtil>
    };
  };

  return <React.Fragment>
    {viewConfirmAppealSplitButton && (<div {...spacingStyling}>
      <Button
        type="button"
        name="Confirm Split"
        classNames={['usa-button-secondary', 'cf-push-right']}
        onClick={() => confirmSplit()}
      >
        {buttonText}
      </Button>

    </div>)
    }
  </React.Fragment>;
};

ConfirmAppealSplitButton.propTypes = {
  appealId: PropTypes.string
};
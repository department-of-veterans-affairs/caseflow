import React from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import IntakeProgressBar from './IntakeProgressBar';
import Alert from 'app/components/Alert';
import { REQUEST_STATE } from 'app/intake/constants';
import { useSelector } from 'react-redux';
import { css } from 'glamor';

const textAlignRightStyling = css({
  textAlign: 'right',
});

export const IntakeLayout = ({
  buttons,
  cancelIntakeRequestStatus,
  children,
}) => {
  return (
    <>
      <IntakeProgressBar />
      <AppSegment filledBackground>
        {cancelIntakeRequestStatus === REQUEST_STATE.FAILED && (
          <Alert
            type="error"
            title="Error"
            message={
              'There was an error while canceling the current intake.' +
              ' Please try again later.'
            }
          />
        )}
        <div>{children}</div>
      </AppSegment>
      {buttons && <nav role="navigation" className={`cf-app-segment ${textAlignRightStyling}`}>{buttons}</nav>}
    </>
  );
};
IntakeLayout.propTypes = {
  cancelIntakeRequestStatus: PropTypes.string,
  buttons: PropTypes.node,
  children: PropTypes.node,
};

const IntakeLayoutContainer = () => {
  const cancelIntakeRequestStatus = useSelector(
    ({ intake }) => intake.requestStatus.cancel
  );

  return <IntakeLayout cancelIntakeRequestStatus={cancelIntakeRequestStatus} />;
};

export default IntakeLayoutContainer;

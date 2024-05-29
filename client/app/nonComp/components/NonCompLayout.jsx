import React from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Alert from 'app/components/Alert';
import { useSelector } from 'react-redux';
import { GENERATE_REPORT_ERROR } from '../constants';

const NonCompLayout = ({ buttons, children }) => {
  const changeHistoryRequestStatus = useSelector((state) => state.changeHistory.status);

  return (
    <div>
      {changeHistoryRequestStatus === 'failed' ?
        <Alert title="Error" type="error">
          {GENERATE_REPORT_ERROR}
        </Alert> :
        null
      }
      <AppSegment filledBackground>
        <div>
          {children}
        </div>
      </AppSegment>
      {buttons ? buttons : null}
    </div>
  );
};

NonCompLayout.propTypes = {
  buttons: PropTypes.node,
  children: PropTypes.node,
};

export default NonCompLayout;

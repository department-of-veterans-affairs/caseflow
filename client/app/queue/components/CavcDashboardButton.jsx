import React from 'react';
import { useHistory } from 'react-router-dom';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import COPY from '../../../COPY';

export const CavcDashboardButton = ({ appealId }) => {
  const { push } = useHistory();

  return <React.Fragment>
    <div>
      <Button
        type="button"
        name="Cavc Dashboard"
        classNames={['usa-button-secondary']}
        onClick={() => push(`/queue/appeals/${appealId}/cavc_dashboard`, { redirectFromButton: true })}
      >
        {COPY.CAVC_DASHBOARD_BUTTON_TEXT}
      </Button>
    </div>
  </React.Fragment>;
};

CavcDashboardButton.propTypes = {
  appealId: PropTypes.string
};

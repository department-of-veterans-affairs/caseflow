import React, { useState } from 'react';
import { useHistory } from 'react-router-dom';
import PropTypes from 'prop-types';
import Button from '../../components/Button';

export const CavcDashboardButton = ({ appealId }) => {
  const [buttonText] = useState('CAVC Dashboard');
  const { push } = useHistory();


  return <React.Fragment>
    (<div>
      <Button
        type="button"
        name="Cavc Dashboard"
        classNames="usa-button-secondary"
        onClick={() => push(`/queue/appeals/${appealId}/cavc_dashboard`)}
      >
        {buttonText}
      </Button>
    </div>
    )
  </React.Fragment>;
};

CavcDashboardButton.propTypes = {
  appealId: PropTypes.string
};

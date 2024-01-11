import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';

const LeverAlertBanner = ({ title, message, type }) => {
  useEffect(() => {
    window.scrollTo({ top: 0, behavior: 'auto' });
  }, []);
  const leverBannerAlerts = `lever-alert-banner
    ${type === ACD_LEVERS.SUCCESS ? 'lever-alert-banner-success' : 'lever-alert-banner-error'}`;

  return (
    <div className={leverBannerAlerts}>
      <h3>{title}</h3>
      <p>{message}</p>
    </div>
  );
};

LeverAlertBanner.propTypes = {
  title: PropTypes.string.isRequired,
  message: PropTypes.string.isRequired,
  type: PropTypes.oneOf([ACD_LEVERS.SUCCESS, ACD_LEVERS.ERROR]),
};

export default LeverAlertBanner;

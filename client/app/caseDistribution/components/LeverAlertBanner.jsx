import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
// import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';

const LeverAlertBanner = ({ title, message, type }) => {
  useEffect(() => {
    window.scrollTo({ top: 0, behavior: 'auto' });
  }, []);
  const leverBannerAlerts = `${styles.leverAlertBanner}
    ${type === ACD_LEVERS.SUCCESS ? styles.leverAlertBannerSuccess : styles.leverAlertBannerError}`;

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

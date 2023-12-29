import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';

const LeverAlertBanner = ({ title, message, type }) => {
  useEffect(() => {
    window.scrollTo({ top: 0, behavior: 'auto' });
  }, []);
  const leverBannerAlerts = `${styles.leverAlertBanner}
    ${type === 'success' ? styles.leverAlertBannerSuccess : styles.leverAlertBannerError}`;

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
  type: PropTypes.oneOf(['success', 'error']),
};

export default LeverAlertBanner;

import React from "react";
import PropTypes from 'prop-types';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';

const LeverAlertBanner = ({ title, message, type }) => {
  // const bannerStyle = {
  //   backgroundColor: type === 'success' ? '#e7f4e4' : '#f44336',
  //   top: 0,
  //   left: 0,
  //   width: "100%",
  //   zIndex: 9999,
  //   position: 'absolute',
  //   margin: 0,
  //   padding: 0,

  // };


  return (
    <div className={`${styles.LeverAlertBanner}`}>
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

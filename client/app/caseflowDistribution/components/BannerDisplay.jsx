import React, { useState, useEffect } from 'react';
import COPY from '../../../COPY';
import LeverAlertBanner from './LeverAlertBanner';
import PropTypes from 'prop-types';
const BannerDisplay = ({ leverStore }) => {
  const [showBanner, setShowBanner] = useState(false);
  useEffect(() => {
    // Subscribe to changes in the Redux store
    const unsubscribe = leverStore.subscribe(() => {
      const state = leverStore.getState();
      setShowBanner(state.showSuccessBanner);
    });
    // Unsubscribe when the component is unmounted
    return () => {
      unsubscribe();
    };
  }, [leverStore]);
  return (
    <>
      {showBanner && (
        <LeverAlertBanner
          title={COPY.CASE_DISTRIBUTION_SUCCESSBANNER_TITLE}
          message={COPY.CASE_DISTRIBUTION_SUCCESSBANNER_DETAIL}
          type="success"
        />
      )}
    </>
  );
};
BannerDisplay.propTypes = {
  leverStore: PropTypes.any.isRequired,
};
export default BannerDisplay;

import React, { useState, useEffect } from 'react';
import COPY from '../../../COPY';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import LeverAlertBanner from './LeverAlertBanner';
import PropTypes from 'prop-types';

const BannerDisplay = ({ leverStore }) => {
  const [showBanner, setShowBanner] = useState(false);

  useEffect(() => {
    const unsubscribe = leverStore.subscribe(() => {
      const state = leverStore.getState();

      setShowBanner(state.showSuccessBanner);
    });

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
          type={ACD_LEVERS.SUCCESS}
        />
      )}
    </>
  );
};

BannerDisplay.propTypes = {
  leverStore: PropTypes.any.isRequired,
};
export default BannerDisplay;

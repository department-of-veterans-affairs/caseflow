import React, { useState, useEffect } from 'react';
import COPY from '../../../COPY';
import { useDispatch, useSelector } from 'react-redux';
import Alert from '../../components/Alert';
import { hideSuccessBanner } from '../reducers/levers/leversActions';

const BannerDisplay = () => {
  const dispatch = useDispatch();
  const showSuccessBanner = useSelector((state) => state.caseDistributionLevers.showSuccessBanner);
  const [showBanner, setShowBanner] = useState(false);

  useEffect(() => {
    setShowBanner(showSuccessBanner);
    if (showSuccessBanner) {
      setTimeout(() => {
        dispatch(hideSuccessBanner());
      }, 10000);
    }
  }, [showSuccessBanner]);

  return (
    <>
      {showBanner && (
        <Alert
          title={COPY.CASE_DISTRIBUTION_SUCCESSBANNER_TITLE}
          message={COPY.CASE_DISTRIBUTION_SUCCESSBANNER_DETAIL}
          type="success"
        />
      )}
    </>
  );
};

export default BannerDisplay;

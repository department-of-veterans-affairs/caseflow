import React, { useState, useEffect } from 'react';
import COPY from '../../../COPY';
import { useDispatch, useSelector } from 'react-redux';
import Alert from '../../components/Alert';
import { hideSuccessBanner } from '../reducers/levers/leversActions';

const BannerDisplay = () => {
  const dispatch = useDispatch();
  const displayBanner = useSelector((state) => state.caseDistributionLevers.displayBanner);
  const errors = useSelector((state) => state.caseDistributionLevers.errors);
  const [showBanner, setShowBanner] = useState(false);

  useEffect(() => {
    setShowBanner(displayBanner);
    if (displayBanner) {
      setTimeout(() => {
        dispatch(hideSuccessBanner());
      }, 10000);
    }
  }, [displayBanner]);

  let title = COPY.CASE_DISTRIBUTION_SUCCESS_BANNER_TITLE;
  let message = COPY.CASE_DISTRIBUTION_SUCCESS_BANNER_DETAIL;
  let type = 'success';

  if (errors.length > 0) {
    console.error(errors);
    title = COPY.CASE_DISTRIBUTION_FAILURE_BANNER_TITLE;
    message = COPY.CASE_DISTRIBUTION_FAILURE_BANNER_DETAIL;
    type = 'error';
  }

  return (
    <>
      {showBanner && (
        <Alert
          title={title}
          message={message}
          type={type}
        />
      )}
    </>
  );
};

export default BannerDisplay;

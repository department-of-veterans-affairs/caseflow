import React from 'react';
import Alert from '../../components/Alert';

const SeedsBannerDisplay = () => {

  let title = 'Test Seeds';
  let message = '';
  let type = 'success';
  let showBanner = false;

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

export default SeedsBannerDisplay;

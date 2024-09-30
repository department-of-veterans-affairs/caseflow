import React from 'react';
import Alert from '../../../components/Alert';
import PropTypes from 'prop-types';

const ReviewPackageNotificationBanner = (props) => {
  return (
    <div>
      <Alert
        message={props.message}
        title={props.title}
        type={props.type}
      />
      <br />
    </div>
  );
};

ReviewPackageNotificationBanner.propTypes = {
  message: PropTypes.string,
  title: PropTypes.string,
  type: PropTypes.string
};

export default ReviewPackageNotificationBanner;

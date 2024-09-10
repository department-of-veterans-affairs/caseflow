// External Dependencies
import React, { Suspense } from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import LoadingScreen from 'app/components/LoadingScreen';

const Loadable = ({ children, spinnerColor, message }) => {
  return (
    <Suspense fallback={<LoadingScreen spinnerColor={spinnerColor} message={message} />}>
      {children}
    </Suspense>
  );
};

Loadable.propTypes = {
  children: PropTypes.element,
  spinnerColor: PropTypes.string,
  message: PropTypes.string
};

export default Loadable;


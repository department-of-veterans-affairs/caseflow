// External Dependencies
import React, { Suspense } from 'react';
import PropTypes from 'prop-types';

const Loadable = ({ children }) => {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      {children}
    </Suspense>
  );
};

Loadable.propTypes = {
  children: PropTypes.element
};

export default Loadable;


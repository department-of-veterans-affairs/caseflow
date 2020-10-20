// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Internal Dependencies
import ReaderAppLegacy from 'app/reader/ReaderApp';

const Reader = (props) => !props.featureToggles?.readerVersion2 && <ReaderAppLegacy {...props} />;

Reader.propTypes = {
  featureToggles: PropTypes.objectOf({
    readerVersion2: PropTypes.bool
  })
};

export default Reader;

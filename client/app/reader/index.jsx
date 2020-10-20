// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Internal Dependencies
import ReaderAppLegacy from 'app/reader/ReaderApp';

// Version 2 does not distinguish by sub-application, so just call it Caseflow
import { Root as Caseflow } from 'app/2.0/root';

const Reader = (props) => props.featureToggles?.readerVersion2 ?
  <Caseflow {...props} /> : <ReaderAppLegacy {...props} />;

Reader.propTypes = {
  featureToggles: PropTypes.objectOf({
    readerVersion2: PropTypes.bool
  })
};

export default Reader;

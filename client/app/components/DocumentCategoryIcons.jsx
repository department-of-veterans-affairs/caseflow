import React, { PropTypes } from 'react';
import * as Constants from '../reader/constants';
import { connect } from 'react-redux';
import _ from 'lodash';

export const DocumentCategoryIcons = ({ document, docId }) => {
  return <ul className="cf-document-category-icons">
    {
      _(_.get(document, [docId, 'categories'])).
        pickBy(_.identity).
        keys().
        map((categoryName) => {
          const Svg = Constants.documentCategories[categoryName].svg;

          return <li key={categoryName}><Svg /></li>;
        }).
        value()
    }
  </ul>;
};

DocumentCategoryIcons.propTypes = {
  document: PropTypes.object,
  docId: PropTypes.number
};

export default connect(
  (state) => ({ document: state && state.document })
)(DocumentCategoryIcons);

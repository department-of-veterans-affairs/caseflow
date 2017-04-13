import React, { PropTypes } from 'react';
import * as Constants from '../reader/constants';
import { connect } from 'react-redux';
import _ from 'lodash';

export const DocumentCategoryIcons = ({ documents, docId }) => {
  return <ul className="cf-document-category-icons">
    {
      _(_.get(documents, [docId, 'categories'])).
        pickBy(_.identity).
        keys().
        sortBy((categoryName) => Constants.documentCategories[categoryName].renderOrder).
        map((categoryName) => {
          const Svg = Constants.documentCategories[categoryName].svg;

          return <li key={categoryName}><Svg /></li>;
        }).
        value()
    }
  </ul>;
};

DocumentCategoryIcons.propTypes = {
  documents: PropTypes.object,
  docId: PropTypes.number
};

const mapPropsToState = (state) => _.pick(state, 'documents');

export default connect(mapPropsToState)(DocumentCategoryIcons);

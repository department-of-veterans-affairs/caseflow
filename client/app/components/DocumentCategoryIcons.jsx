import React, { PropTypes } from 'react';
import * as Constants from '../reader/constants';
import { connect } from 'react-redux';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from '../reader/utils';

export const DocumentCategoryIcons = ({ documents, docId }) => {
  const doc = _.get(documents, docId);

  if (!doc) {
    return null;
  }

  return <ul className="cf-document-category-icons" aria-label="document categories">
    {
      _(Constants.documentCategories).
        filter(
          (category, categoryName) => doc[categoryFieldNameOfCategoryName(categoryName)]
        ).
        sortBy('renderOrder').
        map((category) => {
          const Svg = category.svg;

          return <li key={category.renderOrder} aria-label={category.humanName}>
            <Svg />
          </li>;
        }).
        value()
    }
  </ul>;
};

DocumentCategoryIcons.propTypes = {
  documents: PropTypes.object,
  docId: PropTypes.number.isRequired
};

const mapPropsToState = (state) => _.pick(state, 'documents');

export default connect(mapPropsToState)(DocumentCategoryIcons);

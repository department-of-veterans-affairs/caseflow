import React, { PropTypes } from 'react';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from '../reader/utils';
import * as Constants from '../reader/constants';

const categoriesOfDocument = (document) => _(Constants.documentCategories).
    filter(
      (category, categoryName) => document[categoryFieldNameOfCategoryName(categoryName)]
    ).
    sortBy('renderOrder').
    value();

export default class DocumentCategoryIcons extends React.Component {
  shouldComponentUpdate = (nextProps) => !_.isEqual(
    categoriesOfDocument(this.props.doc),
    categoriesOfDocument(nextProps.doc)
  )

  render() {
    const categories = categoriesOfDocument(this.props.doc);

    if (!_.size(categories)) {
      return null;
    }

    return <ul className="cf-document-category-icons" aria-label="document categories">
      {
        _.map(categories, (category) =>
          <li
            className="cf-no-styling-list"
            key={category.renderOrder}
            aria-label={category.humanName}>
            {category.svg}
          </li>
        )
      }
    </ul>;
  }
}

DocumentCategoryIcons.propTypes = {
  doc: PropTypes.object.isRequired
};

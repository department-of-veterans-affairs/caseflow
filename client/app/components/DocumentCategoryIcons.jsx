import React, { PropTypes } from 'react';
import * as Constants from '../reader/constants';
import { connect } from 'react-redux';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from '../reader/utils';

export class DocumentCategoryIcons extends React.PureComponent {
  render() {
    const { categories } = this.props;

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

const mapStateToProps = (state, ownProps) => ({
  categories: _(Constants.documentCategories).
    filter(
      (category, categoryName) => state.documents[ownProps.docId][categoryFieldNameOfCategoryName(categoryName)]
    ).
    sortBy('renderOrder').
    value()
});

const ConnectedDocumentCategoryIcons = connect(mapStateToProps)(DocumentCategoryIcons);

ConnectedDocumentCategoryIcons.propTypes = {
  docId: PropTypes.number.isRequired
};

export default ConnectedDocumentCategoryIcons;

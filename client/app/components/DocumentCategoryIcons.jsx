import React, { PropTypes } from 'react';
import * as Constants from '../reader/constants';
import { connect } from 'react-redux';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from '../reader/utils';
import { createSelector } from 'reselect';

export class DocumentCategoryIcons extends React.PureComponent {
  shouldComponentUpdate = (nextProps) => !_.isEqual(this.props, nextProps)

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

const getDocument = (state, props) => state.documents[props.docId];

const getCategories = createSelector(
  [getDocument],
  (document) => _(Constants.documentCategories).
    filter(
      (category, categoryName) => document[categoryFieldNameOfCategoryName(categoryName)]
    ).
    sortBy('renderOrder').
    value()
);

const mapStateToProps = (state, ownProps) => ({
  categories: getCategories(state, ownProps)
});

const ConnectedDocumentCategoryIcons = connect(mapStateToProps)(DocumentCategoryIcons);

ConnectedDocumentCategoryIcons.propTypes = {
  docId: PropTypes.number.isRequired
};

export default ConnectedDocumentCategoryIcons;

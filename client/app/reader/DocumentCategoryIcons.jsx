import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { size, sortBy, map } from 'lodash';
import { categoryFieldNameOfCategoryName } from '../reader/utils';
import * as Constants from '../reader/constants';

const SPACE_DELIMITER = ' ';

const categoriesOfDocument = (document) =>
  sortBy(
    Object.keys(Constants.documentCategories).reduce((list, name) => {
      if (document[categoryFieldNameOfCategoryName(name)]) {
        return {
          ...list,
          [name]: Constants.documentCategories[name]
        };
      }

      return list;
    }, {}),
    'renderOrder'
  );

class DocumentCategoryIcons extends React.Component {
  render() {
    const { searchCategoryHighlights, doc } = this.props;
    const categories = categoriesOfDocument(doc);

    if (!size(categories)) {
      return null;
    }
    const listClassName = 'cf-no-styling-list';

    // helper function to get the name of the category
    const getCategoryName = (humanName) => humanName.split(SPACE_DELIMITER)[0].toLowerCase();

    return (
      <ul className="cf-document-category-icons" aria-label="document categories">
        {map(categories, (category) => (
          <li
            className={
              searchCategoryHighlights[getCategoryName(category.humanName)] ?
                `${listClassName} highlighted` :
                listClassName
            }
            key={category.renderOrder}
            aria-label={category.humanName}
          >
            {category.svg}
          </li>
        ))}
      </ul>
    );
  }
}

DocumentCategoryIcons.defaultProps = {
  searchCategoryHighlights: {}
};

DocumentCategoryIcons.propTypes = {
  doc: PropTypes.object.isRequired,
  searchCategoryHighlights: PropTypes.object
};

const mapStateToProps = (state, ownProps) => ({
  searchCategoryHighlights: state.documentList.searchCategoryHighlights[ownProps.doc.id]
});

export { DocumentCategoryIcons };

export default connect(
  mapStateToProps,
  null
)(DocumentCategoryIcons);

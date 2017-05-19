import React, { PropTypes } from 'react';
import _ from 'lodash';

export default class DocumentCategoryIcons extends React.PureComponent {
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

DocumentCategoryIcons.propTypes = {
  categories: PropTypes.array.isRequired
};

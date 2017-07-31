import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import * as Constants from './constants';
import Checkbox from '../components/Checkbox';
import Analytics from '../util/AnalyticsUtil';

const CategorySelector = (props) => {
  const { category, categoryName, handleCategoryToggle, categoryToggleStates } = props;
  const toggleState = categoryToggleStates[categoryName] || false;
  const label = <div className="cf-category-selector">
      {category.svg}
      <span className="cf-category-name">{category.humanName}</span>
    </div>;

  const handleChange = (checked) => {
    Analytics.event('Claims Folder', `${checked ? 'select' : 'unselect'} category filter`, categoryName);

    handleCategoryToggle(categoryName, checked);
  };

  return <Checkbox name={categoryName} onChange={handleChange}
      label={label} value={toggleState} disabled={category.readOnly} />;
};

CategorySelector.propTypes = {
  category: PropTypes.shape({
    humanName: PropTypes.string.isRequired,
    svg: PropTypes.element.isRequired
  }).isRequired,
  categoryToggleStates: PropTypes.object,
  categoryName: PropTypes.string.isRequired
};

const DocCategoryPicker = ({ categoryToggleStates, handleCategoryToggle }) => {
  return <ul className="cf-document-filter-picker cf-document-category-picker">
    {
      _(Constants.documentCategories).
        toPairs().
        // eslint-disable-next-line no-unused-vars
        sortBy(([name, category]) => category.renderOrder).
        map(
          ([categoryName, category]) => <li key={categoryName}>
            <CategorySelector category={category}
              handleCategoryToggle={handleCategoryToggle}
              categoryName={categoryName} categoryToggleStates={categoryToggleStates} />
          </li>
        ).
        value()
    }
  </ul>;
};

DocCategoryPicker.propTypes = {
  handleCategoryToggle: PropTypes.func.isRequired,
  categoryToggleStates: PropTypes.object
};

export default DocCategoryPicker;

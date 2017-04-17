import React, { PropTypes } from 'react';
import _ from 'lodash';
import * as Constants from './constants';
import Checkbox from '../components/Checkbox';

const CategorySelector = (props) => {
  const { category, categoryName, handleCategoryToggle, categoryToggleStates } = props;
  const toggleState = categoryToggleStates[categoryName];
  const Svg = category.svg;
  const label = <div className="cf-category-selector">
      <Svg />
      <span className="cf-category-name">{category.humanName}</span>
    </div>;

  const handleChange = (checked) => handleCategoryToggle(categoryName, checked);

  return <div>
    <Checkbox name={categoryName} onChange={handleChange}
      label={label} value={toggleState} />
  </div>;
};

CategorySelector.propTypes = {
  category: PropTypes.shape({
    humanName: PropTypes.string.isRequired,
    svg: PropTypes.func.isRequired
  }).isRequired,
  categoryName: PropTypes.string.isRequired
};

const DocCategoryPicker = ({ categoryToggleStates, handleCategoryToggle }) => {
  return <ul>
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

export default DocCategoryPicker;

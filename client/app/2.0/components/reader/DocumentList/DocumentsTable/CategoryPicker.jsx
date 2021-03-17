// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import Checkbox from 'app/components/Checkbox';
import {
  categoryLabelStyles,
  categoryNameStyles,
  docCategoryPickerStyles
} from 'styles/reader/DocumentList/DocumentsTable';
import { sortCategories } from 'app/2.0/utils/format';

/**
 * Category Picker Component
 * @param {Object} props -- Contains the category picker state and functions to mutate
 */
export const CategoryPicker = ({
  categoryToggleStates,
  handleCategoryToggle,
  allowReadOnly,
  dropdownFilterViewListStyle,
  dropdownFilterViewListItemStyle,
}) => (
  <ul {...docCategoryPickerStyles} {...dropdownFilterViewListStyle}>
    {sortCategories(false).map(([categoryName, category]) =>
      <li key={categoryName} {...dropdownFilterViewListItemStyle}>
        <Checkbox
          name={categoryName}
          onChange={(checked) => handleCategoryToggle(categoryName, checked)}
          label={(
            <div {...categoryLabelStyles}>
              {category.svg}
              <span {...categoryNameStyles}>{category.humanName}</span>
            </div>
          )}
          value={categoryToggleStates[categoryName] || false}
          disabled={category.readOnly && allowReadOnly}
        />
      </li>
    )}
  </ul>
);

CategoryPicker.defaultProps = {
  dropdownFilterViewListStyle: {},
  dropdownFilterViewListItemStyle: {}
};

CategoryPicker.propTypes = {
  handleCategoryToggle: PropTypes.func.isRequired,
  categoryToggleStates: PropTypes.object,
  allowReadOnly: PropTypes.bool,
  dropdownFilterViewListStyle: PropTypes.object,
  dropdownFilterViewListItemStyle: PropTypes.object,
};

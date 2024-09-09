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
import { documentCategories } from 'store/constants/reader';

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
    {Object.keys(documentCategories).map((categoryName) => (
      <li key={categoryName} {...dropdownFilterViewListItemStyle}>
        <Checkbox
          name={categoryName}
          onChange={(checked) => handleCategoryToggle(categoryName, checked)}
          label={(
            <div {...categoryLabelStyles}>
              {documentCategories[categoryName].svg}
              <span {...categoryNameStyles}>{documentCategories[categoryName].humanName}</span>
            </div>
          )}
          value={categoryToggleStates[categoryName] || false}
          disabled={documentCategories[categoryName].readOnly && allowReadOnly}
        />
      </li>
    ))}
  </ul>
);

CategoryPicker.defaultProps = {
  dropdownFilterViewListStyle: {},
  dropdownFilterViewListItemStyle: {}
};

CategoryPicker.propTypes = {
  categories: PropTypes.object,
  handleCategoryToggle: PropTypes.func.isRequired,
  categoryToggleStates: PropTypes.object,
  allowReadOnly: PropTypes.bool,
  dropdownFilterViewListStyle: PropTypes.object,
  dropdownFilterViewListItemStyle: PropTypes.object,
};

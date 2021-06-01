// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import { CategoryPicker } from 'components/reader/DocumentList/DocumentsTable/CategoryPicker';
import { CannotSaveAlert } from 'components/shared/CannotSaveAlert';

/**
 * Sidebar Categories Component for Document screen
 * @param {Object} props -- Contains category toggle state
 */
export const SidebarCategories = ({ error, categories, handleCategoryToggle, ...props }) => (
  <div className="cf-category-sidebar">
    {error?.category?.visible && <CannotSaveAlert />}
    <CategoryPicker
      {...props}
      allowReadOnly
      categoryToggleStates={categories}
      handleCategoryToggle={handleCategoryToggle}
    />
  </div>
);

SidebarCategories.propTypes = {
  error: PropTypes.object,
  handleCategoryToggle: PropTypes.func,
  categories: PropTypes.object,
};

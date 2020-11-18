// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import { CategoryPicker } from 'components/reader/DocumentList/DocumentsTable/CategoryPicker';
import { CannotSaveAlert } from 'components/reader/DocumentViewer/CannotSaveAlert';

/**
 * Sidebar Categories Component for Document screen
 * @param {Object} props -- Contains category toggle state
 */
export const SidebarCategories = ({ error, filterCriteria, setCategoryFilter, ...props }) => (
  <div className="cf-category-sidebar">
    {error.category.visible && <CannotSaveAlert />}
    <CategoryPicker
      {...props}
      categoryToggleStates={filterCriteria?.category}
      handleCategoryToggle={setCategoryFilter}
    />
  </div>
);

SidebarCategories.propTypes = {
  error: PropTypes.object,
  setCategoryFilter: PropTypes.func,
  filterCriteria: PropTypes.object,
};

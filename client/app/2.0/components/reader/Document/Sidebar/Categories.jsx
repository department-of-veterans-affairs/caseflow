// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import DocCategoryPicker from 'app/reader/DocCategoryPicker';
import { CannotSaveAlert } from 'components/shared/CannotSaveAlert';

/**
 * Sidebar Categories Component for Document screen
 * @param {Object} props -- Contains category toggle state
 */
export const SidebarCategories = ({ doc, error, categoryToggleStates, handleCategoryToggle }) => (
  <div className="cf-category-sidebar">
    {error.category.visible && <CannotSaveAlert />}
    <DocCategoryPicker
      allowReadOnly
      handleCategoryToggle={() => handleCategoryToggle(doc.id)}
      categoryToggleStates={categoryToggleStates}
    />
  </div>
);

SidebarCategories.propTypes = {
  error: PropTypes.object,
  handleCategoryToggle: PropTypes.array,
  categoryToggleStates: PropTypes.object,
  doc: PropTypes.object,
};

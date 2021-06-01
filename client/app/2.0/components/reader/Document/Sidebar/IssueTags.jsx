// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import { CannotSaveAlert } from 'components/shared/CannotSaveAlert';
import SearchableDropdown from 'app/components/SearchableDropdown';

/**
 * Issue Tags Component for searching Document Issue Tags
 * @param {Object} props -- Contains details to search for document tags
 */
export const IssueTags = ({ error, doc, onChange, tagOptions, tags }) => (
  <div className="cf-issue-tag-sidebar">
    {error.tag.visible && <CannotSaveAlert />}
    <SearchableDropdown
      key={doc.id}
      name="tags"
      label="Select or tag issues"
      multi
      dropdownStyling={{ position: 'relative' }}
      creatable
      options={tagOptions}
      placeholder=""
      value={tags}
      onChange={onChange}
    />
  </div>
);

IssueTags.propTypes = {
  doc: PropTypes.object,
  onChange: PropTypes.func,
  error: PropTypes.object,
  tagOptions: PropTypes.array,
  tags: PropTypes.object
};

// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import { CannotSaveAlert } from 'components/shared/CannotSaveAlert';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { formatTagValue } from 'utils/reader';

/**
 * Issue Tags Component for searching Document Issue Tags
 * @param {Object} props -- Contains details to search for document tags
 */
export const IssueTags = ({ errors, pendingTag, changeTags, tagOptions, currentDocument, handleTagEdit }) => {
  return (
    <div className="cf-issue-tag-sidebar">
      {errors?.tag?.visible && <CannotSaveAlert />}
      <SearchableDropdown
        creatableOptions={{ onFocus: handleTagEdit('focus'), onBlur: handleTagEdit('blur') }}
        readOnly={pendingTag}
        key={currentDocument.id}
        name="tags"
        label="Select or tag issues"
        multi
        dropdownStyling={{ position: 'relative' }}
        creatable
        options={tagOptions}
        placeholder=""
        value={currentDocument.tags ? formatTagValue(currentDocument.tags) : []}
        onChange={changeTags}
      />
    </div>
  );
};

IssueTags.propTypes = {
  pendingTag: PropTypes.bool,
  handleTagEdit: PropTypes.func,
  changeTags: PropTypes.func,
  errors: PropTypes.object,
  tagOptions: PropTypes.array,
  currentDocument: PropTypes.object
};

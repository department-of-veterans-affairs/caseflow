// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import Checkbox from 'app/components/Checkbox';
import { tagListStyles, tagListItemStyles } from 'styles/reader/DocumentList/DocumentsTable';

/**
 * Document Tag Picker component
 * @param {Object} props -- Contains tag details and state as well as state manipulation functions
 */
export const TagPicker = ({
  tags,
  tagToggleStates,
  handleTagToggle,
  dropdownFilterViewListStyle,
  dropdownFilterViewListItemStyle
}) => (
  <ul {...dropdownFilterViewListStyle} {...tagListStyles}>
    {Object.keys(tags).map((tag, index) => (
      <li key={index} {...dropdownFilterViewListItemStyle} {...tagListItemStyles}>
        <Checkbox
          label={
            <div className="cf-tag-selector">
              <span className="cf-tag-name">{tags[tag].text}</span>
            </div>
          }
          name={tags[tag].text}
          onChange={(checked) => handleTagToggle(tags[tag].text, checked, tags[tag].id)}
          value={tagToggleStates[tags[tag].text] || false}
        />
      </li>
    ))}
  </ul>
);

TagPicker.propTypes = {
  tags: PropTypes.array,
  handleTagToggle: PropTypes.func.isRequired,
  tagToggleStates: PropTypes.object,
  dropdownFilterViewListStyle: PropTypes.object,
  dropdownFilterViewListItemStyle: PropTypes.object
};

import React from 'react';
import PropTypes from 'prop-types';

import Checkbox from '../components/Checkbox';
import { css } from 'glamor';

const TagSelector = (props) => {
  const { tag, handleTagToggle, tagToggleStates } = props;
  const toggleState = tagToggleStates[tag.text] || false;
  const label = <div className="cf-tag-selector">
    <span className="cf-tag-name">{tag.text}</span>
  </div>;

  const handleChange = (checked) => {
    handleTagToggle(tag.text, checked, tag.id);
  };

  return <Checkbox name={tag.text} onChange={handleChange}
    label={label} value={toggleState} />;
};

TagSelector.propTypes = {
  tag: PropTypes.shape({
    text: PropTypes.string.isRequired
  }).isRequired,
  handleTagToggle: PropTypes.func,
  tagToggleStates: PropTypes.object
};

const tagListStyling = css({
  paddingBottom: 0,
  margin: 0,
  maxHeight: '345px',
  wordBreak: 'break-word',
  width: '218px',
  overflowY: 'auto',
  listStyleType: 'none',
  paddingLeft: 0
});
const tagListItemStyling = css({
  '& .cf-form-checkboxes': {
    marginBottom: 0,
    marginTop: 0,
    '& label': {
      marginBottom: 0
    }
  }
});

const DocTypePicker = ({ tags, tagToggleStates, handleTagToggle,
  dropdownFilterViewListStyle, dropdownFilterViewListItemStyle }) => {
  return <ul {...dropdownFilterViewListStyle} {...tagListStyling}>
    {tags.map((tag, index) => {
      return <li key={index} {...dropdownFilterViewListItemStyle} {...tagListItemStyling}>
        <TagSelector
          tag={tag}
          handleTagToggle={handleTagToggle}
          tagToggleStates={tagToggleStates}
        />
      </li>;
    })}
  </ul>;
};

DocTypePicker.propTypes = {
  handleTagToggle: PropTypes.func.isRequired,
  tagToggleStates: PropTypes.object
};

export default DocTypePicker;

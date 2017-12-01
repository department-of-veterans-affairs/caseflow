import React from 'react';
import PropTypes from 'prop-types';

import Checkbox from '../components/Checkbox';

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

const DocTagPicker = ({ tags, tagToggleStates, handleTagToggle }) => {
  return <ul className="cf-document-filter-picker cf-document-tag-picker">
    {tags.map((tag, index) => {
      return <li className="cf-tag-selector" key={index}>
        <TagSelector
          tag={tag}
          handleTagToggle={handleTagToggle}
          tagToggleStates={tagToggleStates}
        />
      </li>;
    })}
  </ul>;
};

DocTagPicker.propTypes = {
  handleTagToggle: PropTypes.func.isRequired,
  tagToggleStates: PropTypes.object
};

export default DocTagPicker;

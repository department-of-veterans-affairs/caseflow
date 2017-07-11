import React from 'react';
import PropTypes from 'prop-types';

import Checkbox from '../components/Checkbox';
import Analytics from '../util/AnalyticsUtil';

const TagSelector = (props) => {
  const { tag, handleTagToggle, tagToggleStates } = props;
  const toggleState = tagToggleStates[tag.text] || false;
  const label = <div className="cf-category-selector">
      <span className="cf-category-name">{tag.text}</span>
    </div>;

  const handleChange = (checked) => {
    Analytics.event('Claims Folder', `${checked ? 'select' :  'unselect'} tag filter`, tag.text);

    handleTagToggle(tag.text, checked);
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
      return <div className="cf-category-selector" key={index}>
        <TagSelector
          tag={tag}
          handleTagToggle={handleTagToggle}
          tagToggleStates={tagToggleStates}
        />
      </div>;
    })}
  </ul>;
};

DocTagPicker.propTypes = {
  handleTagToggle: PropTypes.func.isRequired,
  tagToggleStates: PropTypes.object
};

export default DocTagPicker;

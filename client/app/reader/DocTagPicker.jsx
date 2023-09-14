import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Checkbox from '../components/Checkbox';
import { css } from 'glamor';
import SearchBar from '../components/SearchBar';

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
  tagToggleStates: PropTypes.object,
  searchOnChange: PropTypes.func
};

// const updateFilterTextState = (newState) => {
//   this.setState({ filterText: newState });
// };

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

const DocTagPicker = ({ tags, tagToggleStates, handleTagToggle,

  dropdownFilterViewListStyle, dropdownFilterViewListItemStyle }) => {
  const [filterText, updateFilterText] = useState('');

  const getFilteredData = () => {
    if (filterText.length < 3) {
      return tags;
    }
    const filteredData = tags.filter(
      (tag) => tag.text.toLowerCase().includes(filterText.toLowerCase())
    );

    return filteredData;
  };

  return (
    <div style={{width: '217px'}}>
      <SearchBar onChange={updateFilterText} value={filterText} disableClearSearch size="small" />
      <ul {...dropdownFilterViewListStyle} {...tagListStyling}>
        {getFilteredData().map((tag, index) => {
          return <li key={index} {...dropdownFilterViewListItemStyle} {...tagListItemStyling}>
            <TagSelector
              tag={tag}
              handleTagToggle={handleTagToggle}
              tagToggleStates={tagToggleStates}
            />
          </li>;
        })}
      </ul>
    </div>);
};

DocTagPicker.propTypes = {
  handleTagToggle: PropTypes.func.isRequired,
  tagToggleStates: PropTypes.object,
  searchOnChange: PropTypes.func
};

export default DocTagPicker;

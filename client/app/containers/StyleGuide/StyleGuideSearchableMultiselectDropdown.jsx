import React, { Component } from 'react';
import SearchableMutiselectDropdown from '../../components/SearchableMultiselectDropdown';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

class StyleGuideSearchableMultiselectDropdown extends Component {
  constructor(props) {
    super(props);

    this.state = {
      value: null
    };
  }

  onChange = (value) => value;

  render() {
    return (
      <div>
        <StyleGuideComponentTitle
          title="Searchable multiselect Dropdown"
          id="searchable_multiselect_dropdown"
          link="SearchableMutiselectDropdown.jsx"
        />
        <SearchableMutiselectDropdown
          label="Searchable multiselect dropdown"
          name="countries"
          options={[{ value: 'unitedstates',
            label: 'United States' },
          { value: 'germany',
            label: 'Germany' },
          { value: 'france',
            label: 'France' },
          { value: 'russia',
            label: 'Russia' },
          { value: 'china',
            label: 'China' },
          { value: 'india',
            label: 'India' },
          { value: 'uae',
            label: 'United Arab Emrites' }]}
          onChange={this.onChange}
          required={true}
        />
        <p>The searchable dropdown provides more context to users' choices.
          This is helpful in cases where there is a large dropdown menu with many options.
          This dual behavior dropdown component make the dropdown easier to use and
          options more readily available for the user.</p>
      </div>
    );
  }
}

export default StyleGuideSearchableMultiselectDropdown;

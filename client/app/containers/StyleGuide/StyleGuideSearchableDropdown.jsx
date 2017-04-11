import React, { Component } from 'react';
import SearchableDropdown from '../../components/SearchableDropdown';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

class StyleGuideSearchableDropdown extends Component {
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
          title="Searchable Dropdown"
          id="searchable_dropdown"
          link="StyleGuideSearchableDropdown.jsx"
        />
        <SearchableDropdown
          label="Searchable dropdown"
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

export default StyleGuideSearchableDropdown;

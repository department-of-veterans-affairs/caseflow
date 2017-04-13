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
    let options = {
      tagAlreadyExistsMsg: "Tag already exists",
      promptTextCreator: (label) => {return `Create a tag for "${label}"`}
    };

    return (
      <div>
        <StyleGuideComponentTitle
          title="Searchable Dropdowns"
          id="searchable_dropdown"
          link="StyleGuideSearchableDropdown.jsx"
        />
        <h3>Single Select Searchable Dropdown</h3>
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
        <h3>Creatable Searchable Multiselect Dropdown</h3>
        <SearchableDropdown
          creatable={true}
          label="Click in the box below to select, type, or add in issue(s)"
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
          required={true}
          multi={true}
          placeholder="Select options"
          creatable={true}
          creatableOptions={options}
        />
        <p>The searchable dropdowns provide more context to users' choices.
          This is helpful in cases where there is a large dropdown menu with many options.
          This dual behavior dropdown component make the dropdown easier to use and
          options more readily available for the user.</p>
      </div>
    );
  }
}

export default StyleGuideSearchableDropdown;

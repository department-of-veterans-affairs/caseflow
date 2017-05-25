import React, { Component } from 'react';
import SearchBar from '../../components/SearchBar';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

class StyleGuideSearch extends Component {
  constructor(props) {
    super(props);

    this.state = {
      value: ''
  
    }

  }

  render() {
    const options = [{ value: 'unitedstates',
      label: 'United States' },
    { value: 'germany',
      label: 'Germany' },
    { value: 'france',
      label: 'France' },
    { value: 'russia',
      label: 'Russia' }];

    return (
      <div>
        <StyleGuideComponentTitle
          title="Search"
          id="search"
          link="StyleGuideSearch.jsx"
        />

        <h3>Search Small</h3>
        {this.state.name}
        <SearchBar />
      </div>
    );
  }
}

export default StyleGuideSearch;

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
    

    return (
      <div>
        <StyleGuideComponentTitle
          title="Search"
          id="search"
          link="StyleGuideSearch.jsx"
        />

        <h3>Search Small</h3>
        <div className="cf-sg-searchbar-example">
          <SearchBar 
            id="search-field"
            xclassNames="usa-search usa-search-big"
          />
        </div>
      </div>
    );
  }
}

export default StyleGuideSearch;

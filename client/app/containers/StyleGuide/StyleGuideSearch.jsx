import React, { Component } from 'react';
import SearchBar from '../../components/SearchBar';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

class StyleGuideSearch extends Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: {
        small: false,
        big: false
      }
    };

  }

  handleSearchClick = (elemName) => {
    const load = () => {
      this.setState((prevState) => ({
        [elemName]: !prevState[elemName]
      }));
    };

    load();

    setTimeout(load, 2000);
  }

  handleBigClick = () => this.handleSearchClick('big')

  handleSmallClick = () => this.handleSearchClick('small')

  onChange = (value) => this.setState({ value });

  render() {

    return (
      <div>
        <StyleGuideComponentTitle
          title="Search"
          id="search"
          link="StyleGuideSearch.jsx"
        />
        <p>
        Search bars are a block that allows users to search for specific content
        if they know what search terms to use or can’t find desired content in the main navigation.
        In Caseflow they serve as a vital UI component that allows users to
        find information necessary in completing their tasks.</p>

        <p>
        Based on the app there are two sizes: big and small.
        There is also a unique Caseflow search behavior that displays a spinning logo to indicate load times.
        </p>

        <p>
        <b>Technical notes:</b> In the "Search Big" and the "Search Small" examples below,
        click on the Search buttons to activate the loading spinner for a 2 second
        period.
        </p>

        <div className="cf-sg-searchbar-example">
          <SearchBar
            id="search-big"
            title="Search Big"
            size="big"
            onClick={this.handleBigClick}
            loading={this.state.big}
            onChange={this.onChange}
          />
        </div>
        <div className="cf-sg-searchbar-example">
          <SearchBar
            id="search-small"
            title="Search Small"
            size="small"
            onClick={this.handleSmallClick}
            loading={this.state.small}
            onChange={this.onChange}
          />
       </div>
       <div className="cf-sg-searchbar-example">
         <SearchBar
           id="search-ahead"
           title="Search Ahead"
           size="small"
           placeholder="Type to search..."
           onChange={this.onChange}
         />
      </div>
    </div>
    );
  }
}

export default StyleGuideSearch;

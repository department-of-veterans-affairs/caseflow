import React, { Component } from 'react';
import SearchBar from '../../components/SearchBar';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';


class StyleGuideSearch extends Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: {
        small: false,
        medium: false,
        big: false
      }
    };

  }

  handleSearchClick = (elem) => () => {
    const load = () => {
      this.setState((prevState) => ({
        [elem]: !prevState[elem]
      }));
    };

    load();

    setTimeout(load, 2000);
  };

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
        Based on the app there are three sizes: big, medium, and small.
        There is also a unique Caseflow search behavior that displays a spinning logo to indicate load times.
        </p>

          <div className="cf-sg-searchbar-example">
            <SearchBar
              id="search-big"
              title="Search Big"
              size="big"
              onClick={this.handleSearchClick('big')}
              loading={this.state.big}
            />
          </div>
          <br/>
          <div className="cf-sg-searchbar-example">
            <SearchBar
              id="search-medium"
              title="Search Medium"
              size="medium"
              onClick={this.handleSearchClick('medium')}
              loading={this.state.medium}
            />
        </div>
         <br/>
         <div className="cf-sg-searchbar-example">
            <SearchBar
              id="search-small"
              title="Search Small"
              size="small"
              onClick={this.handleSearchClick('small')}
              loading={this.state.small}
            />
        </div>

      </div>
    );
  }
}

export default StyleGuideSearch;

import React, { Component } from 'react';
import SearchBar from '../../components/SearchBar';
import Button from '../../components/Button';
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

  handleMenuClick = (elem) => ()=> {
    this.setState((prevState) => ({
      [elem]: !prevState[elem]
    }))
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
        Search bars are a are block that allows users to search for specific content
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
              classNames="usa-search usa-search-big"
              onClick={this.handleMenuClick('big')}
              loading={this.state.big}
            />
            <Button
              id="reset-big"
              name="Reset"
              onClick={this.handleMenuClick('big')}
              classNames={['cf-btn-link']}
              disabled={!this.state.big}
            />
          </div>

          <div className="cf-sg-searchbar-example">
            <SearchBar
              id="search-medium"
              title="Search medium"
              classNames="usa-search usa-search-medium"
              onClick={this.handleMenuClick('medium')}
              loading={this.state.medium}
            />
            <Button
              id="reset-medium"
              name="Reset"
              onClick={this.handleMenuClick('medium')}
              classNames={['cf-btn-link']}
              disabled={!this.state.medium}
            />
        </div>

        <br />
        <div className="cf-sg-searchbar-example">
            <SearchBar
              id="search-small"
              title="Search Small"
              classNames="usa-search usa-search-small"
              onClick={this.handleMenuClick('small')}
              loading={this.state.small}
            />
            <Button
              id="reset-small"
              name="Reset"
              onClick={this.handleMenuClick('small')}
              classNames={['cf-btn-link']}
              disabled={!this.state.small}
            />
        </div>

      </div>
    );
  }
}

export default StyleGuideSearch;

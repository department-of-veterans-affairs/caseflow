import React, { Component } from 'react';
import SearchBar from '../../components/SearchBar';
import Button from '../../components/Button';
import InlineForm from '../../components/InlineForm';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

class StyleGuideSearch extends Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: {
        search: false
      }
   };

}

  handleMenuClick = () => {
    this.setState((prevState) => ({
      search: !prevState.search
    }));
  };

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
          <InlineForm>
            <SearchBar
              id="search-field"
              classNames="usa-search usa-search-big"
              onClick={this.handleMenuClick}
              loading={this.state.search}
            />
            <Button
              id="reset-default"
              name="Reset"
              onClick={this.handleMenuClick}
              classNames={['cf-btn-link']}
              disabled={!this.state.search}
            />
          </InlineForm>
        </div>
      </div>
    );
  }
}

export default StyleGuideSearch;

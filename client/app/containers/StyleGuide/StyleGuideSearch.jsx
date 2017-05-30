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
        search: false,
        medium: false
      }

   };

}
   handleMenuClick = () => {
    this.setState((prevState) => ({
     search: !prevState.search,
     medium: !prevState.medium,
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
        <p>
        Search bars are a are block that allows users to search for specific content 
        if they know what search terms to use or can’t find desired content in the main navigation. 
        In Caseflow they serve as a vital UI component that allows users to 
        find information necessary in completing their tasks.</p>

        <p>
        Based on the app there are three sizes: big, medium, and small.
        There is also a unique Caseflow search behavior that displays a spinning logo to indicate load times.
        </p> 

        <h3>Search Big</h3>
        <div className="cf-sg-searchbar-example">
            <SearchBar
              id="search-field-big"
              title="SEARCH BIG"
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
        </div>
        
        <h3>Search Medium</h3>
        <div className="cf-sg-searchbar-example">
            <SearchBar
              id="search-field"
              title="SEARCH MEDIUM"
              classNames="usa-search usa-search-medium"
              onClick={this.handleMenuClick}
              loading={this.state.medium}
            />
        </div>
        
        <br />
        <h3>Search Small</h3>
        <div className="cf-sg-searchbar-example">
            <SearchBar
              id="search-field-small"
              title="SEARCH SMALL"
              classNames="usa-search usa-search-small"
              onClick={this.handlesMenuClick}
              loading={this.state.search}
            />
        </div>
        
      </div>
    );
  }
}

export default StyleGuideSearch;

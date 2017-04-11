import React, { Proptypes } from 'react';
import SearchBar from '../components/SearchBar';
import Button from '../components/Button';

const DocumentListHeader = (props) => {
  return <div className="usa-grid-full document-list-header">
    <div className="usa-width-one-third">
      <SearchBar
        id="searchBar"
        onChange={props.onFilter}
        value={props.filterBy}
      />
    </div>
    <div className="usa-width-one-third num-of-documents">
      {props.numberOfDocuments} Documents
    </div>
    <div className="usa-width-one-third">
      <span className="cf-right-side">
        <Button
          id="btn-default"
          name="Expand all"
        />
      </span>
    </div>
  </div>;
};

export default DocumentListHeader;

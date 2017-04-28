import React, { PropTypes } from 'react';
import SearchBar from '../SearchBar';
import Button from '../Button';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setSearch, clearAllFilters } from '../../reader/actions';
import _ from 'lodash';

export const DocumentListHeader = (props) => {
  const categoryFilters = Object.keys(props.docFilterCriteria.category).some((category) =>
    props.docFilterCriteria.category[category]
  );
  const tagFilters = Object.keys(props.docFilterCriteria.tag).some((tag) =>
    props.docFilterCriteria.tag[tag]
  );
  const filteredCategories = [].concat(
    categoryFilters ? ["categories"] : [],
    tagFilters ? ["tags"] : []).join(" ");

  return <div>
    <div className="usa-grid-full document-list-header">
      <div className="usa-width-one-third">
        <SearchBar
          id="searchBar"
          onChange={props.setSearch}
          value={props.docFilterCriteria.searchQuery}
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
    </div>
    {filteredCategories.length > 0 && <div className="usa-alert usa-alert-info">
      <div className="usa-alert-body">
        <h3 className="usa-alert-heading">Showing limited results</h3>
        <p className="usa-alert-text">Documents are currently
          filtered by {filteredCategories}. <a onClick={props.clearAllFilters}>
          Click here to see all documents.</a></p>
      </div>
    </div>}
  </div>;
};

DocumentListHeader.propTypes = {
  searchQuery: PropTypes.string.isRequired,
  setSearch: PropTypes.func.isRequired,
  clearAllFilters: PropTypes.func,
  numberOfDocuments: PropTypes.number.isRequired
};

const mapStateToProps = (state) => ({
  numberOfDocuments: state.ui.filteredDocIds ? state.ui.filteredDocIds.length : _.size(state.documents),
  docFilterCriteria: state.ui.docFilterCriteria
});
const mapDispatchToProps = (dispatch) => ({
  clearAllFilters: () => dispatch(clearAllFilters()),
  setSearch: (searchQuery) => {dispatch(setSearch(searchQuery))}
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentListHeader);


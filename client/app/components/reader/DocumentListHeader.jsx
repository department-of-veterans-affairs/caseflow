import React, { PropTypes } from 'react';
import SearchBar from '../SearchBar';
import Button from '../Button';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setSearch } from '../../reader/actions';
import _ from 'lodash';

export const DocumentListHeader = (props) => {
  return <div className="usa-grid-full document-list-header">
    <div className="usa-width-one-third">
      <SearchBar
        id="searchBar"
        onChange={props.setSearch}
        value={props.searchQuery}
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

DocumentListHeader.propTypes = {
  searchQuery: PropTypes.string.isRequired,
  setSearch: PropTypes.func.isRequired,
  numberOfDocuments: PropTypes.number.isRequired
};

const mapStateToProps = (state) => ({
  numberOfDocuments: state.ui.filteredDocIds ? state.ui.filteredDocIds.length : _.size(state.documents),
  ..._.pick(state.ui.docFilterCriteria, 'searchQuery')
});
const mapDispatchToProps = (dispatch) => {
  return bindActionCreators({ setSearch }, dispatch);
};

export default connect(mapStateToProps, mapDispatchToProps)(DocumentListHeader);


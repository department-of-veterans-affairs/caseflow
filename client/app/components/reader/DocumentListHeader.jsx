import React, { PropTypes, Component } from 'react';
import SearchBar from '../SearchBar';
import Button from '../Button';
import { connect } from 'react-redux';
import { setSearch, clearAllFilters, clearSearch, toggleExpandAll } from '../../reader/actions';
import _ from 'lodash';

const DEBOUNCE_TIME_IN_MS = 150;

export class DocumentListHeader extends Component {
  constructor(props) {
    super(props);
    this.state = {
      value: ''
    };
    // debounce the passed in dispatch method
    this.changed = _.debounce(this.props.setSearch, DEBOUNCE_TIME_IN_MS);
  }

  componentWillReceiveProps(nextProps) {
    this.setState({ value: nextProps.docFilterCriteria.searchQuery });
  }

  handleChange = (value) => {
    this.setState({ value }, () => {
      this.changed(value);
    });
  }

  render() {
    const buttonText = this.props.expandAll ? 'Collapse all' : 'Expand all';

    const categoryFilters = Object.keys(this.props.docFilterCriteria.category).some((category) =>
      this.props.docFilterCriteria.category[category]
    );
    const tagFilters = Object.keys(this.props.docFilterCriteria.tag).some((tag) =>
      this.props.docFilterCriteria.tag[tag]
    );
    const filteredCategories = [].concat(
      categoryFilters ? ['categories'] : [],
      tagFilters ? ['tags'] : []).join(' ');

    return <div>
      <div className="usa-grid-full document-list-header">
        <div className="usa-width-one-third">
          <SearchBar
            id="searchBar"                                                                                               
            onChange={this.handleChange}
            onClearSearch={this.props.clearSearch}
            value={this.state.value}
          />
        </div>
        <div className="usa-width-one-third num-of-documents">
          {this.props.numberOfDocuments} Documents
        </div>
        <div className="usa-width-one-third">
          <span className="cf-right-side">
            <Button
              name={buttonText}
              onClick={this.props.toggleExpandAll}
              id="btn-default"
            />
          </span>
        </div>
      </div>
      {filteredCategories.length > 0 && <div className="usa-alert usa-alert-info">
        <div className="usa-alert-body">
          <h3 className="usa-alert-heading">Showing limited results</h3>
          <p className="usa-alert-text">Documents are currently
            filtered by {filteredCategories}. <a
              href="#"
              id="clear-filters"
              onClick={this.props.clearAllFilters}>
            Click here to see all documents.</a></p>
        </div>
      </div>}
    </div>;
  }
}

DocumentListHeader.propTypes = {
  setSearch: PropTypes.func.isRequired,
  expandAll: PropTypes.bool,
  toggleExpandAll: PropTypes.func,
  clearAllFilters: PropTypes.func,
  numberOfDocuments: PropTypes.number.isRequired
};

const mapStateToProps = (state) => ({
  expandAll: state.ui.expandAll,
  numberOfDocuments: state.ui.filteredDocIds ? state.ui.filteredDocIds.length : _.size(state.documents),
  docFilterCriteria: state.ui.docFilterCriteria
});
const mapDispatchToProps = (dispatch) => ({
  clearAllFilters: () => dispatch(clearAllFilters()),
  setSearch: (searchQuery) => {
    dispatch(setSearch(searchQuery));
  },
  clearSearch: () => {
    dispatch(clearSearch());
  },
  toggleExpandAll: () => {
    dispatch(toggleExpandAll());
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentListHeader);


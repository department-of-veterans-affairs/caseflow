import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { compact, values, size } from 'lodash';
import classNames from 'classnames';

import { clearAllFilters } from '../reader/DocumentList/DocumentListActions';
import Button from '../components/Button';

class HeaderFilterMessage extends React.PureComponent {
  doClearAllFilters = () => {
    // Call any passed clear functions for page elements
    this.props.clearAllFiltersCallbacks.forEach((filter) => filter());
    this.props.clearAllFilters();
  }

  render() {
    const props = this.props;

    // returns the number of truthy values in an object
    const getTruthyCount = (obj) => size(compact(values(obj)));

    const categoryCount = getTruthyCount(props.docFilterCriteria.category);
    const tagCount = getTruthyCount(props.docFilterCriteria.tag);
    const docTypeCount = getTruthyCount(props.docFilterCriteria.document);
    const receiptDateCount = getTruthyCount(props.docFilterCriteria.receiptFilterDates);

    const filteredCategories = compact([
      categoryCount && `Categories (${categoryCount})`,
      tagCount && `Issue tags (${tagCount})`,
      docTypeCount && `Document Types (${docTypeCount})`,
      receiptDateCount && `Receipt Date (${receiptDateCount})`
    ]).join(', ');

    const className = classNames('document-list-filter-message', {
      hidden: !filteredCategories.length
    });

    return (
      <p className={className}>
        Filtering by: {filteredCategories}.
        <Button
          id="clear-filters"
          name="clear-filters"
          classNames={['cf-btn-link']}
          onClick={this.doClearAllFilters}
        >Clear all filters.</Button>
      </p>
    );
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearAllFilters
}, dispatch);

HeaderFilterMessage.propTypes = {
  docFilterCriteria: PropTypes.object,
  clearAllFilters: PropTypes.func.isRequired,
  clearAllFiltersCallbacks: PropTypes.array.isRequired
};

export default connect(null, mapDispatchToProps)(HeaderFilterMessage);

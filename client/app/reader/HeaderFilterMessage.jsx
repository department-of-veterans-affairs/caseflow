import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { compact, values, size } from 'lodash';
import classNames from 'classnames';

import { clearAllFilters } from '../reader/DocumentList/DocumentListActions';
import Button from '../components/Button';

class HeaderFilterMessage extends React.PureComponent {
  render() {
    const props = this.props;

    // returns the number of truthy values in an object
    const getTruthyCount = (obj) => size(compact(values(obj)));

    const categoryCount = getTruthyCount(props.docFilterCriteria.category);
    const tagCount = getTruthyCount(props.docFilterCriteria.tag);
    // TODO: document type
    // TODO: receipt date

    const filteredCategories = compact([
      categoryCount && `Categories (${categoryCount})`,
      tagCount && `Issue tags (${tagCount})`
      // TODO: document type
      // TODO: receipt date
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
          onClick={props.clearAllFilters}
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
  clearAllFilters: PropTypes.func.isRequired
};

export default connect(null, mapDispatchToProps)(HeaderFilterMessage);

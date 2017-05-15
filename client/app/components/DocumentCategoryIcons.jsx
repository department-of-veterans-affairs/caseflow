import React, { PropTypes } from 'react';
import * as Constants from '../reader/constants';
import { connect } from 'react-redux';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from '../reader/utils';
import { PerfDebugPureComponent } from '../util/PerfDebug';

export class DocumentCategoryIcons extends PerfDebugPureComponent {
  render() {
    const { doc } = this.props;

    if (!doc) {
      return null;
    }

    return <ul className="cf-document-category-icons" aria-label="document categories">
      {
        _(Constants.documentCategories).
          filter(
            (category, categoryName) => doc[categoryFieldNameOfCategoryName(categoryName)]
          ).
          sortBy('renderOrder').
          map((category) => {
            const Svg = category.svg;

            return <li
              className="cf-no-styling-list"
              key={category.renderOrder}
              aria-label={category.humanName}>
              <Svg />
            </li>;
          }).
          value()
      }
    </ul>;
  }
}

DocumentCategoryIcons.propTypes = {
  documents: PropTypes.object,
  docId: PropTypes.number.isRequired
};

const mapPropsToState = (state, ownProps) => ({doc: state.documents[ownProps.docId]});

export default connect(mapPropsToState)(DocumentCategoryIcons);

import React, { PropTypes } from 'react';
import * as Constants from './constants';
import { closeSymbolHtml } from '../components/RenderFunctions';
import _ from 'lodash';

const DropdownFilter = () => {
  return <div>
    <div>
      Clear category filter {closeSymbolHtml()}
    </div>
    <ul>
      {
        _(Constants.documentCategories).
          toPairs().
          // eslint-disable-next-line no-unused-vars
          sortBy(([name, category]) => category.renderOrder).
          map(
            ([categoryName, category]) => <li key={categoryName}>
              <ConnectedCategorySelector category={category}
                categoryName={categoryName} docId={this.props.doc.id} />
            </li>
          ).
          value()
      }
    </ul>
  </div>;
};

export default DropdownFilter;

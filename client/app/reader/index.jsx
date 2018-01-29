import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';

import DecisionReviewer from './DecisionReviewer';

import { reduxSearch } from 'redux-search';
import rootReducer from './reducers';

class Reader extends React.PureComponent {
  componentWillMount() {
    const enhancers = [
      reduxSearch({
      // Configure redux-search by telling it which resources to index for searching
        resourceIndexes: {
          extractedText: ['text']
        },
        // This selector is responsible for returning each collection of searchable resources
        resourceSelector: (resourceName, state) => state.searchActionReducer[resourceName]
      })
    ];

    this.setState({ enhancers });

  }
  render = () =>
    <ReduxBase reducer={rootReducer} enhancers={this.state.enhancers}>
      <DecisionReviewer {...this.props} />
    </ReduxBase>;
}

export default Reader;

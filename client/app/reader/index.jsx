import React from 'react';
import ReduxBase from '../util/ReduxBase';

import DecisionReviewer from './DecisionReviewer';

import { reduxSearch } from 'redux-search';
import rootReducer from './reducers';

class Reader extends React.PureComponent {
  componentWillMount() {
    const enhancers = [
      reduxSearch({
      // Configure redux-search by telling it which resources to index for searching
        resourceIndexes: {
        // In this example Books will be searchable by :title and :author
          extractedText: ['text']
        },
        // This selector is responsible for returning each collection of searchable resources
        resourceSelector: (resourceName, state) => {
        // In our example, all resources are stored in the state under a :resources Map
        // For example "books" are stored under state.resources.books
          return state.searchActionReducer[resourceName];
        }
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

import React from 'react';
import NarrativeTable from './components/NarrativeTable';
import PropTypes from 'prop-types';

class Explain extends React.PureComponent {
  render = () => {
    const narratives = this.props.eventData;

    return (
      <React.Fragment>
        <NarrativeTable
          eventData={narratives} />
      </React.Fragment>
    );
  };
}

Explain.propTypes = {
  eventData: PropTypes.object,
};

export default Explain;

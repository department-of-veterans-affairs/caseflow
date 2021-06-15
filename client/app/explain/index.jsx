import React from 'react';
import useSelector from 'react-redux';
import NarrativeTable from './components/NarrativeTable'

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

export default Explain;

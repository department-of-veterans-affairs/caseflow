import React from 'react';
import CancelEdit from './CancelEdit';
import Button from '../../components/Button';

class CancelOrSave extends React.PureComponent {
  // save button not yet implemented
  render = () => {
    return <div>
      <CancelEdit history={this.props.history}/>
      <Button
        id="save-edit"
        legacyStyling={false}
      >
        Save
      </Button>
    </div>
  }
}

export default CancelOrSave;

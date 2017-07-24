import React, {PureComponent} from 'react';
import ToggleButton from '../components/ToggleButton';
import Button from '../components/Button';
import { connect } from 'react-redux';

class DocumentsCommentsButton extends PureComponent {
  handleButtonClick = () => {}

  render() {
    return <ToggleButton active="documents" onClick={this.handleButtonClick}>
      <Button name="documents" style={{marginLeft: 0}}>
        Documents
      </Button>
      <Button name="comments">
        Comments
      </Button>
    </ToggleButton>;
  }
}

export default connect(

)(DocumentsCommentsButton);

import React from 'react';
import { withRouter } from 'react-router-dom';
import Button from '../../components/Button';
import COPY from '../../../COPY.json';

class BulkAssignButton extends React.PureComponent {
  changeRoute = () => {
    let baseUrl = this.props.location.pathname;

    // Remove the trailing slash if it exists so we navigate to the correct URl.
    baseUrl = baseUrl.slice(-1) === '/' ? baseUrl.slice(0, -1) : baseUrl;

    this.props.history.push(`${baseUrl}/modal/bulk_assign_tasks`);
  }

  render = () => <Button classNames={['bulk-assign-button']} onClick={this.changeRoute}>
    {COPY.BULK_ASSIGN_BUTTON_TEXT}
  </Button>;
}

export default (withRouter(BulkAssignButton));

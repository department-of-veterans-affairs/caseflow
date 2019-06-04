import React from 'react';
import { withRouter } from 'react-router-dom';
import Button from '../../components/Button';

class BulkAssignButton extends React.PureComponent {
  changeRoute = () => this.props.history.push(`${this.props.location.pathname}/modal/bulk_assign_tasks`);

  render = () => <Button classNames={['bulk-assign-button']} onClick={this.changeRoute}>Assign Tasks</Button>;
}

export default (withRouter(BulkAssignButton));

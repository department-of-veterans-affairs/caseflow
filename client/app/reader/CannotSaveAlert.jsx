import React, { PureComponent } from 'react';
import Alert from '../components/Alert';

export default class CannotSaveAlert extends PureComponent {
  render() {
    let messages = ['Unable to save.'];

    if (this.props.message) {
      messages.push(this.props.message);
    } else {
      messages.push('Please try again.');
    }

    return <Alert type="error" message={messages.join(' ')} />;
  }
}

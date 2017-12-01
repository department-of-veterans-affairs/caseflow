import React, { PureComponent } from 'react';
import Alert from '../components/Alert';

export default class CannotSaveAlert extends PureComponent {
  render() {
<<<<<<< HEAD
    return <Alert type="error" message="Unable to save. Please try again." />;
=======
    let messages = ['Unable to save.'];

    if (this.props.message) {
      messages.push(this.props.message);
    } else {
      messages.push('Please try again.');
    }

    return <Alert type="error" message={messages.join(' ')} />;
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b
  }
}

import React, { PureComponent } from 'react';
import Alert from '../components/Alert';

export default class CannotSaveAlert extends PureComponent {
  render() {
    return <Alert type="error" message="Unable to save. Please try again." />;
  }
}

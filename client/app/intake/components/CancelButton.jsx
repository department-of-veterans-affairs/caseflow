import React from 'react';
import Button from '../../components/Button';

export default class CancelButton extends React.PureComponent {
  render = () => <Button legacyStyling={false} willNeverBeLoading>Cancel Intake</Button>
}

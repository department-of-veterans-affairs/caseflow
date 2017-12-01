import React from 'react';
import Button from '../../components/Button';
import BareOrderedList from '../../components/BareOrderedList';

export default class Finish extends React.PureComponent {
  render() {
    const steps = [
      <span>Upload the RAMP election form to VBMS and ensure the Document Type is <em>Correspondence</em>.</span>,
      <span>Update the Subject Line with <em>RAMP Opt-In</em>.</span>,
      <span>Create an EP <strong>030 RAMP Supplemental</strong> in VBMS.</span>,
      <span>Add a placeholder contention of <em>RAMP</em>.</span>
    ];
    const stepFns = steps.map((step, index) => () => <span><strong>Step {index}.</strong> {step}</span>);

    return <div>
      <h1>Finish processing Supplemental Claim request</h1>
      <p>Please complete the following 4 steps outside Caseflow.</p>
      <BareOrderedList className="cf-steps-outside-of-caseflow-list" items={stepFns} />
    </div>;
  }
}

export class FinishNextButton extends React.PureComponent {
  handleClick = () => this.props.history.push('/completed');

  render = () => <Button onClick={this.handleClick}>I've completed all the steps</Button>;
}

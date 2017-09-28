import React from 'react';
import Button from '../../components/Button';

export default class Finish extends React.PureComponent {
  render() {

    const steps = [
      <span>Upload the RAMP election form to VBMS and ensure the Document Type is <em>Correspondence</em>.</span>,
      <span>Update the Subject Line with <em>RAMP Opt-In</em>.</span>,
      <span>Create an EP <strong>030 RAMP Supplemental</strong> in VBMS.</span>,
      <span>Add a placeholder contention of <em>RAMP</em></span>,
    ]

    return <div>
      <h1>Finish processing Supplemental Claim request</h1>
      <p>Please complete the following 4 steps outside Caseflow.</p>
      <ol>
        {
          steps.map((step, index) => 
            <li><strong>Step {index}.</strong>{step}</li>
          )
        }
      </ol>
    </div>;
  }
}

export class FinishNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.history.push('/completed')
  }

  render() {
    return <Button onClick={this.handleClick}>I've completed all the steps</Button>
  }
}

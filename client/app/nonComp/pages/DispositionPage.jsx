import React from 'react';
import { connect } from 'react-redux';

import Button from '../../components/Button';

class NonCompDispositionsPage extends React.PureComponent {
  render = () => {
    console.log(this.props);
    const {
      appeal,
      businessLine,
      task
    } = this.props;

    return <div>
      <h1>{businessLine}</h1>
      <div className="review-details">
       <div className="usa-grid-full">
        <div className="usa-width-one-half">
         <h3 className="claimant-name">{task.claimant.name}</h3>
         | <strong>Relationship to Veteran</strong> {task.claimant.relationship}
        </div>
        <div className="usa-width-one-half cf-txt-r">
         <span><strong>Intake date</strong> {appeal.receiptDate}</span>
         <span>Veteran ID: {appeal.veteran.fileNumber}</span>
        </div>
       </div>
       <div className="usa-grid-full">
        <div className="usa-width-one-half">
        { appeal.veteranIsNotClaimant ? "Veteran Name `${appeal.veteran.name}`" : "" }
        </div>
        <div className="usa-width-one-half cf-txt-r">
         <span>SSN: TODO</span>
        </div>
       </div>
      </div>
      <div className="decisions">
       <div className="usa-grid-full">
        <div className="usa-width-one-half">
         <h2>Decision</h2>
         <div>Review each issue and assign the appropriate dispositions.</div>
        </div>
        <div className="usa-width-one-half cf-txt-r">
          <a className="cf-link-btn" href={`/intake/${appeal.id}/edit`}>
           Edit Issues
          </a>
        </div>
       </div> 
      </div>
    </div>;
  }
}

const DispositionPage = connect(
  (state) => ({
    appeal: state.appeal,
    businessLine: state.businessLine,
    task: state.task
  })
)(NonCompDispositionsPage);

export default DispositionPage;

import React from 'react';
import Button from '../../components/Button';

let StyleGuideAction = () => {
  return <div>
    <div className="cf-app cf-push-row cf-sg-layout cf-app-segment cf-app-segment--alt">
    </div>
    <div className="cf-app-segment" id="establish-claim-buttons">
      <div className="cf-push-left">
        <Button
          name="Back To Preview"
          classNames={['cf-btn-link']}
        />
      </div>
      <div className="cf-push-right">
        <Button
          name="Cancel"
          classNames={['cf-btn-link', 'cf-adjacent-buttons']}
        />
        <Button
          name="Submit End Product"
          classNames={['usa-button-primary']}
        />
      </div>
    </div>
  </div>;
};

export default StyleGuideAction;

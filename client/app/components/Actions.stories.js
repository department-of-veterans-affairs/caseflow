import React from 'react';
import Button from './Button';

export default {
  title: 'Commons/Components/Layout/Actions',
};

const Template = () => (
  <div>
    <div className="cf-app-segment cf-app-segment--alt"></div>
    <div className="cf-app-segment" id="establish-claim-buttons">
      <div className="cf-push-left">
        <Button
          name="Back"
          classNames={['cf-btn-link']}
        />
      </div>
      <div className="cf-push-right">
        <Button
          name="Cancel"
          classNames={['cf-btn-link']}
        />
        <Button
          name="Submit"
          classNames={['usa-button-primary']}
        />
      </div>
    </div>
  </div>
);

export const Actions = Template.bind({});

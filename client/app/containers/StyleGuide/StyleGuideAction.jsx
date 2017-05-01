import React from 'react';

import Button from '../../components/Button';
import InlineForm from '../../components/InlineForm';


export default class StyleGuideAction extends React.Component {

  render () {
    return (
      <div>
      <div className="cf-app cf-push-row cf-sg-layout cf-app-segment cf-app-segment--alt"></div>
       <p>
        <div className="cf-app-segment" id="establish-claim-buttons">
          <div className="usa-width-one-half">
           <InlineForm>
            <span><Button
               name="Back to Preview"
               classNames={['cf-btn-link']} />
            </span>
          </InlineForm>
         </div>
        <div className ="cf-push-right">
           <Button
            name="Cancel"
           classNames={['cf-btn-link']}/>
          <Button
            name="Submit End Product"
          />
         </div>
        </div>
        </p>   
     </div>

    );
  }
}

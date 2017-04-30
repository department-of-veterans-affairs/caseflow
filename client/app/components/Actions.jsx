import React from 'react';
import Button from '../components/Button';

 export default class Actions extends React.Component {

  render () {
    return (
      <div>
      <div className="cf-app cf-push-row cf-sg-layout cf-app-segment cf-app-segment--alt"></div>
       <p>
        <div className="cf-app-segment" id="establish-claim-buttons">
          <div className="usa-width-one-half">
           <div className ="cf-push-left">
            <span><Button
               name="Back to Preview"
               classNames={['cf-btn-link']} />
            </span>
           </div>
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


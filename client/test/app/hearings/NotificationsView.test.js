import React from 'react';
import { render,screen  } from '@testing-library/react';
import { NotificationsView } from 'app/queue/NotificationsView';
import {
  BrowserRouter as Router,
} from "react-router-dom";
import { Provider } from 'react-redux';
import { createStore } from 'redux';


const createReducer = (storeValues) => {
  return function (state = storeValues) {

    return state;
  };
};

const setup = (props={}) => {
  const reducer = createReducer(props);
  const defaults = {};

 
  const store = createStore(reducer);

  return render(
    <Provider store={store} >
      <Router>
      <NotificationsView {...defaults} />
      </Router>
    </Provider>
  );
};
const appeal = {
  id:"1987",
appellant_hearing_email_recipient:null,
representative_hearing_email_recipient:null,
externalId:"e1bdff31-4268-4fd4-a157-ebbd48013d91",
docketName:"hearing",
withdrawn:false,
removed:false,
overtime:false,
contestedClaim:false,
veteranAppellantDeceased:false,
isLegacyAppeal:false,
caseType:"Original",
isAdvancedOnDocket:false,
issueCount:0,
docketNumber:"220715-1987",
assignedAttorney:null,
assignedJudge:null,
distributedToJudge:false,
veteranFullName:"Bob Smithschumm",
veteranFileNumber:"200000161",
isPaperCase:false,
readableHearingRequestType:null,
readableOriginalHearingRequestType:null,
vacateType:null
};

const props = {
  
    queue:{
      appealId:"e1bdff31-4268-4fd4-a157-ebbd48013d91",
      appeals:{"e1bdff31-4268-4fd4-a157-ebbd48013d91":appeal} 

    },
    ui:{
    organizations:
    [{name: "Hearings Management",  url: "hearings-management"}]
    
    },
  
 
}


describe('NotificationsTest', () => {
  
  
  it('renders correctly', () => {
   
        const  container  = setup(props);
 });

});
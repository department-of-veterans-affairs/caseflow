import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import AppFrame from '../components/AppFrame';
import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import CertificationHelp from './CertificationHelp';
import HearingsHelp from './HearingsHelp';
import ReaderHelp from './ReaderHelp';
import DispatchHelp from './DispatchHelp';
import IntakeHelp from './IntakeHelp';

class Help extends React.PureComponent {

     helpRoot = () => <div> <h1>Caseflow Help</h1>
       <ul id="toc" className="usa-unstyled-list">
         <li><a href="/certification/help">Certification Help</a></li>
         <li><a href="/dispatch/help">Dispatch Help</a></li>
         <li><a href="/reader/help">Reader Help</a></li>
         <li><a href="/hearings/help">Hearings Help</a></li>
         <li><a href="/intake/help">Intake Help</a></li>
       </ul></div>

     render() {

       return <BrowserRouter>
         <div>
           <NavigationBar
             userDisplayName={this.props.userDisplayName}
             dropdownUrls={this.props.dropdownUrls}
             appName="Help"
             defaultUrl="/"
             logoProps={{
               accentColor: COLORS.GREY_DARK,
               overlapColor: COLORS.GREY_DARK
             }} />
           <AppFrame>
             <div className="cf-app-width cf-app-segment cf-app-segment--alt">
               <PageRoute
                 exact
                 path="/help"
                 title="Caseflow Help"
                 component={this.helpRoot} />
               <PageRoute
                 exact
                 path="/"
                 title="Caseflow Help"
                 component={this.helpRoot} />
               <PageRoute
                 exact
                 path="/certification/help"
                 title="Certification Help"
                 component={CertificationHelp} />
               <PageRoute
                 exact
                 path="/reader/help"
                 title="Reader Help"
                 component={ReaderHelp} />
               <PageRoute
                 exact
                 path="/hearings/help"
                 title="Hearings Help"
                 component={HearingsHelp} />
               <PageRoute
                 exact
                 path="/dispatch/help"
                 title="Dispatch Help"
                 component={DispatchHelp} />
               <PageRoute
                 exact
                 path="/intake/help"
                 title="Intake Help"
                 component={IntakeHelp} />

             </div>
           </AppFrame>
           <Footer
             appName="Help"
             feedbackUrl={this.props.feedbackUrl}
             buildDate={this.props.buildDate} />
         </div>
       </BrowserRouter>;
     }
}
export default Help;


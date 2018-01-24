import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import AppFrame from '../components/AppFrame';
import PageRoute from '../components/PageRoute';
import PrimaryAppContent from '../components/PrimaryAppContent';
import NavigationBar from '../components/NavigationBar';
import { COLORS } from '@department-of-veterans-affairs/appeals-frontend-toolkit/util/StyleConstants';
import Footer from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/Footer';
import CertificationHelp from './certificationHelp';

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
             defaultUrl="/"
             userDisplayName={this.props.userDisplayName}
             dropdownUrls={this.props.dropdownUrls}
             appName="Help"
             logoProps={{
               accentColor: COLORS.GREY_DARK,
               overlapColor: COLORS.GREY_DARK
             }} />
           <AppFrame>
             <PrimaryAppContent>
               <PageRoute
                 exact
                 path="/help"
                 title="Help"
                 component={this.helpRoot} />
               <PageRoute
                 exact
                 path="/certification/help"
                 title="Certification Help"
                 component={CertificationHelp} />

             </PrimaryAppContent>
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


import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import StyleGuideAction from './StyleGuideAction';
import StyleGuideNavigationBar from './StyleGuideNavigationBar';
import StyleGuideUserDropdownMenu from './StyleGuideUserDropdownMenu';
import StyleGuideFooter from './StyleGuideFooter';

export default function StyleGuideLayout (){

  return <div>
    <h2 id="layout">Layout</h2>

    <p>
      Any Caseflow app should always follow the same layout and structure shown here.
      At the top of the application is the Navigation Bar. 
      Next, sitting on the canvass of the application is the main content area. 
      This is where the title of the page, instructions for the user, and detailed interaction should be placed. 
      The primary and secondary actions sit below the main content area. 
      Finally, the Footer should go at the bottom of the app.
   </p>

    <p>
      We try to be consistent in this layout across all our applications 
      so that our interface is predictable and familiar to our user.
      The consistency also helps us reuse common code in Caseflow Commons.</p>

    <h3 id="app-canvas">App Canvas</h3>

    <p>
      Almost all of the interaction in Caseflow takes place in an App Canvas.
      The content starts off with a page title and minimal instructions for what the user
      needs to do to complete their task on the page.
      It then contains any interaction that well help this to accomplish their task including forms,
      document previews, tables, error messages, and more.
    </p>

    <StyleGuideNavigationBar />
    <br/>
    <StyleGuideUserDropdownMenu />
    <br/>
    <StyleGuideAction />
     <br/>
    <StyleGuideFooter />

  </div>;
}


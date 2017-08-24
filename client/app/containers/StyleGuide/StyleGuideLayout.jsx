import React from 'react';
import StyleGuideAction from './StyleGuideAction';
import StyleGuideNavigationBar from './StyleGuideNavigationBar';
import StyleGuideUserDropdownMenu from './StyleGuideUserDropdownMenu';
import StyleGuideFooter from './StyleGuideFooter';
import StyleGuideHorizontalLine from './StyleGuideHorizontalLine';

export default function StyleGuideLayout () {

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

    <br/>
    <StyleGuideNavigationBar />
    <br/>
    <StyleGuideUserDropdownMenu />
    <br/>
    <h3 id="app-canvas">Main Content Area</h3>
    <p>
      The main content area is where we put all the application-specific interaction.
      This includes things like a Queue of tasks for the user to perform,
      workflow specific actions, document previews, confirmation messages, and more.
      The background of the main content area is #f9f9f9.</p>
    <br/>

    <h3 id="app-canvas">App Canvas</h3>

    <p>
      Almost all of the interaction in Caseflow takes place in an App Canvas.
      The content starts off with a page title and minimal instructions for what the user
      needs to do to complete their task on the page.
      It then contains any interaction that well help this to accomplish their task including forms,
      document previews, tables, error messages, and more.
      The canvas has a default standard width but can be adjusted according to the needs of each application.</p>
    <br/>
    <StyleGuideAction />
    <br/>
    <StyleGuideHorizontalLine />
    <br/>
    <StyleGuideFooter />

  </div>;
}

import React from 'react';

// components
import TabWindow from '../../components/TabWindow';
// import RenderFunctions from '../../components/RenderFunctions';
import { crossSymbolHtml, checkSymbolHtml } from '../../components/RenderFunctions';

export default class StyleGuideTabs extends React.Component {
  render() {

    let {
      tabHeaders,
      tabHeadersWithIcons,
      tabPages,
      tabPagesWithIcons
    } = this.props;

    tabHeaders = [
      { label: "Tab 1" },
      { label: "Tab 2" },
      { label: "Tab 3" }
    ];

    tabHeadersWithIcons = [{
      disable: false,
      icon: checkSymbolHtml(),
      label: "Active Tab",
      page: "1"
    }, {
      disable: false,
      icon: checkSymbolHtml(),
      label: "Enabled Tab",
      page: "2"
    }, {
      disable: true,
      icon: crossSymbolHtml(),
      label: "Disabled Tab",
      page: "3"
    }
    ];

    tabPages = [
      "1",
      "2",
      "3"
    ];

    tabPagesWithIcons = [
      "This is an 'Active' Tab.",
      "This is an 'Enabled' Tab.",
      "This is a 'Disabled' Tab"
    ];

    return <div>
      <h2 id="tabs">Tabs</h2>
      <h3>Tabs without Icons</h3>
      <p>
        The US Web Design doesn’t include tabs so we’ve designed our own.
        The active tab is highligted with a blue border and blue text.
        Inactive tabs have grey text. Disabled tabs are grey, have faded grey text,
        and cannot be clicked.
      </p>
      <TabWindow
        tabs={tabHeaders}
        pages={tabPages}
        onChange={this.onTabSelected}/>
      <h3>Tabs with Icons</h3>
      <p>
        Icons are optional on tabs and are set by the designer in the mockup.
        These icons come from the Font Awesome package, which is set in the
        U.S. Design standards. Here is an example of tabs with icons:
      </p>
      <TabWindow
        tabs={tabHeadersWithIcons}
        pages={tabPagesWithIcons}
        onChange={this.onTabSelected}/>
      <p><a href="#">View the tab code sample in React.</a></p>

  </div>;
  }
}

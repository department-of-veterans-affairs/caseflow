import React from 'react';

// components
import TabWindow from '../../components/TabWindow';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import { crossSymbolHtml, checkSymbolHtml } from '../../components/RenderFunctions';

export default class StyleGuideTabs extends React.Component {
  render() {

    let {
      tabs,
      tabsWithIcons
    } = this.props;

    tabs = [
      {
        label: "Tab 1",
        page: " "
      },
      {
        label: "Tab 2",
        page: " "
      },
      {
        label: "Tab 3",
        page: " "
      }
    ];

    tabsWithIcons = [{
      disable: false,
      icon: checkSymbolHtml(),
      label: "Active Tab",
      page: " "
    }, {
      disable: false,
      icon: checkSymbolHtml(),
      label: "Enabled Tab",
      page: " "
    }, {
      disable: true,
      icon: crossSymbolHtml(),
      label: "Disabled Tab",
      page: " "
    }
    ];

    return <div>
      <br />
      <StyleGuideComponentTitle
        title="Tabs"
        id="tabs"
        link="StyleGuideTabs.jsx"
      />
      <h3>Tabs without Icons</h3>
      <p>
        The US Web Design doesn’t include tabs so we’ve designed our own.
        The active tab is highligted with a blue border and blue text.
        Inactive tabs have grey text. Disabled tabs are grey, have faded grey text,
        and cannot be clicked.
      </p>
      <TabWindow
        tabs={tabs}
        onChange={this.onTabSelected}/>
      <h3>Tabs with Icons</h3>
      <p>
        Icons are optional on tabs and are set by the designer in the mockup.
        These icons come from the Font Awesome package, which is set in the
        U.S. Design standards. Here is an example of tabs with icons:
      </p>
      <TabWindow
        tabs={tabsWithIcons}
        onChange={this.onTabSelected}/>
  </div>;
  }
}

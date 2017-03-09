import React from 'react';

// components
import TabWindow from '../../components/TabWindow';
// import RenderFunctions from '../../components/RenderFunctions';
import { closeSymbolHtml, successSymbolHtml, missingSymbolHtml } from '../../components/RenderFunctions.jsx';

export default class StyleGuideTabs extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      tabText: "HI"
    };

  }

  render() {

    let {
      tabHeaders,
      tabHeadersWithIcons,
      tabPages,
      tabPagesWithIcons
    } = this.props;

    tabHeaders = [
      {label: "Tab 1"},
      {label: "Tab 2"},
      {label: "Tab 3"}
    ];

    tabHeadersWithIcons = [{
        label: "Active Tab",
        icon: successSymbolHtml()
      },{
        label: "Enabled Tab",
        icon: successSymbolHtml()
      },{
        label: "Disabled Tab",
        icon: missingSymbolHtml(),
        disable: true
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
    </div>;
  }
}

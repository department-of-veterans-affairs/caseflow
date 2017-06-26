import React from 'react';
import Collapse, { Panel } from 'rc-collapse';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideAccordions extends React.Component {
  render = () => {
    return <div>
    <StyleGuideComponentTitle
      title="Accordions"
      id="accordions"
      link="StyleGuideAccordions.jsx"
    />
  <p>Our accordion style was taken from the US Web Design Standards.
    Accordions are a list of headers that can be clicked to hide or reveal additional
    content.</p>
    <Collapse accordion={true} className="usa-accordion">
      <Panel header="hello" headerClass="usa-accordion-button">
        <div className="usa-accordion-content">
          this is panel content
        </div>
      </Panel>
      <Panel header="title2" headerClass="usa-accordion-button">
        <div className="usa-accordion-content">
          this is panel content2 or other
        </div>
      </Panel>
    </Collapse>
    </div>;
  }
}

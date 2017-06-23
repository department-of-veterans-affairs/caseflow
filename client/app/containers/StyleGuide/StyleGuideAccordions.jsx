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
    <Collapse accordion={true}>
      <Panel header="hello" headerClass="my-header-class">this is panel content</Panel>
      <Panel header="title2">this is panel content2 or other</Panel>
    </Collapse>
    </div>;
  }
}

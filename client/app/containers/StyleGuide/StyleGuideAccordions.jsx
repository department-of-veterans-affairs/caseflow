import React from 'react';
import { Accordion } from '../../components/Accordion';
import AccordionSection from '../../components/AccordionSection';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideAccordions extends React.PureComponent {
  render = () => {
    const sgAccordionSections = [1, 2, 3, 4, 5].map((header) => {
      return (<AccordionSection title={`Example title ${header}`} key={header}>
        <p>
          Millions of Americans interact with government services every day.
          Veterans apply for benefits. Students compare financial aid options.
          Small business owners seek loans. Too often, outdated tools and complex
          systems make these interactions cumbersome and frustrating. Enter the
          United States Digital Service. We partner leading technologists with
          dedicated public servants to improve the usability and reliability of
          our government's most important digital services.
          Visit USDS.gov to learn more.
        </p>
      </AccordionSection>);
    });

    return <div>
      <StyleGuideComponentTitle
        title="Accordions"
        id="accordions"
        link="StyleGuideAccordions.jsx"
      />
      <p>Our accordion style was taken from the US Web Design Standards.
    Accordions are a list of headers that can be clicked to hide or reveal additional
    content.</p>

      <h3 id="border">Border</h3>
      <Accordion style="bordered" accordion>
        {sgAccordionSections}
      </Accordion>

      <h3 id="borderless">Borderless</h3>
      <Accordion style="borderless" accordion>
        {sgAccordionSections}
      </Accordion>

      <h3 id="bordered-outline">Bordered Outline</h3>
      <Accordion style="outline" accordion>
        {sgAccordionSections}
      </Accordion>
    </div>;
  }
}

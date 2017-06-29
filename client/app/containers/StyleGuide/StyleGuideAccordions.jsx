import React from 'react';
import Accordion from '../../components/Accordion';
import AccordionHeader from '../../components/AccordionHeader';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideAccordions extends React.PureComponent {
  render = () => {
    const sgAccordionHeaders = [1, 2, 3, 4, 5].map((header) => {
      return (<AccordionHeader title={`Example title ${header}`} key={header}>
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
      </AccordionHeader>);
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

    <h3>Border</h3>
    <Accordion style="bordered">
      {sgAccordionHeaders}
    </Accordion>

    <h3>Borderless</h3>
    <Accordion style="borderless">
      {sgAccordionHeaders}
    </Accordion>

    <h3>Bordered Outline</h3>
    <Accordion style="outline">
      {sgAccordionHeaders}
    </Accordion>
    </div>;
  }
}

import React from 'react';

import Table from '../../app/components/Table';

const columns = [
  {
    header: 'Text Style',
    valueName: 'textStyle'
  },
  {
    header: 'CSS Rules',
    valueName: 'rules'
  }
];

const rowObjects = [
  {
    textStyle: <h1 className="cf-display-1">Display 1</h1>,
    rules: (
      <span>
        <span>font-family: ‘Source Sans Pro’</span>
        <span>font-weight: 700</span>
        <span>font-size: 52px</span>
        <span>line-height: 1.3em/68px</span>
      </span>
    )
  },
  {
    textStyle: <h2 className="cf-display-2">Display 2</h2>,
    rules: (
      <span>
        <span>font-family: ‘Source Sans Pro’</span>
        <span>font-weight: 300</span>
        <span>font-size: 44px</span>
        <span>line-height: 1.3em/57px</span>
      </span>
    )
  },
  {
    textStyle: <h1>Heading 1</h1>,
    rules: (
      <span>
        <span>font-family: ‘Source Sans Pro’</span>
        <span>font-weight: 700</span>
        <span>font-size: 34px</span>
        <span>line-height: 1.3em/44px</span>
      </span>
    )
  },
  {
    textStyle: <h2>Heading 2</h2>,
    rules: (
      <span>
        <span>font-family: ‘Source Sans Pro’</span>
        <span>font-weight: 700</span>
        <span>font-size: 24px</span>
        <span>line-height: 1.3em/31px</span>
      </span>
    )
  },
  {
    textStyle: <h3>Heading 3</h3>,
    rules: (
      <span>
        <span>font-family: ‘Source Sans Pro’</span>
        <span>font-weight: 700</span>
        <span>font-size: 19px</span>
        <span>line-height: 1.3em/25px</span>
      </span>
    )
  },
  {
    textStyle: <h4>Heading 4</h4>,
    rules: (
      <span>
        <span>font-family: ‘Source Sans Pro’</span>
        <span>font-weight: 700</span>
        <span>font-size: 15px</span>
        <span>line-height: 1.3em/20px</span>
      </span>
    )
  },
  {
    textStyle: <h5>Heading 5</h5>,
    rules: (
      <span>
        <span>font-family: ‘Source Sans Pro’</span>
        <span>font-weight: 400</span>
        <span>font-size: 13px</span>
        <span>line-height: 1.3em/17px</span>
      </span>
    )
  },
  {
    textStyle: <p className="cf-lead-paragraph">Lead paragraph</p>,
    rules: (
      <span>
        <span>font-family: ‘Source Sans Pro’</span>
        <span>font-weight: 300</span>
        <span>font-size: 19px</span>
        <span>line-height: 1.5em/33px</span>
      </span>
    )
  },
  {
    textStyle: <p>Body copy. A series of sentences together which make a paragraph.</p>,
    rules: (
      <span>
        <span>font-family: ‘Source Sans Pro’</span>
        <span>font-weight: 400</span>
        <span>font-size: 17px</span>
        <span>line-height: 1.5em/26px</span>
      </span>
    )
  },
  {
    textStyle: (
      <p>
        <i>Italic body copy. A series of sentences together which make a paragraph.</i>
      </p>
    ),
    rules: (
      <span>
        <span>font-family: ‘Source Sans Pro’</span>
        <span>font-style: Italic</span>
        <span>font-weight: 400</span>
        <span>font-size: 17px</span>
        <span>line-height: 1.5em/26px</span>
      </span>
    )
  }
];

export const TextStyles = () => (
  <Table
    className="cf-sg-typography-text-styles"
    columns={columns}
    rowObjects={rowObjects}
    summary="Caseflow Typography - Text Styles"
    slowReRendersAreOk
  />
);

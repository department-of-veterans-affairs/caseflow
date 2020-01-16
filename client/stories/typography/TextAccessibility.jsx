import React from 'react';

const Colors = {
  Base: '#212121',
  Gray: '#5b616b',
  Primary: '#0071bc',
  Secondary: '#e31c3d',
  Green: '#2e8540'
};

const Combos = ['Base', 'Gray', 'Primary', 'Secondary', 'Green'];

export const TextAccessibility = () => (
  <React.Fragment>
    {Combos.map((name) => (
      <div className="sg-colors-combo" key={name} style={{ color: Colors[name] }}>
        <b>{name.toLowerCase()} - on white</b>
      </div>
    ))}
  </React.Fragment>
);

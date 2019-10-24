import React from 'react'

export default class StatisticCard extends React.Component {
  render() {
    let {
      title,
      value,
      color,
      fa_class_name
    } = this.props

    return <div {...css({ color: color,
      position: absolute,
      width: '212px',
      height: '110.11px',
      left: '96px',
      top: '113.95px',
      boxShadow: '0px 4px 4px rgba(0, 0, 0, 0.25)'})}>

      <h4>{title}</h4>
      <i classname={fa_class_name}></i>
      <p>{value}</p>
    </div>
  }
}



import React, { Component, PropTypes} from 'react';
import html2canvas from 'html2canvas';
import jspdf from 'jspdf';

export default class Export extends Component {
  constructor(props) {
    super(props);
  }

  printDocument() {
    const input = document.getElementById('divToPrint');
    html2canvas(input)
      .then((canvas) => {
        const imgData = canvas.toDataURL('image/png');
        const pdf = new jspdf();
        pdf.addImage(imgData, 'JPEG', 0, 0);
        pdf.save("worksheet.pdf");
      })
    ;
  }

  render() {
    return (<div>
      <div>
        <button onClick={this.printDocument}>Print</button>
      </div>
      <div id="divToPrint"  {...css({
        backgroundColor: '#f5f5f5',
        width: '200mm',
        minHeight: '200mm',
        marginLeft: 'auto',
        marginRight: 'auto'
      })}>
        <div>Test Page</div> 
        <div>--insert components here</div>
      </div>
    </div>);
  }
}
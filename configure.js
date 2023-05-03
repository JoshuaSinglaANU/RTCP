const fs = require('fs');

const config = {
  vulnerabilities: [
    {
      SQL_Injection: 2,
      URL_rewriting: 1,
      Authentication: 1,
      XSS: 1,
      Paramater_tampering: 0,
      Admin_Console: 1,
      Directory_Listing: 1,
      SSL: 1
    }
  ]
};

const json = JSON.stringify(config, null, 2);

fs.writeFile('config.json', json, (err) => {
  if (err) {
    console.error(err);
    return;
  }
  console.log('JSON data has been written to file');
});

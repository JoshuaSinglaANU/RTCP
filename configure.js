const fs = require('fs');

const config = {
  vulnerabilities: [
    {
      SQL_Injection: 2,
      URL_rewriting: 1,
      Authentication: 0,
      XSS: 1,
      Paramater_tampering: 0,
      Admin_Console: 1,
      Directory_Listing: 1,
      SSL: 0
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

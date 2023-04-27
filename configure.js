const fs = require('fs');

const config = {
    vulnerabilities : [
        {
            street: 1
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

# JSX Number Format
This is a lightweight js number formatting library
## To install
 _npm install jsx-number-format_
 
# Usage
- Syntax
```javascript
NumberFormat(float,decimal_places,thousand_seperater)
```
* Permitted thousand separators are :
    * Comma(,)
    * Space(" ")

 ```javascript
const {NumberFormat} = require('jsx-number-format');
 let formattedNumber =NumberFormat(5000,2,',');
// or formatNumber = NumberFormat(5000);
/*5000 is the amount to format
* 2 decimal places (optional)
* , is the thousand delimiter(optional)
* result: 5,000.00
*/
let formattedNumber2 =  NumberFormat(5000.789,2,',');
/*or formattedNumber2 =  NumberFormat(5000.789);
* gives 5,000.79
*/
//Having .004 which the last value 4 is less than 5
let formattedNumber3 =  NumberFormat(5000.004,2,',');
/* or let formattedNumber3 =  NumberFormat(5000.004);
* gives 5,000.00
*/
```

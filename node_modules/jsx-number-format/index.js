const NumberFormat =(number,decimals=2,delimiter=',') =>{
    const permitted_delimeters = [','," "];

    if (!permitted_delimeters.includes(delimiter)){
        delimiter =",";//to cap when one uses the period(.) for delimiter
    }
    if (typeof  number ==='undefined' || number === '' || isNaN(number)){
        number = "0";
    }
    let string_val = parseFloat(number)
        .toFixed(decimals)
        .toString();
    let number_decimals_ = string_val.split('.', 2);
    let _decimals_ = (number_decimals_.length > 1)?number_decimals_[1]:'';
    let _number = (number_decimals_.length > 0)?number_decimals_[0]:'0';
    return (_number.replace(/\B(?=(\d{3})+(?!\d))/g, "$&"+delimiter))+((_decimals_!=='')?'.'+_decimals_:'');

}
module.exports = {NumberFormat};

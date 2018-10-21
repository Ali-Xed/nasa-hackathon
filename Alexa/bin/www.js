'use strict';

const util = require('util');
const ds = require('../datasource');

const city = 'new york';
const period = '2017-SU';

// Alexa date input format 'yyyy-MM-dd'
ds.getAverageTemperature(city, period)
    .then(data => {
        if (data) {
            // console.log(util.inspect(data));
            const avg = data.averageTemperature();
            if (avg) {
                console.log(`The average temperature in ${city} for ${data.periodName} was ${avg} degrees celsius`);
                return;
            }
            console.error('Unable to retrieve data for the period selected');
        }
    });